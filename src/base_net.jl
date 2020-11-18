# -- Define an edge --
mutable struct Edge
    index::Int
    source::Int
    target::Int
    is_directed::Bool
    function Edge(source::Int, target::Int, is_directed::Bool)
        index = -1
        new(index, source, target, is_directed)
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
    edges::Array{Edge}
    # ---------- Vertex properties ----------- #
    int_vproperties::Dict{String, Array{Int}}
    float_vproperties::Dict{String, Array{Float64}}
    string_vproperties::Dict{String, Array{String}}
    # ----------- Edge properties ------------ #
    int_eproperties::Dict{String, Array{Int}}
    float_eproperties::Dict{String, Array{Float64}}
    string_eproperties::Dict{String, Array{String}}
    # ---------------------------------------- #
    function Graph(is_directed::Bool)
        N = 0
        M = 0
        vertices = node[]
        edges = Edge[]
        int_vproperties = Dict{String, Array{Int}}()
        float_vproperties = Dict{String, Array{Float64}}()
        string_vproperties = Dict{String, Array{String}}()
        int_eproperties = Dict{String, Array{Int}}()
        float_eproperties = Dict{String, Array{Float64}}()
        string_eproperties = Dict{String, Array{String}}()
        new(N, M, is_directed, vertices, edges, int_vproperties, 
            float_vproperties, string_vproperties, int_eproperties,
            float_eproperties, string_eproperties)
    end
end

        ##################################################
        # ---------------------------------------------- #
######### ------------- Graph Properties --------------- ##########
        # ---------------------------------------------- #
        ##################################################

"""
    Set a mapping properties for the vertices.

    Depending on the type of the elements of 'arr' the
    properties are set in different variables.

    'name' -> name of the property.
    'arr' -> array of typed elements.
    'graph' -> graph to be assigned with the property.

    If there is already a property with the given 'name',
    the function will replace the old array with the new
    one, without any warning.
"""
function set_vertices_properties(name::String, arr::Array{Int}, graph::Graph)
    if length(graph.vertices) == length(arr)
        graph.int_vproperties[name] = arr
    else
        print("size array does not match number of vertices\n")
    end
end

function set_vertices_properties(name::String, arr::Array{Float64}, graph::Graph)
    if length(graph.vertices) == length(arr)
        graph.float_vproperties[name] = arr
    else
        print("size array does not match number of vertices\n")
    end
end

function set_vertices_properties(name::String, arr::Array{String}, graph::Graph)
    if length(graph.vertices) == length(arr)
        graph.string_vproperties[name] = arr
    else
        print("size array does not match number of vertices\n")
    end
end

"""
    Set a mapping properties for the edges.

    Depending on the type of the elements of 'arr' the
    properties are set in different variables.
        
    'name' -> name of the property.
    'arr' -> array of typed elements.
    'graph' -> graph to be assigned with the property.

    If there is already a property with the given 'name',
    the function will replace the old array with the new
    one, without any warning.
"""
function set_edges_properties(name::String, arr::Array{Int}, graph::Graph)
    if length(graph.edges) == length(arr)
        graph.int_eproperties[name] = arr
    else
        print("size array does not match number of edges\n")
    end
end

function set_edges_properties(name::String, arr::Array{Float64}, graph::Graph)
    if length(graph.edges) == length(arr)
        graph.float_eproperties[name] = arr
    else
        print("size array does not match number of edges\n")
    end
end

function set_edges_properties(name::String, arr::Array{String}, graph::Graph)
    if length(graph.edges) == length(arr)
        graph.string_eproperties[name] = arr
    else
        print("size array does not match number of edges\n")
    end
end

function list_properties(graph::Graph)
    print("$(keys(graph.int_vproperties)) - Int - Vertex\n")
    print("$(keys(graph.float_vproperties)) - Float - Vertex\n")
    print("$(keys(graph.string_vproperties)) - String - Vertex\n")

    print("$(keys(graph.int_eproperties)) - Int - Edge\n")
    print("$(keys(graph.float_eproperties)) - Float - Edge\n")
    print("$(keys(graph.string_eproperties)) - String - Edge\n")
end

        ##################################################
        # ---------------------------------------------- #
######### ------------ Graph Manipulation -------------- ##########
        # ---------------------------------------------- #
        ##################################################

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

"""
    Create graph from edgelist.

    edgelist is an array of dimension M x 2 containing
    the source and target of each edge.

    The function assumes that the vertices are labeled
    from 1 to N.
"""
function graph_from_edgelist(edgelist::Array{Int, 2}, is_directed::Bool)
    g = Graph(is_directed)
    N = maximum([maximum(edgelist[:,1]), maximum(edgelist[:,2])])

    # -- Create the vertices --
    for j in 1:N
        add_node(g)
    end
    # -- Then, build the connections
    for j in 1:length(edgelist[:,1])
        add_edge(edgelist[j,1], edgelist[j,2], g)
    end
    return g
end

"""
    Check if the edge(i,j) already exists in the network.
    If the network is directed, then we check for i->j, while
    for the undirected, i<->j.

    Time complexity: O(k), where k = k_i + k_j.
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
    #if is_edge(i, j, graph)
    #    return 
    #end
    # -- Create the edge object --
    new_edge = Edge(node_i.index, node_j.index, is_directed)
    append!(node_i.edges_source, [new_edge])
    append!(node_j.edges_target, [new_edge])
    append!(graph.edges, [new_edge])
    new_edge.index = length(graph.edges)
    graph.M += 1
end

"""
    If the network is directed, returns outcoming neighbors.
    Otherwise, returns all neighbors.
"""
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
        append!(neighbors, [cur_edge.target])
    end
    return collect(Int, Set(neighbors))
end

function copy_graph(graph::Graph)
    cpy_g = Graph(graph.is_directed)
    cpy_g.N = graph.N
    cpy_g.M = graph.M
    cpy_g.vertices = copy(graph.vertices)
    cpy_g.edges = copy(graph.edges)
    cpy_g.int_vproperties = copy(graph.int_vproperties)
    cpy_g.float_vproperties = copy(graph.float_vproperties)
    cpy_g.string_vproperties = copy(graph.string_vproperties)
    cpy_g.int_eproperties = copy(graph.int_eproperties)
    cpy_g.float_eproperties = copy(graph.float_eproperties)
    cpy_g.string_eproperties = copy(graph.string_eproperties)
    return cpy_g
end

