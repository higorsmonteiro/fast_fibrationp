"""
    Generate a random network based on the G(N, p) Erdos-Renyi
    model.
"""
function fast_erdosr(N::Int, p::Float64, is_directed::Bool)
    if p<=0 || p>=1
        return
    end

    # Create the graph and its nodes.
    graph = Graph(is_directed)
    for i in 1:N
        add_node(graph)
    end

    w = -1
    lp = log(1.0-p)
    if is_directed
        v = 0
        while v < N
            lr = log(1.0 - rand(1)[1])
            w += (1 +  floor(Int, lr/lp))
            while v < N && N <= w
                w -= N
                v += 1
            end
            if v < N
                add_edge(v+1, w+1, graph)
            end
        end
    else
        v = 1
        while v < N
            lr = log(1.0 - rand(1)[1])
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
function ER_k(N::Int, k_mean::Float64, is_directed::Bool)
    p = k_mean/(N-1)
    graph = fast_erdosr(N, p, is_directed)
    return graph
end