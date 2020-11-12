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
    for strong in sccs
        
    end




end