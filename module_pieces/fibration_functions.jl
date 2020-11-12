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

    scc_info = find_strong(graph)
    node_labels = scc_info[1]
    unique_labels = scc_info[2]
    N_scc = scc_info[3]

    # -- Initialize dictionary to hold the components' nodes -- 
    components = Dict{Int, Array{Int}}()
    for l in unique_labels
        components[l] = Int[]
    end
    for (j, label) in enumerate(node_labels)
        push!(components[label], j)
    end

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
    We define the list A of classes that receives information from
    'pivot'. To guarantee that the fibration algorithm runs in loglinear
    time, this procedure should take advantage of the 'fiber_index'
    vertex property in the network to avoid a sweep over all the nodes
    in it.

    By getting the fiber indexes of all outcoming neighbors of the pivot
    set nodes the 'receiver_classes' stores the indexes of the possible
    unstable classes. Then, 'classes' lists the corresponding objects.

    Returns a list of fibers representing the fibers that must be checked
    for the input-set stability.
"""
function get_possible_unstable(graph::Graph, pivot::Fiber, partition::Array{Fiber})
    fiber_index = graph.int_vproperties["fiber_index"]
    receiver_classes = Int[]
    pivot_sucessors = sucessor_nodes(graph, pivot)
    for w in pivot_sucessors
        push!(receiver_classes, fiber_index[w])
    end
    receiver_classes = collect(Int, Set(receiver_classes))
    selected_classes = [ partition[ind] for ind in receiver_classes ]
    return selected_classes
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

    At the end of the function, 'partition' is input-set stable with
    respect to 'pivot' and the 'pivot_queue' will be properly updated.
"""
function fast_partitioning(partition::Array{Fiber}, receivers::Array{Fiber}, 
                           pivot::Fiber, pivot_queue::Array{Fiber})
    # Necessary data for the correct splitting.
    fiber_index = graph.int_vproperties["fiber_index"]
    edgetype_prop = graph.int_eproperties["edgetype"]
    number_edgetype = length(collect(Int, Set(edgetype_prop)))

    input_dict = Dict{Int, Array{Int}}()
    for w in pivot.nodes
        w_out_edges = graph.vertices[w].edges_source
        for edge in w_out_edges
            tgt = edge.target
            f_index = fiber_index[tgt] 
            etype = edgetype_prop[edge.index]

            if get(input_dict, tgt, -1)==-1
                input_dict[tgt] = [ 0 for j in 1:number_edgetype ]
            end
            input_dict[tgt][etype] += 1
        end
    end

    default_str = ""
    for j in 1:number_edgetype
        default_str = default_str*"0"
    end
    for f in receivers
        aux_dict = Dict{String, Array{Int}}()
        for v in f.nodes
            if get(input_dict, v, -1)==-1 # no input from pivot.
                aux_dict[default_str] = Int[]
                push!(aux_dict[default_str], v)
            else # there is input from pivot
                iscv_str = ""
                for j in input_dict[v]
                    iscv_str = iscv_str*"$j"
                end
                if get(aux_dict, iscv_str, -1)==-1
                    aux_dict[iscv_str] = Int[]
                end
                push!(aux_dict[iscv_str], v)
            end
        end
        """ 
            -- SPLIT PROCEDURE --
        
            'aux_dict' now represents the splitted classes for the
            current fiber 'f'
        """
        all_keys = collect(keys(aux_dict))
        if length(all_keys)==1 # class is stable w.r.t pivot.
            continue
        end
        # -- choose the first key to keep the nodes --
        new_classes = Fiber[]
        nodes_to_remove = Int[]
        cur_fiber = partition[f.index]
        for key in all_keys[2:length(all_keys)]
            # -- create new fiber and add the nodes from the current key. --
            new_fiber = Fiber()
            insert_nodes(aux_dict[key], new_fiber)
            new_fiber.index = length(partition)+1
            for u in new_fiber.nodes
                fiber_index[u] = new_fiber.index
            end
            push!(partition, new_fiber)
            push!(new_classes, copy_fiber(new_fiber))
            # -- at the same time, the nodes added to the new fiber must be 
            # -- deleted from its original fiber.
            append!(nodes_to_remove, aux_dict[key])
        end
        delete_nodes(nodes_to_remove, cur_fiber)
        push!(new_classes, copy_fiber(cur_fiber))

        enqueue_splitted(new_classes, pivot_queue)
    end
end