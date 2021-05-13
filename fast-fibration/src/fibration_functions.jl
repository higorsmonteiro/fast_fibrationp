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
    Generate a input-set stable partition with respect to the pivot set.    

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
    # Necessary data for the correct splitting.
    fiber_index = graph.int_vproperties["fiber_index"]
    edgetype_prop = graph.int_eproperties[eprop_name]

    # Default input-set string for those who does not have input from 'pivot'.
    default_str = ""
    for j in 1:n_edgetype
        default_str = default_str*"0"
    end

    # Classes' index of the ones which receives input from 'pivot'.
    input_classes = Int[]
    # Input-set of the nodes with input from 'pivot'.
    input_dict = Dict{Int, Array{Int}}()
    # Get all nodes with input from 'pivot'. Efficient.
    for w in pivot.nodes
        w_out_edges = graph.vertices[w].edges_source
        for edge in w_out_edges
            tgt = edge.target
            etype = edgetype_prop[edge.index]
            push!(input_classes, fiber_index[tgt])
            #f_index = fiber_index[tgt] 

            # In case 'tgt' is not included in the dict yet.
            if get(input_dict, tgt, -1)==-1
                input_dict[tgt] = [ 0 for j in 1:n_edgetype ]
            end
            input_dict[tgt][etype] += 1
        end
    end
    input_classes = collect(Int, Set(input_classes))
    receivers = Fiber[ copy_fiber(partition[j]) for j in input_classes ]

    # ----------------------> SPLIT PROCEDURE <---------------------- #
    # -- go over each pivot-inputted class and split it if necessary --
    for r_fiber in receivers
        str_input_aux = Dict{String, Array{Int}}()
        for v in r_fiber.nodes
            # if no input from 'pivot'.
            if get(input_dict, v, -1)==-1 
                str_input_aux[default_str] = Int[]
                push!(str_input_aux[default_str], v)
            else # there is input from 'pivot'
                input_str = ""
                for j in input_dict[v]
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

function count_fiber(partition::Array{Fiber}, graph::Graph)
    # Count the number of nontrivial fibers
    node_name = graph.string_vproperties["node_name"]
    
    count = []
    nodes_in_fiber = Array{String}[]
    for fiber in partition
        if length(fiber.nodes)>1
            push!(count, fiber.index)
        end
        fmt_nodes = [ node_name[j] for j in fiber.nodes ]
        append!(nodes_in_fiber, [fmt_nodes])
    end
    return length(count), length(partition), nodes_in_fiber
end