#=
    Utility functions to handle I/O graph in forms of edgefiles.
=#

"""
    Create graph from edgelist.

    edgelist is an array of dimension M x 2 containing
    the source and target of each edge.

    The function assumes that the vertices are labeled
    from 1 to N.
"""
function graph_from_edgelist(edgelist::Array{Int, 2}, is_directed::Bool)
    graph = Graph(is_directed)
    N = maximum([maximum(edgelist[:,1]), maximum(edgelist[:,2])])

    # -- Create the vertices --
    for j in 1:N
        add_node(graph)
    end
    # -- Then, build the connections
    for j in 1:length(edgelist[:,1])
        add_edge(edgelist[j,1], edgelist[j,2], graph)
    end
    return graph
end

"""
    Given a formatted edgelist file, it returns two objects: a N x 2
    array containing the edgelist with format [[src,tgt], ...] and 
    a array of string arrays containing all the other columns in the file.

    Example:
    file -> "1 2 prop1 prop2
             2 3 prop1 prop2
             ... ..... ....."

    returns ->
    [1 2; 2 3; ...] and [["prop1", "prop2"], ["prop1", "prop2"], ...]
"""
function process_edgefile(fname::String, convert_int=false)
    src_tgt = Array{String}[]
    edge_prop = Array{String}[]
    
    open(fname, "r") do f
        for line in eachline(f)
            line_elem = split(line)
            elem1 = [ line_elem[1], line_elem[2] ]
            #elem1 = Int[parse(Int, line_elem[1]), parse(Int, line_elem[2])]

            append!(src_tgt, [elem1])
            append!(edge_prop, [line_elem[3:length(line_elem)]])
        end
    end

    src_tgt = reduce(hcat, src_tgt)
    edges = permutedims(src_tgt)
    if convert_int
        edges = parse.(Int, edges)
    end
    return edges, edge_prop
end

"""
    Process the edge properties returned by function 'process_edgefile'.
    
    As returned from 'process_edgefile', eprops is an array containing
    string arrays with the properties' values for each edge.

    For example, 'eprops' holds two string arrays if the edgefile has two
    extra columns. The size of these arrays are equal to the number of edges.
    For this, 'names' represents the arrays with the string names for each 
    column.

    Returns a dictionary where the keys are the names in 'names' and the
    values are arrays with the edge properties indexed from 1 to M. 
"""
function process_eprops(eprops::Array{Array{String}}, names::Array{String})
    container = Array{String}[]
    n_props = length(eprops[1])
    for j in 1:n_props
        append!(container, [String[]])
    end
    for j in 1:length(eprops)
        for k in 1:n_props
            append!(container[k], [eprops[j][k]])
        end
    end

    holder = Dict{String, Array{String}}()
    for (j, name) in enumerate(names)
        holder[name] = container[j]
    end
    return holder
end

"""

"""
function create_indexing(edges::Array{String,2})
    unroll = reduce(vcat, edges)
    unroll = collect(Set(unroll))
    N = length(unroll)

    hash = Dict{String, Int}()
    for (j, name) in enumerate(unroll)
        hash[name] = j
    end

    M, dummy = size(edges)
    new_edges = Array{Int}[]
    for j in 1:M
        u = hash[edges[j,1]]
        v = hash[edges[j,2]]
        append!(new_edges, [[u, v]])
    end
    new_edges = copy(transpose(reduce(hcat, new_edges)))
    return new_edges, hash
end

"""
    Read an edgelist file and returns a graph structure.

    'fname' refers to the file name holding the edgelist.

    If there is extra columns holding edge metadata, then 
    these properties will be included as a String edge property,
    in 'string_eproperties'.
"""
function load_net(fname::String, is_directed::Bool, convert_int=false)
    edges, eprops = process_edgefile(fname, convert_int)
    
    # -- If the nodes indexes are strings, create new indexing --
    if !convert_int
        edges, name_map = create_indexing(edges)
    end
    graph = graph_from_edgelist(edges, is_directed)

    # -- Save the original string indexes of nodes as 'node_name' vertex property --
    N = graph.N
    nodes_name = [ "" for j in 1:N ]
    if !convert_int
        keys_name = collect(keys(name_map))
        for key in keys_name
            nodes_name[name_map[key]]*=key
        end
        set_vertices_properties("node_name", nodes_name, graph)
    end

    fmt_eprops = Dict{String, Array{String}}()
    if length(eprops[1])!=0
        col_names = [ "Column $j" for j in 1:length(eprops[1]) ]
        fmt_eprops = process_eprops(eprops, col_names)
    end
    return graph, fmt_eprops
end