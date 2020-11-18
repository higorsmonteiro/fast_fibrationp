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

function dfs_search(graph::Graph)
    N = length(graph.vertices)
    color = [-1 for j in 1:N ]
    dist = [-1 for j in 1:N ]
    parent = [-1 for j in 1:N ]
    finished = [-1 for j in 1:N ]

    time = [0]
    for u in 1:N
        if color[u]==-1
            dfs_visit(u, graph, time, color, dist, parent, finished)
        end
    end
    return color, parent, finished
end

function dfs_visit(u::Int, graph::Graph, time::Array{Int},
                   color::Array{Int}, dist::Array{Int},
                   parent::Array{Int}, finished::Array{Int})
    time[1] += 1
    dist[u] = time[1]
    color[u] = 0
    u_adj = get_out_neighbors(u, graph)
    for v in u_adj
        if color[v]==-1
            parent[v] = u
            dfs_visit(v, graph, time, color, dist, parent, finished)
        end
    end
    color[u] = 1
    time[1] += 1
    finished[u] = time[1]
end

function bfs_search(source::Int, graph::Graph)
    N = length(graph.vertices)
    color = [-1 for j in 1:N]
    dist = [-1 for j in 1:N]
    parent = [-1 for j in 1:N]

    # -1/0/1 -> white/gray/black
    color[source] = 0
    dist[source] = 0
    parent[source] = -1

    queue = Int[]
    push!(queue, source)
    while length(queue)>0
        u = pop!(queue)
        u_adj = get_out_neighbors(u, graph)
        for w in u_adj
            if color[w]==-1
                color[w] = 0
                dist[w] = dist[u]+1
                parent[w] = u
                push!(queue, w)
            end
        end
        color[u] = 1
    end
    return color, dist, parent
end

function transpose_graph(graph::Graph)
    edges = graph.edges
    for edge in edges
        src = edge.source
        tgt = edge.target
        edge.source = tgt
        edge.target = src
    end
    for node in graph.vertices
        aux_src = node.edges_source
        aux_tgt = node.edges_target
        node.edges_source = aux_tgt
        node.edges_target = aux_src
    end
end

function find_root(node::Int, parent::Array{Int})
    par = parent[node]
    r = node
    while par!=-1
        r = par
        par = parent[par]
    end
    return r
end

function extract_strong(graph::Graph, graph_t::Graph)
    color, dist, parent, finished = dfs_search(graph)
    node_ordering = sortperm(finished, rev=true)

    N = length(graph_t)
    color2 = [-1 for j in 1:N ]
    dist2 = [-1 for j in 1:N ]
    parent2 = [-1 for j in 1:N ]
    finished2 = [-1 for j in 1:N ]
    time = [0]
    for u in node_ordering
        if color2[u]==-1
            dfs_visit(u, graph_t, time, color2, dist2, parent2, finished2)
        end
    end

    # -- Separate SCCs --
    sccs = Dict{Int, Array{Int}}()
    for v in 1:N
        root = find_root(v, parent2)
        if get(sccs, root, -1)==-1
            sccs[root] = Int[]
        end
        push!(sccs[root], v)
    end

    scc_list = Array{Int}[]
    for key in collect(keys(sccs))
        push!(scc_list, sccs[key])
    end
    return scc_list
end