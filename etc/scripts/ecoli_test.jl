include("../fsym.jl")

import .fsym

g, fmt_eprops = fsym.load_net("../datasets/rawData/Ecoli.txt", true)

partition = fsym.fast_fibration(g)

fiber_count, all_classes, v_per_fiber = fsym.count_fiber(partition, g)

print("Non-trivial fibers: $fiber_count, All partition elements: $all_classes\n $(v_per_fiber)\n")