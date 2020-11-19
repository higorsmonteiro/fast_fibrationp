#=
    Define 'Fiber' object and its main methods.

    Define 'StrongComponent' object and its main methods.
=#

## ------------> FIBER OBJECT <------------- ##

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

"""
    Returns all nodes in 'graph' that is pointed by 'fiber'.
    This function is important to define an efficient procedure
    to determine which fibers are input-set unstable with 
    respect to 'fiber', assuring a time complexity of the order
    of the outgoing neighborhood of 'fiber'.
"""
function sucessor_nodes(graph::Graph, fiber::Fiber)
    sucessor = Int[]
    for node in fiber.nodes
        out_neigh = get_out_neighbors(node, graph)
        append!(successor, out_neigh)
    end
    return collect(Int, Set(sucessor))
end

"""
   Given the two fiber objects 'fiber' and 'pivot', it checks if 'fiber'
   is input-set stable with respect to 'pivot', that is, every node of
   'fiber' receives equivalent information, through 'graph', from 'pivot'.

   if input-set stable, returns true. Otherwise, returns false.

    *** MISMATCH IN THE PYTHON CODE - CHECK LATER.
"""
function input_stability(fiber::Fiber, pivot::Fiber, graph::Graph, num_edgetype::Int)
    fiber_nodes = get_nodes(fiber)
    pivot_nodes = get_nodes(pivot)
    edges_received = Dict{Int,Array{Int}}()

    edgelist = graph.edges
    edgetype = graph.int_eproperties["edgetype"]

    # -- initiate the input-set array for each node of 'fiber' --
    for node in fiber_nodes
        edges_received[node] = zeros(Int, num_edgetype)
    end

    # -- Based on the outcoming edges of 'pivot' set, we set the
    # -- input-set of each node of 'fiber'.
    for w in pivot_nodes
        pivot_obj = graph.vertices[w]
        out_edges = pivot_obj.edges_source
        for out_edge in out_edges
            edge_index = out_edge.index
            target_node = out_edge.target
            if get(edges_received, target_node, -1)!=-1
                edges_received[target_node][edge_index] += 1
            end
        end
    end

    # -- Check input-set stability --
    for j in 1:length(fiber_nodes)-1
        if edges_received[fiber_nodes[j]]!=edges_received[fiber_nodes[j+1]]
            return false
        end
    end
    return true
end

function copy_fiber(fiber::Fiber)
    copy_fiber = Fiber()
    copy_fiber.index = fiber.index
    copy_fiber.nodes = copy(fiber.nodes)
    copy_fiber.input_type = copy(fiber.input_type)
    copy_fiber.number_nodes = length(copy_fiber.nodes)
    copy_fiber.number_regulators = fiber.number_regulators
    copy_fiber.regulators = copy(fiber.regulators)
    return copy_fiber
end

## ---------------> StrongComponent < ---------------- ##

mutable struct StrongComponent
    number_nodes::Int
    have_input::Bool
    nodes::Array{Int}
    type::Int
    function StrongComponent()
        number_nodes = 0
        have_input = false
        nodes = Int[]
        type = -1
        new(number_nodes, have_input, nodes, type)
    end
end

"""
    Add 'node' to 'strong' object. If 'node' is an array
    of nodes, then all nodes are inserted.
"""
function insert_nodes(node::Int, strong::StrongComponent)
    strong.number_nodes += 1
    append!(strong.nodes, [node])
end

function insert_nodes(node::Array{Int}, strong::StrongComponent)
    strong.number_nodes += length(node)
    append!(strong.nodes, node)
end

function get_nodes(strong::StrongComponent)
    return strong.nodes
end

function get_input_bool(strong::StrongComponent)
    return strong.have_input
end

"""
    Check if the given SCC receives or not input from another 
    components in the 'graph'.

    the field 'have_input' of 'strong' is modified to 'true'
    if the component receives external information. Otherwise,
    'have_input' maintains its default ('false').
"""
function check_input(strong::StrongComponent, graph::Graph)
    from_out = false
    for u in strong.nodes
        input_nodes = get_in_neighbors(u, graph)
        for w in input_nodes
            if w in strong.nodes
                from_out = false
            else
                from_out = true
            end
            if from_out
                strong.have_input = true
                break
            end
        end
        if strong.have_input
            break
        end
    end
    return
end

"""
    This function should be called after 'check_input'
"""
function classify_strong(strong::StrongComponent, graph::Graph)
    if strong.have_input
        strong.type = 0
    else
        """
            If it doesn't receive any external input, then we
            must check if it is an isolated self-loop node.
        """
        if length(strong.nodes)==1
            in_neighbors = get_in_neighbors(strong.nodes[1], graph)
            if length(in_neighbors)==0
                strong.type = 1
            else
                strong.type = 2 # Isolated self-loop node.
            end
        else
            strong.type = 1 # SCC does not have external input.
        end
    end
    return
end
