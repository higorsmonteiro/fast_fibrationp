#=

=#

"""
    -------------------------------------------------------------------
    Build the fundamental data structures to define vertices, edges and 
    the graph itself.
    -------------------------------------------------------------------
"""

# -- Define an edge --
mutable struct Edge
    index::Int
    source::Int
    target::Int
    function Edge(source::Int, target::Int)
        index = -1
        new(index, source, target)
    end
end

# -- Define a Vertex --
mutable struct Vertex
    index::Int
    edges_source::Array{Edge}
    edges_target::Array{Edge}
    function Vertex(index::Int)
        edges_source = Edge[]
        edges_target = Edge[]
        new(index, edges_source, edges_target)
    end
end

# -- Define a graph structure -- 
mutable struct Graph
    N::Int
    M::Int
    is_directed::Bool
    vertices::Array{Vertex}
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
        vertices = Vertex[]
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
    Create a new Vertex in the given Graph.
"""
function add_node(graph::Graph)
    index = graph.N+1
    new_node = Vertex(index)
    push!(graph.vertices, new_node)
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

    # -- Create the edge object --
    new_edge = Edge(node_i.index, node_j.index)
    push!(node_i.edges_source, new_edge)
    push!(node_j.edges_target, new_edge)
    push!(graph.edges, new_edge)
    new_edge.index = length(graph.edges)
    graph.M += 1
end

"""
    Check if the edge(i,j) already exists in the network.
    If the network is directed, then we check for i->j, while
    for the undirected, i<->j.
"""
function is_edge(i, j, graph::Graph)
    node_i = graph.vertices[i]
    node_j = graph.vertices[j]
    is_directed = graph.is_directed

    if is_directed
        out_edges = node_i.edges_source
        for cur_edge in out_edges
            if cur_edge.target == node_j.index
                return true
            end
        end
    else
        out_edges = node_i.edges_source
        in_edges = node_i.edges_target
        for cur_edge in out_edges
            if cur_edge.target == node_j.index
                return true
            end
        end
        for cur_edge in in_edges
            if cur_edge.source == node_j.index
                return true
            end
        end
    end
    return false
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

# -----> COPY FUNCTIONS FOR GRAPH <----- #

function get_edgelist(graph::Graph)
    M = graph.M
    edgelist = zeros(Int, (M,2))
    for (j, edge) in enumerate(graph.edges)
        edgelist[j,1] = edge.source
        edgelist[j,2] = edge.target
    end
    return edgelist
end

function copy_graph(graph::Graph)
    edges = get_edgelist(graph)
    new_graph = graph_from_edgelist(edges, graph.is_directed)

    new_graph.int_vproperties = copy(graph.int_vproperties)
    new_graph.float_vproperties = copy(graph.float_vproperties)
    new_graph.string_vproperties = copy(graph.string_vproperties)
    new_graph.int_eproperties = copy(graph.int_eproperties)
    new_graph.float_eproperties = copy(graph.float_eproperties)
    new_graph.string_eproperties = copy(graph.string_eproperties)
    return new_graph
end

