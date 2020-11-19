#=
    This code must be inserted together with 'base_net.jl'.
=#

##### --------------- ACCESS LOCAL TOPOLOGY  --------------- ########

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

"""
function get_in_neighbors(node::Int, graph::Graph)
    node_obj = graph.vertices[node]

    # -- edges where 'node' is the target --
    incoming_edges = node_obj.edges_target
    incoming_neighbors = Int[]
    for edge in incoming_edges
        # fundamental check
        if edge.target!=node
            print("BUG. aborted.\n")
            return
        end
        push!(incoming_neighbors, edge.source)
    end
    return collect(Set(incoming_neighbors))
end

"""

"""
function get_out_neighbors(node::Int, graph::Graph)
    node_obj = graph.vertices[node]

    # -- edges where 'node' is the source --
    outcoming_edges = node_obj.edges_source
    outcoming_neighbors = Int[]
    for edge in outcoming_edges
        # fundamental check
        if edge.source!=node
            print("BUG. aborted.\n")
        end
        push!(outcoming_neighbors, edge.target)
    end
    return collect(Set(outcoming_neighbors))
end

"""

"""
function get_all_neighbors(node::Int, graph::Graph)
    incoming_neighbors = get_in_neighbors(node, graph)
    outcoming_neighbors = get_out_neighbors(node, graph)

    neighbors = Int[]
    append!(neighbors, incoming_neighbors)
    append!(neighbors, outcoming_neighbors)
    return collect(Set(neighbors))
end

# -------------------------------------------------------------------------- #

"""
    Tarjan's algorithm for finding strongly connected
    components. Recursive.

    Given 'graph' the function returns a tuple containing,
    respectively, the list of components labels, the unique
    component's labels and the number of components.
"""
function find_strong(graph::Graph, return_dict=false)
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
    sccs = Dict{Int, Array{Int}}()
    for v in 1:N
        if get(sccs, low[v], -1)==-1
            sccs[low[v]] = Int[]
        end
        push!(sccs[low[v]], v)
    end
    if return_dict
        return low, unique_labels, sccs
    end
    return low, unique_labels
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

function get_root(node::Int, parent::Array{Int,1})
    r = node
    while parent[r]!=-1
        r = parent[r]
    end
    return r
end

"""
    Extract the strongly connected components of the graph.

    ...
"""
function extract_strong(graph::Graph, return_dict=false)
    N = graph.N
    color, parent, finished = dfs_search(graph)

    # Create the tranpose graph from 'graph'.
    graph_t = copy_graph(graph)
    transpose_graph(graph_t)

    time = [0]
    color_t = [-1 for j in 1:N ]
    dist_t = [-1 for j in 1:N ]
    parent_t = [-1 for j in 1:N ]
    finished_t = [-1 for j in 1:N ]
    # Apply second DFS to 'graph_t' in decreasing order of 'finished'.
    node_ordering = sortperm(finished, rev=true)
    for u in node_ordering
        if color_t[u]==-1
            dfs_visit(u, graph_t, time, color_t, dist_t, parent_t, finished_t)
        end
    end

    # Now, each DFS tree in 'parent_t' represents an strongly connected component.
    scc_trees = Dict{Int, Array{Int}}()
    node_labels = [-1 for j in 1:N]
    for u in 1:N
        root = get_root(u, parent_t)
        if get(scc_trees, root, -1)==-1
            scc_trees[root] = Int[]
        end
        push!(scc_trees[root], u)
        node_labels[u] = root
    end
    unique_labels = collect(Int, Set(node_labels))
    if return_dict
        return node_labels, unique_labels, scc_trees
    end
    return node_labels, unique_labels
end