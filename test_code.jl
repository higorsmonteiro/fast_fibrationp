include("netx.jl")

import .my_net

edgelist = [[1,2],[2,3],[3,1],[3,4],[4,5],[5,6],
            [6,7],[7,5],[7,8],[8,5]]

(edges, eprop) = my_net.process_edgefile("test_datasets/test_edgelist.txt")

print(eprop)
print("\n $(eprop[2])")

# res = copy(transpose(reduce(hcat, edgelist)))

# net = my_net.new_graph_from_edgelist(res, true)

# my_net.printGraph(net)
# print("\n")
# print(my_net.DFS(1, net))
# print("\n")
# print(my_net.extract_scc(net))