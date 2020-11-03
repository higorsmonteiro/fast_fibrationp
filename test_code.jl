include("netx.jl")

import .my_net

# Read the edgelist file and returns the edgelist and all other columns, if any.
(edges, eprops) = my_net.process_edgefile("test_datasets/test_edgelist.txt")

# generate the network from the edgelist.
net = my_net.new_graph_from_edgelist(edges, true)

# Assign the other columns as properties for the edges.
eprops_cols = ["some_weight", "some_string"]
eprops_dict = my_net.process_eprops(eprops, eprops_cols)

weight = parse.(Int, eprops_dict["some_weight"])
my_net.set_edges_properties("some_weight", weight, net)

print(net.int_eproperties)

er_example = my_net.ER_k(256, 2.0, false)
deg = my_net.get_degree(er_example, "total")
#my_net.printGraph(er_example)
print("\n")
print(sum(deg)/256.0)
print("\n $(er_example.N)")

#my_net.printGraph(net)
# print("\n")
# print(my_net.DFS(1, net))
# print("\n")
# print(my_net.extract_scc(net))