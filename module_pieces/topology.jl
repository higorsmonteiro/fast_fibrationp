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

function strongconnect(v::Int, graph::Graph, i::Int, SCC::Array,
                       LOWPT::Array{Int}, LOWVINE::Array{Int},
                       NUMBER::Array{Int}, STACK::Array{Int})
    LOWPT[v] = i
    LOWVINE[v] = i
    NUMBER[v] = i
    i+=1
    push!(STACK, v)
    for w in get_out_neighbors(v, graph)
        if NUMBER[w]==-1
            strongconnect(w, graph, i, SCC, LOWPT, LOWVINE, NUMBER, STACK)
            LOWPT[v] = minimum([LOWPT[v], LOWPT[w]])
            LOWVINE[v] = minimum([LOWVINE[v], LOWVINE[w]])
        elseif w in get_in_neighbors(v, graph)
            LOWPT[v] = minimum([LOWPT[v], NUMBER[w]])
        elseif NUMBER[w] < NUMBER[v]
            if w in STACK
                LOWVINE[v] = minimum([LOWVINE[v], NUMBER[w]])
            end
        end
    end

    if LOWPT[v]==NUMBER[v] && LOWVINE[v]==NUMBER[v]
        new_scc = Int[]
        w = STACK[1]
        while NUMBER[STACK[1]] >= NUMBER[v]
            w = pop!(STACK)
            append!(new_scc, [w])
        end
        if length(new_scc)>0
            append!(SCC, [new_scc])
        end
    end
end

function get_scc(graph::Graph)
    LOWPT = [-1 for j in graph.vertices]
    LOWVINE = [-1 for j in graph.vertices]
    NUMBER = [-1 for j in graph.vertices]
    STACK = Int[]
    SCC = Array[]
    i = 1
    for (v, node) in enumerate(graph.vertices)
        if NUMBER[v]==-1
            strongconnect(v, graph, i, SCC, LOWPT, LOWVINE, NUMBER, STACK)
        end
    end
    return SCC
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