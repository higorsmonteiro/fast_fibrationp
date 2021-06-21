include("../fsym.jl")
import .fsym

g, eprops = fsym.load_net("../datasets/rawData/Ecoli.txt", true, false)

nodelabels, unique, scc_trees = fsym.extract_strong(g, true)
nodelabels2, unique2, scc_trees2 = fsym.find_strong(g, true)

print("$(length(collect(keys(scc_trees)))), $(length(collect(keys(scc_trees2))))\n")

# --> all the SCCs are equal from both methods.
for v in 1:g.N
    if Set(scc_trees[nodelabels[v]])!=Set(scc_trees2[nodelabels2[v]])
        print("Nope\n")
    end
end

# -- 'sccs1' holds a list of 'StrongComponent' objects --
sccs1 = fsym.StrongComponent[]
for label in collect(keys(scc_trees))
    new_scc = fsym.StrongComponent()
    fsym.insert_nodes(scc_trees[label], new_scc)
    push!(sccs1, new_scc)
end
node_index1 = [-1 for j in 1:g.N]
for (index,scc) in enumerate(sccs1)
    for v in scc.nodes
        node_index1[v] = index
    end
end

# -- 'sccs2' holds a list of 'StrongComponent' objects --
sccs2 = fsym.StrongComponent[]
for label in collect(keys(scc_trees2))
    new_scc = fsym.StrongComponent()
    fsym.insert_nodes(scc_trees2[label], new_scc)
    push!(sccs2, new_scc)
end
node_index2 = [-1 for j in 1:g.N]
for (index,scc) in enumerate(sccs2)
    for v in scc.nodes
        node_index2[v] = index
    end
end

for (j, scc1) in enumerate(sccs1)
    fsym.check_input(scc1,g)
    fsym.classify_strong(scc1,g)
    if scc1.type==0
        outside_neighbors = Int[]
        for u in scc1.nodes
            in_neigh = fsym.get_in_neighbors(u, g)
            outside = [ w for w in in_neigh if !(w in scc1.nodes)  ]
            append!(outside_neighbors, outside)
        end
        outside_neighbors = collect(Set(outside_neighbors))
        print("TYPE 0: $j - $(scc1.nodes) - $(outside_neighbors)\n")
    elseif scc1.type==1
        outside_neighbors = Int[]
        for u in scc1.nodes
            in_neigh = fsym.get_in_neighbors(u, g)
            outside = [ w for w in in_neigh ]
            append!(outside_neighbors, outside)
        end
        outside_neighbors = collect(Set(outside_neighbors))
        print("TYPE 1: $j - $(scc1.nodes) - $(outside_neighbors)\n")
    else
        print("TYPE 2: $j - $(scc1.nodes) - $(fsym.get_in_neighbors(scc1.nodes[1], g))\n")
    end
end

count = Int[0]
for v in 1:g.N
    if length(fsym.get_in_neighbors(v, g))==0
        count[1] += 1
    end
end
print(count)
