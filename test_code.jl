include("netx.jl")

import .my_net

edges = copy(transpose(reduce(hcat, [[1,2],[2,3],[3,1],[3,4],
         [4,5], [5,6], [6,7], [7,5],
         [7,8], [8,5]])))

print(edges)


# # Read the edgelist file and returns the edgelist and all other columns, if any.
# (edges, eprops) = my_net.process_edgefile("test_datasets/test_edgelist.txt")

# # generate the network from the edgelist.
net = my_net.new_graph_from_edgelist(edges, true)

#my_net.printGraph(net)
#print(my_net.get_out_neighbors(7, net))

partition, pivot_queue = my_net.initialize(net)
for fiber in pivot_queue
    print("$(fiber.nodes)\n")
end

# # Assign the other columns as properties for the edges.
# eprops_cols = ["some_weight", "some_string"]
# eprops_dict = my_net.process_eprops(eprops, eprops_cols)

# weight = parse.(Int, eprops_dict["some_weight"])
# my_net.set_edges_properties("some_weight", weight, net)

# print(net.int_eproperties)

# #er_example = my_net.ER_k(256, 2.0, false)
# er_example = my_net.ER_multilayer(256, 2.0, 3, true)
# my_net.list_properties(er_example)