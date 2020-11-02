#=
    This code must be inserted together with 'build_net.jl'.
=#

"""
    Two-pass algorithm. Intuitive. Demands a great 
    deal of memory.
"""
function extract_scc(graph::Graph)
    sets = Array[]
    for node in graph.vertices
        reach = BFS(node.index, graph)
        append!(sets, [reach])
    end

    sccs = Array[]
    checked = [ false for j in 1:length(graph.vertices) ]
    for (j, node) in enumerate(graph.vertices)
        if checked[j]
            continue
        end

        current_scc = Int[]
        node_reach = sets[j]
        append!(current_scc, [node.index])
        checked[node.index] = true

        for k in sets[j]
            if j in sets[k] && j!=k
                checked[k] = true
                append!(current_scc, [k])
            end
        end
        append!(sccs, [current_scc])
    end
    return sccs
end

"""
    Depth-First Search, starting from node of index 'v_index'.
"""
function DFS(v_index::Int, graph::Graph)
    stack = Int[]
    visited = Int[ 0 for i in 1:length(graph.vertices) ]
    for w in get_all_neighbors_aware(v_index, graph)
        push!(stack, w)
    end
    visited[v_index] = 1

    while length(stack)!=0
        v = pop!(stack)
        if visited[v]==0
            for w in get_all_neighbors_aware(v, graph)
                push!(stack, w)
            end
            visited[v] = 1
        end
    end
    return Int[ j for (j, value) in enumerate(visited) if value==1 ]
end

"""
    Breadth-First Search, starting from node of index 'v_index'.
"""
function BFS(v_index::Int, graph::Graph)
    queue = Int[]
    visited = Int[ 0 for i in 1:length(graph.vertices) ]
    append!(queue, get_all_neighbors_aware(v_index, graph))
    visited[v_index] = 1 
    
    while length(queue)!=0
        v = pop!(queue)
        if visited[v]==0
            append!(queue, get_all_neighbors_aware(v, graph))
            visited[v] = 1        
        end
    end
    return Int[ j for (j, value) in enumerate(visited) if value==1 ]
end