#=

=#

"""
    Group nodes into the corresponding Strongly Connected Components and 
    classify each component to correctly initialize the fibration algorithm.
    From that, it provides the initial partitioning of the network together
    with the queue of pivot sets to run the fibration partitioning algorithm.

    Args:
        graph:
            'Graph' structure storing the vertices and edges' objects.
    Return:
        partition:
            List containing 'Fiber' objects. This list corresponds to the
            initial partitioning to be used for the fast fibration algorithm.
        pivot_queue:
            List containing 'Fiber' objects. This list corresponds to the queue
            of pivot sets. Each pivot set is used in one iteration of the algorithm
            to determine the next splitting.
"""
function initialize(graph::Graph)
    N = length(graph.vertices)

    scc_info = extract_strong(graph, true)
    node_labels = scc_info[1]
    unique_labels = scc_info[2]
    components = scc_info[3]

    # -- 'sccs' holds a list of 'StrongComponent' objects --
    sccs = StrongComponent[]
    for label in collect(keys(components))
        new_scc = StrongComponent()
        insert_nodes(components[label], new_scc)
        push!(sccs, new_scc)
    end
    
    # -- Check if each SCC receives or not input from other
    # -- components not itself --
    partition = Fiber[Fiber()]
    autopivot = Fiber[]
    for strong in sccs
        check_input(strong, graph)
        classify_strong(strong, graph)

        if strong.type == 0
            insert_nodes(strong.nodes, partition[1])
        elseif strong.type == 1 
            new_fiber = Fiber()
            insert_nodes(strong.nodes, new_fiber)
            append!(partition, [new_fiber])
        else
            new_fiber = Fiber()
            insert_nodes(strong.nodes, new_fiber)
            append!(autopivot, [new_fiber])
            insert_nodes(strong.nodes, partition[1])
        end
    end

    # -- Define the pivot set queue and fiber pointer for each
    # -- node. Also push the defined classes to the queue.
    pivot_queue = Fiber[]
    fiber_index = [ -1 for j in 1:N ]
    for (index, class) in enumerate(partition)
        push!(pivot_queue, copy_fiber(class))
        for v in class.nodes
            fiber_index[v] = index
        end
        partition[index].index = index
    end
    # -- Push the isolated self-loop nodes to the queue --
    for isolated in autopivot
        push!(pivot_queue, copy_fiber(isolated))
    end
    # -- Save the graph property 'fiber_index' --
    set_vertices_properties("fiber_index", fiber_index, graph)
    return partition, pivot_queue
end

"""
    Push all the splitted classes to the pivot queue, with exception
    of the largest class.

    Args:
        new_classes:
            List of 'Fiber' objects containing all the classes that must be
            pushed to pivot set (excluding the larger one)..
        pivot_queue:
            List of 'Fiber' objects. It corresponds to the pivot set that must 
            be updated with new splitted classes.
"""
function enqueue_splitted(new_classes::Array{Fiber}, pivot_queue::Array{Fiber})
    classes_size = [ fiber.number_nodes for fiber in new_classes ]
    mxval, mxind = findmax(classes_size) 

    for (j, fiber) in enumerate(new_classes)
        if j!=mxind
            new_pivot = copy_fiber(fiber)
            push!(pivot_queue, new_pivot)
        end
    end
end

"""
    Returns a list of indexes of the possible input set unstable classes of the
    'graph'. Also, it returns a dictionary which maps a node to its input set. This
    function is called by the 'fast_partitioning' function.

    Args:
        graph:
            'Graph' structure storing the vertices and edges' objects.
        pivot:
            'Fiber' object representing the current pivot set which is used for the
            splitting process.
        partition:
                
        number_edgetype:
            Total number of edge types within the parsed 'graph'.

        eprop_name:
                
    Return:
        receivers:
            Array of 'Fiber' objects. Each fiber contained in this array receives at least 
            one input from the parsed pivot set.
        input_sets:
            Dictionary with integer indexes and value as arrays of integers. The integer
            indexes represents the nodes of the graph, while their associated array of
            integers represents the input set with respect to the pivot set.
            Example: input_sets[2] => [0 2 1] -> Node 2 receives 2 input of type 2 and 
            1 input of type 3 from the pivot set.
"""
function calculate_input_set(graph::Graph, pivot::Fiber, partition::Array{Fiber},
                             number_edgetype::Int, eprop_name::String)
    fiber_index = graph.int_vproperties["fiber_index"]
    edgetype_prop = graph.int_eproperties[eprop_name]

    receivers_classes = Int[]
    input_sets = Dict{Int, Array{Int}}()

    for pivot_v in pivot.nodes
        out_edges = graph.vertices[pivot_v].edges_source
        for edge in out_edges
            target = edge.target
            etype = edgetype_prop[edge.index]
            push!(receivers_classes, fiber_index[target])
            # In case 'target' is not included in the dict yet.
            if get(input_sets, target, -1)==-1
                input_sets[target] = [ 0 for j in 1:number_edgetype ]
            end
            input_sets[target][etype] += 1
        end
    end
    receivers_classes = collect(Int, Set(receivers_classes))
    receivers = Fiber[ copy_fiber(partition[j]) for j in receivers_classes ]
    return receivers, input_sets
end

"""
    Generate a input set stable partition with respect to the pivot set.    

    Given a pivot set, we select all the possible unstable classes of 
    the current 'partition' and define these classes as 'receivers',
    meaning classes that have input from the pivot set. After this, we 
    check all edges coming out from the pivot set and calculate the input set 
    for its targets.

    Using a hash table, each node receiving edges from the pivot set holds
    a list representing its input set. With these we make the proper 
    splitting of the unstable classes.

    'eprop_name' {default to "edgetype"} is the edge property that should
    be used in the algorithm.

    At the end of the function, 'partition' is input-set stable with
    respect to 'pivot' and the 'pivot_queue' will be properly updated.

    Args:
        graph:
            'Graph' structure holding the vertices and edges' objects that
            defines the network.
        pivot:
            'Fiber' object representing the current pivot set that must be used
            to split unstable classes.
        partition:
            List of 'Fiber' object representing the current partitioning of the
            network. This list is modified if any class is splitted during this 
            iteration.
        pivot_queue:
            List of 'Fiber' objects. It corresponds to the pivot set that must 
            be updated with new splitted classes.
        n_edgetype:
            Integer value representing the number of edge types within the network.
        eprop_name:
            String representing the edge property of the network that should be used
            to query the type of each edge.
"""
function fast_partitioning(graph::Graph, pivot::Fiber, partition::Array{Fiber}, 
                           pivot_queue::Array{Fiber}, n_edgetype::Int, eprop_name="edgetype")
    receivers, input_sets = calculate_input_set(graph, pivot, partition, n_edgetype, eprop_name) 

    # Default input set string for those who does not receive input from 'pivot'.
    default_str = ""
    for j in 1:n_edgetype default_str = default_str*"0" end

    fiber_index = graph.int_vproperties["fiber_index"]
    edgetype_prop = graph.int_eproperties[eprop_name]

    # ----------------------> SPLIT PROCEDURE <---------------------- #
    # -- go over each pivot-inputted class and split it if necessary --
    for r_fiber in receivers
        str_input_aux = Dict{String, Array{Int}}()
        for v in r_fiber.nodes
            # if no input from 'pivot'.
            if get(input_sets, v, -1)==-1 
                str_input_aux[default_str] = Int[]
                push!(str_input_aux[default_str], v)
            else # there is input from 'pivot'
                input_str = ""
                for j in input_sets[v]
                    input_str = input_str*"$j"
                end
                if get(str_input_aux, input_str, -1)==-1
                    str_input_aux[input_str] = Int[]
                end
                push!(str_input_aux[input_str], v)
            end
        end
        
        # -- 'str_input_aux' now represents the splitted classes for the
        # -- current fiber 'r_fiber'. Each key of it holds the new class.
        all_keys = collect(keys(str_input_aux))
        # if class is stable w.r.t 'pivot', then go to the next class.
        if length(all_keys)==1 
            continue
        end
        new_classes = Fiber[]
        nodes_to_remove = Int[]
        cur_fiber = partition[r_fiber.index]
        # -- choose the first key to keep the nodes --
        for key in all_keys[2:length(all_keys)]
            # -- create new fiber and add the nodes from the current key. --
            new_fiber = Fiber()
            new_fiber.index = length(partition)+1
            insert_nodes(str_input_aux[key], new_fiber)
            # -- Update the pointer of the nodes to their new fiber --
            for u in new_fiber.nodes
                fiber_index[u] = new_fiber.index
            end
            # -- put the new fiber in the partition --
            push!(partition, new_fiber)
            push!(new_classes, copy_fiber(new_fiber))
            # -- at the same time, the nodes added to the new fiber must be 
            # -- deleted from its original fiber.
            append!(nodes_to_remove, str_input_aux[key])
        end
        delete_nodes(nodes_to_remove, cur_fiber)
        push!(new_classes, copy_fiber(cur_fiber))

        # -- Update 'pivot_queue' --
        enqueue_splitted(new_classes, pivot_queue)
    end
end

"""
    Divide a directed graph into several groups according to the fibration 
    partitioning of the graph.
    
    Args:
        graph:
            'Graph' structure where the vertices and edges are placed.
        eprop_name:
            String representing the integer edge property of the network that should 
            be used to query the type of each edge.
    Return:
        partition:
            Final fibration partitioning.
"""
function fast_fibration(graph::Graph, eprop_name="edgetype")
    if !graph.is_directed
        print("Undirected network\n")
        return
    end

    edgetype_prop = graph.int_eproperties[eprop_name]
    number_edgetype = length(collect(Int, Set(edgetype_prop)))

    partition, pivot_queue = initialize(graph)
    while length(pivot_queue)>0
        pivot_set = pop!(pivot_queue)
        fast_partitioning(graph, pivot_set, partition, pivot_queue, number_edgetype)
    end
    return partition
end

"""
    Given a list of fibers, returns the count of nontrivial fibers, 
    the total count of fibers and also a dictionary containing all
    the nodes for each fiber.

    Args:
        partition:
            List of 'Fiber' objects.
    Return:
        nontrivial_fibers:
            Count of fibers containing more than one node.
        total_fibers:
            Total count of fibers, including trivial and nontrivial
            fibers. 
        fibers_map:
            Dictionary where the indexes are the list index of the fiber
            in the parsed 'partition' and the contained value is an array
            of integers representing the nodes inside the current fiber.
"""
function extract_fiber_groups(partition::Array{Fiber})
    nontrivial_fibers = 0
    total_fibers = 0
    fibers_map = Dict{Int, Array{Int}}()
    for j in 1:length(partition)
        fibers_map[j] = partition[j].nodes
        if partition[j].number_nodes > 1
            nontrivial_fibers += 1
        end
        total_fibers += 1
    end
    return nontrivial_fibers, total_fibers, fibers_map
end