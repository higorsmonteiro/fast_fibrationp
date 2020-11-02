# -- Define an edge --
mutable struct Edge
    source::Int
    target::Int
    is_directed::Bool
    function Edge(source::Int, target::Int, is_directed::Bool)
        new(source, target, is_directed)
    end
end

# -- Define a node --
mutable struct node
    index::Int
    edges_source::Array{Edge}
    edges_target::Array{Edge}
    function node(index::Int)
        edges_source = Edge[]
        edges_target = Edge[]
        new(index, edges_source, edges_target)
    end
end

# -- Define a graph -- 
mutable struct Graph
    N::Int
    M::Int
    is_directed::Bool
    vertices::Array{node}
    function Graph(is_directed::Bool)
        N = 0
        M = 0
        vertices = node[]
        new(N, M, is_directed, vertices)
    end
end

"""
    Given an adjacency list, we build a network.

    The adjacency list must be of the following form:
    
    adjlist = [[1,2,3,4,...,j,..],
               [3,5],
               ...,
               [3,6,7]]

    where all the node indexes must be inside the range
    [1,N].
"""
function create_graph(adjlist, is_directed::Bool)
    new_graph = Graph(is_directed)
    # First, create all the nodes.
    for j in 1:length(adjlist)
        add_node(new_graph)
    end

    # Then, build the connections.
    for (j, nodelist) in enumerate(adjlist)
        for k in nodelist
            add_edge(j, k, new_graph)
        end
    end
    return new_graph
end

##################################################
# ---------------------------------------------- #
# ------------ Graph Manipulation -------------- #
# ---------------------------------------------- #
##################################################


"""
    Check if the edge(i,j) already exists in the network.
    If the network is directed, then we check for i->j, while
    for the undirected, i<->j.

    Time complexity: O(k), where k = max(k_i, k_j).
"""
function is_edge(i, j, graph::Graph)
    node_i = graph.vertices[i]
    node_j = graph.vertices[j]
    is_directed = graph.is_directed

    if is_directed
        out_edges_i = node_i.edges_source
        for cur_edge in out_edges_i
            if cur_edge.target == node_j.index
                return true
            end
        end
    else
        out_edges_i = node_i.edges_source
        in_edges_i = node_i.edges_target
        for cur_edge in out_edges_i
            if cur_edge.target == node_j.index
                return true
            end
        end
        for cur_edge in in_edges_i
            if cur_edge.source == node_j.index
                return true
            end
        end
    end
    return false
end

"""
    Create a new node in the given Graph.
"""
function add_node(graph::Graph)
    index = graph.N+1
    new_node = node(index)
    append!(graph.vertices, [new_node])
    graph.N += 1
end

"""
    Create an edge between node 'i' and node 'j'.
    Edges are created as directed edges (i->j) whether
    the network is directed or not. 

    The direction of the network defines the behavior of
    other functions.
"""
function add_edge(i, j, graph::Graph)
    is_directed = graph.is_directed
    node_i = graph.vertices[i]
    node_j = graph.vertices[j]
    # If the edge already exists, then do nothing
    if is_edge(i, j, graph)
        return 
    end
    # -- Create the edge object --
    new_edge = Edge(node_i.index, node_j.index, is_directed)
    append!(node_i.edges_source, [new_edge])
    append!(node_j.edges_target, [new_edge])
end

function get_all_neighbors_aware(v_index::Int, graph::Graph)
    node_v = graph.vertices[v_index]
    neighbors = Int[]
    out_edges_v = node_v.edges_source
    for cur_edge in out_edges_v
        append!(neighbors, [cur_edge.target])
    end
    if graph.is_directed
        return collect(Int, Set(neighbors))
    end
    in_edges_v = node_v.edges_target
    for cur_edge in in_edges_v
        append!(neighbors, [cur_edge.source])
    end
    return collect(Int, Set(neighbors))
end

"""
    Returns an iterator containing all the neighbors of node
    of index 'v_index'. Independent of network direction.
"""
function get_all_neighbors(v_index::Int, graph::Graph)
    node_v = graph.vertices[v_index]
    neighbors = Int[]
    out_edges_v = node_v.edges_source
    for cur_edge in out_edges_v
        append!(neighbors, [cur_edge.target])
    end
    in_edges_v = node_v.edges_target
    for cur_edge in in_edges_v
        append!(neighbors, [cur_edge.source])
    end
    return collect(Int, Set(neighbors))
end

"""
    Returns an iterator containing all the incoming neighbors 
    of node of index 'v_index'.
"""
function get_in_neighbors(v_index::Int, graph::Graph)
    node_v = graph.vertices[v_index]
    is_directed = graph.is_directed
    neighbors = Int[]
    in_edges_v = node_v.edges_target
    for cur_edge in in_edges_v
        append!(neighbors, [cur_edge.source])
    end
    return collect(Int, Set(neighbors))
end

"""
    Returns an iterator containing all the  outcoming neighbors 
    of node of index 'v_index'. Independent of network direction.
"""
function get_out_neighbors(v_index::Int, graph::Graph)
    node_v = graph.vertices[v_index]
    is_directed = graph.is_directed
    neighbors = Int[]
    out_edges_v = node_v.edges_source
    for cur_edge in out_edges_v
        append!(neighbors, [cur_edge.source])
    end
    return collect(Int, Set(neighbors))
end

function printGraph(graph::Graph)
    vertices = graph.vertices
    for v in vertices
        print("node $(v.index) -> ")
        for w in v.edges_source
            print("$(w.target) ")
        end
        for w in v.edges_target
            print("$(w.source) ")
        end
        print("\n")
    end
end

"""
    Breadth-First Search, starting from node of index 'v_index'.
"""
function BFS(v_index::Int, graph::Graph)
    stack = Int[]
    visited = Int[ 0 for i in 1:length(graph.vertices) ]
    append!(stack, get_all_neighbors(v_index, graph))
    visited[v_index] = 1 
    
    while length(stack)!=0
        v = pop!(stack)
        if visited[v]==0
            append!(stack, get_all_neighbors(v, graph))
            visited[v] = 1        
        end
    end
    return Int[ j for (j, value) in enumerate(visited) ]
end

#adjlist_ex = [[2,3], [1], [2]]
#net = create_graph(adjlist_ex, false)
#printGraph(net)
#print("\n")
#print(BFS(1, net))






