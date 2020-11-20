#=

=#

"""
    Separate each node in its corresponding SCC and classify
    each one to correctly initialize the fibration algorithm.

    Returns a list containing 'Fiber' objects, representing
    the initial partitioning of the network.
"""
function initialize(graph::Graph)
    N = length(graph.vertices)

    #scc_info = find_strong(graph, true)
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
    Generate a input-set stable 'partition' with respect to 'pivot'.    

    Given a 'pivot', we select all the possible unstable classes of 
    the current 'partition' and define these classes as 'receivers',
    meaning classes that have input from 'pivot'. After this, we check 
    all edges coming out from 'pivot' and set the input-set for its
    targets.

    Using an hash table, each node receiving edges from 'pivot' holds
    a list representing its input-set. With these we make the proper 
    splitting of the unstable classes.

    'eprop_name' {default to "edgetype"} is the edge property that should
    be used in the algorithm.

    At the end of the function, 'partition' is input-set stable with
    respect to 'pivot' and the 'pivot_queue' will be properly updated.
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
    Main function for the fibration. Returns the final partitioning
    of the given 'graph'.
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

# =================== BALANCED COLORING ===================== #

function initialize_coloring(graph::Graph)
    N = length(graph.vertices)

    #scc_info = find_strong(graph)
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
    # -- Save the graph property 'fiber_index' --
    set_vertices_properties("fiber_index", fiber_index, graph)
    return partition, autopivot
end

"""
    Splitting function for the minimal balanced coloring algorithm.

    Given 'graph' with the vertex property 'fiber_index' indicating
    the class of each node, and also the 'ncolor' and 'ntype' corresponding
    to the current number of colors and the number of edge types in the 
    network, the function modifies 'fiber_index' if the coloring is not
    balanced and returns the new value of 'ncolor'.
"""
function s_coloring(graph::Graph, ncolor::Int, ntype::Int)
    fiber_index = graph.int_vproperties["fiber_index"]
    edgetype_prop = graph.int_eproperties["edgetype"]

    # -- Set the ISCV matrix --
    input_dict = Dict{String, Array{Int}}()
    iscv = zeros(Int, (ncolor*ntype, length(graph.vertices)))
    # For each node check its incoming edges' colors. 
    for v in 1:length(graph.vertices)
        node = graph.vertices[v]
        incoming_edges = node.edges_target
        for edge in incoming_edges
            src = edge.source
            incoming_color = fiber_index[src]
            incoming_type = edgetype_prop[edge.index]
            # pay attention on indexing.
            iscv[(incoming_color-1)*ntype + incoming_type, v] += 1
        end
        # -- Convert the ISCV into a string --
        input_str = ""
        for j in 1:(ncolor*ntype)
            input_str*="$(iscv[j,v])"
        end
        # -- Put nodes with same ISCV in the same key.
        if get(input_dict, input_str, -1)==-1
            input_dict[input_str] = Int[]
        end
        push!(input_dict[input_str], v)
    end

    # -- The keys of 'input_dict' are the unique ISCV 
    # -- and each of these keys holds the belonging nodes.
    # -- NOTE: nodes without input are in the same key.
    updated_colors = collect(keys(input_dict))
    increase_color = Dict{Int,Bool}()
    for f_index in fiber_index
        increase_color[f_index] = false
    end
    for color in updated_colors
        unique = collect(Set([fiber_index[v] for v in input_dict[color]]))
        # If the nodes come from two different class, then it is an 
        # improper splitting
        if length(unique)>1
            continue
        end

        if increase_color[unique[1]]
            ncolor += 1
            # -- assign new color to this new class --
            for v in input_dict[color]
                fiber_index[v] = ncolor
            end
        else
            increase_color[unique[1]] = true
        end
    end
    return ncolor
end

"""
    Main call function for the minimal balanced coloring.

    'graph' is the network structure to be partitioned, and 'eprop_name'
    is the name of the edge property holding the type of the edges. (this
    property must be an integer prop ranging from 1 to number of types.)
"""
function minimal_coloring(graph::Graph, eprop_name="edgetype")
    if !graph.is_directed
        print("Undirected network\n")
        return
    end

    edgetype_prop = graph.int_eproperties[eprop_name]
    num_edgetype = length(collect(Int, Set(edgetype_prop)))
 
    # -- Set the 'fiber_index' property for the network --
    partition, autopivot = initialize_coloring(graph)
    fiber_index = graph.int_vproperties["fiber_index"]
    # -- Number of color before and after refinement --
    ncolor_new = -1
    ncolor_old = length(collect(Int, Set(fiber_index)))

    # -- Refinement process through coloring --
    while true
        ncolor_new = s_coloring(graph, ncolor_old, num_edgetype)
        if ncolor_new==ncolor_old
            break
        end
        #print("$(ncolor_old), $(ncolor_new)\n")
        ncolor_old = ncolor_new
    end
    # --------------------------------------------------------- #

    # -- After the coloring is balanced generate the fiber structure --
    fiber_dict = Dict{Int, Array{Int}}()
    fiber_index = graph.int_vproperties["fiber_index"]
    for v in 1:length(graph.vertices)
        if get(fiber_dict, fiber_index[v], -1)==-1
            fiber_dict[fiber_index[v]] = Int[]
        end
        push!(fiber_dict[fiber_index[v]], v)
    end

    partition = Fiber[]
    for key in collect(keys(fiber_dict))
        new_fiber = Fiber()
        insert_nodes(fiber_dict[key], new_fiber)
        new_fiber.index = length(partition)+1
        push!(partition, new_fiber)
    end
    return partition
end