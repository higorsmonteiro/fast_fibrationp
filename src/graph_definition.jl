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