#=
    Module for fibration partitioning. 
        - Fast fibration partitioning
        - Minimal balacing coloring.
=#

mutable struct Fiber
    index::Int
    number_nodes::Int
    number_regulators::Int
    regulators::Array{Int}
    nodes::Array{Int}
    input_type::Dict{Int, Int}
    function Fiber()
        index = 0
        number_nodes = 0
        number_regulators = 0
        regulators = Int[]
        nodes = Int[]
        input_type = Dict{Int, Int}()
        new(index, number_nodes, number_regulators, 
            regulators, nodes, input_type)
    end
end

function insert_nodes(nodelst::Int, fiber::Fiber)
    fiber.number_nodes += 1
    append!(fiber.nodes, [nodelst])
end

function insert_nodes(nodelst::Array{Int}, fiber::Fiber)
    append!(fiber.nodes, nodelst)
    fiber.number_nodes = length(fiber.nodes)
end

function delete_nodes(nodelist::Array{Int}, fiber::Fiber)
    fiber.nodes = [ node for node in fiber.nodes if !(node in nodelist)]
    fiber.number_nodes = length(fiber.nodes)
end

function insert_regulator(reg::Int, fiber::Fiber)
    append!(fiber.regulators, [reg])
    fiber.number_regulators += 1
end

function get_nodes(fiber::Fiber)
    return fiber.nodes
end

function num_nodes(fiber::Fiber)
    return fiber.number_nodes
end

function sucessor_nodes(graph::Graph, fiber::Fiber)
    sucessor = Int[]
    for node in fiber.nodes
        out_neigh = get_out_neighbors(node, graph)
        append!(successor, out_neigh)
    end
    return collect(Int, Set(sucessor))
end

function input_stability(fiber::Fiber, graph::Graph, set::Fiber, num_edgetype::Int)
    set_nodes = get_nodes(set)
    edges_received = zeros(Int, num_edgetype, length(fiber.nodes))

    for setnode in set_nodes
        index = -1
        ## find index
        for (j, fnode) in enumerate(fiber.nodes)
            if fnode==setnode
                index = j
                break
            end
        end

        node_obj = graph.vertices[setnode]
        in_edges = node_obj.edges_target
        # we need to find the index of the edge 
    end
end
