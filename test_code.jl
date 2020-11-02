include("netx.jl")

import .my_net

adjlist = [[2], [3], [1,4], [5], [6],
           [7], [5,8], [5]]

net = my_net.create_graph(adjlist, true)
my_net.printGraph(net)
print("\n")
print(my_net.DFS(1, net))
print("\n")
print(my_net.extract_scc(net))