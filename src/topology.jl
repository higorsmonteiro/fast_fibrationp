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
    Tarjan's algorithm for finding strongly connected
    components. Recursive.

    Given 'graph' the function returns a tuple containing,
    respectively, the list of components labels, the unique
    component's labels and the number of components.
"""
function find_strong(graph::Graph)
    UNVISITED = -1
    N = length(graph.vertices)

    id = 0
    scount = 0

    stack = Int[]
    low = zeros(Int, N)
    ids = [ UNVISITED for n in 1:N ]
    onstack = [ false for n in 1:N ]

    for i in 1:N
        if ids[i] == UNVISITED
            id, scount = dfs_tarjan(i, graph, stack, low, ids, onstack, id, scount)
        end
    end
    unique_labels = collect(Int, Set(low))
    return low, unique_labels, scount
end

function dfs_tarjan(at::Int, g::Graph, stack::Array{Int},
                    low::Array{Int}, ids::Array{Int},
                    onstack::Array{Bool}, id::Int, scount::Int)
    UNVISITED = -1
    push!(stack, at)
    onstack[at] = true
    ids[at] = id
    low[at] = id
    id += 1

    for at_out in get_out_neighbors(at, g)
        if ids[at_out] == UNVISITED
            id, scount = dfs_tarjan(at_out, g, stack, low, ids, onstack, id, scount)
        end
        if onstack[at_out]
            low[at] = minimum([low[at], low[at_out]])
        end
    end

    if ids[at] == low[at]
        while true
            node = pop!(stack)
            onstack[node] = false
            low[node] = ids[at]
            if node == at
                break
            end
        end
        scount += 1
    end
    return id, scount
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