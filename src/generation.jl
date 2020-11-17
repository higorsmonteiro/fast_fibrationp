#=
    Network generation.
=#

"""
    Returns an erdos-renyi random network according the G(N, p) model.

    N -> number of nodes
    p -> edge probability
    is_directed -> bool for the directness of the network
    self -> true if self-loops are allowed.
"""
function erdos_renyi_net(N::Int, p::Float64, is_directed::Bool, self=false)
    if p<=0 || p>=1
        return
    end

    graph = Graph(is_directed)
    for i in 1:N
        add_node(graph)
    end

    w = -1
    lp = log(1.0-p)

    if is_directed # ----- directed -----
        v = 0
        while v < N
            mu = rand(1)[1]
            lr =  log(1.0 - mu)
            w += (1 +  floor(Int, lr/lp))
            while v<N && N<=w
                w -= N
                v += 1
            end
            if v < N
                if v==w && self
                    add_edge(v+1, w+1, graph)
                elseif v!=w
                    add_edge(v+1, w+1, graph)
                end
            end
        end
    else # ----- undirected -----
        v = 1
        while v < N
            mu = rand(1)[1]
            lr = log(1.0 - mu)
            w += 1 + floor(Int, lr/lp)
            while w >= v && v < N
                w -= v
                v += 1
            end
            if v < N
                add_edge(v+1, w+1, graph)
            end
        end
    end
    return graph
end


"""
    Generate a random network by parsing G(N, <k>) where <k>
    is the desired mean degree of the final network.
"""
function ER_k(N::Int, k_mean::Float64, is_directed::Bool, self=false)
    p = k_mean/(N-1)
    graph = erdos_renyi_net(N, p, is_directed, self)
    return graph
end

"""
    Generate a random network by parsing the desired number of nodes,
    desired mean degree and number of types of edges.

    the edge property receives the name "edgetype".
"""
function ER_multi(N::Int, k_mean::Float64, n_types::Int, is_directed::Bool, self=false)
    graph = ER_k(N, k_mean, is_directed, self)
    possible_types = [j for j in 1:n_types]

    edgetypes_prop = [ rand(possible_types) for j in 1:length(graph.edges) ]
    set_edges_properties("edgetype", edgetypes_prop, graph)
    return graph
end

"""
    Function specific for exporting the generated random networks.
    The only metadata exported together is the "edgetype" property.
"""
function export_edgefile(graph::Graph, fout::String)
    edges = graph.edges
    edgetype = graph.int_eproperties["edgetype"]
    open("$fout.txt", "w") do f
        for edge in edges
            write(f, "$(edge.source)\t$(edge.target)\t$(edgetype[edge.index])\n")
        end
    end
end