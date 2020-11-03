#=
    This code must be inserted together with 'base_net.jl'.
=#

"""
    Returns an array containing the degree for each vertex
    in the given graph.

    mode -> {'total', 'in', 'out'}
"""
function get_degree(graph::Graph, mode::String)
    degree = zeros(Int, length(graph.vertices))
    for j in 1:length(graph.vertices)
        vertex = graph.vertices[j]
        if mode=="total"
            degree[j] = length(vertex.edges_source) + length(vertex.edges_target)
        elseif mode=="in"
            degree[j] = length(vertex.edges_target)
        elseif mode=="out"
            degree[j] = length(vertex.edges_source)
        end
    end
    return degree
end

"""
    Two-pass algorithm. Intuitive. Demands a great 
    deal of memory. Kosajaru's algorithm.
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