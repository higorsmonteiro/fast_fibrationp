include("../netx.jl")

import .netx

edges, eprops = netx.process_edgefile("../datasets/hernan_data/Ecoli.txt")

fmt_edges, name_map = netx.create_indexing(edges)
fmt_eprops = netx.process_eprops(eprops, ["regulation"])

# -- Create a list associating the edgetype names with integers --
edgetype = Int[]
map_regulation = Dict([("positive", 1) ("negative", 2) ("dual", 3)])
for reg in fmt_eprops["regulation"]
    push!(edgetype, map_regulation[reg])
end

# -- Create network and set the edgetypes as an edge property --
g = netx.graph_from_edgelist(fmt_edges, true)
netx.set_edges_properties("edgetype", edgetype, g)

partition = netx.fast_fibration(g)