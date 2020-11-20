#=
    Utility functions for proper benchmarking between FFP and MBC.
=#
push!(LOAD_PATH, "../"); using netx
using BenchmarkTools

function open_random_net(path::String, N::Int, k::Float64, ntype::Int, samp::Int)
    fname = "$(path)TYPE$(ntype)/ER_N$(N)_k$(k)_samp$(samp).txt"
    edges, eprops = netx.process_edgefile(fname, true)
    fmt_eprops = netx.process_eprops(eprops, ["etype"])
    edgetype_prop = parse.(Int, fmt_eprops["etype"])

    g = netx.graph_from_edgelist(edges, true)
    netx.set_edges_properties("edgetype", edgetype_prop, g)
    return g
end

function process_samples_ffp(N::Int, ntype::Int, nsamples::Int, path::String)
    kmean_arr = Float64[ 1.0, 2.0, 4.0, 8.0 ]
    runtime = [ Float64[ 0.0 for j in 1:nsamples ] for i in 1:4 ]
    memory = [ Float64[ 0.0 for j in 1:nsamples ] for i in 1:4 ]

    print("Size $N\n")
    for (j, k_mean) in enumerate(kmean_arr)
        print("mean degree = $(k_mean)\n")
        for m in 1:nsamples
            print("$m ")
            g = open_random_net(path, N, k_mean, ntype, m)
            b = @benchmarkable fast_fibration($g)
            tune!(b)
            res = minimum(run(b))
            g = netx.Graph(true) # check garbage collector
            runtime[j][m] = res.time*1e-9 # seconds
            memory[j][m] = res.memory*1e-6 # megabytes
        end
        print("\n")
    end
    return runtime, memory
end

"""

"""
function do_measure(path::String, nsamples::Int, fout::String)
    ntypes = Int[1,2,4,8]
    sizes = Int[256, 512, 1024, 2048, 4096, 8192, 16384]

    time_dict = Dict{Int, Array{Float64}}()
    space_dict = Dict{Int, Array{Float64}}()
    for N in sizes
        time_dict[N] = Float[ 0.0, 0.0, 0.0, 0.0 ]
        space_dict[N] = Float[ 0.0, 0.0, 0.0, 0.0 ]
        for (k, nt) in enumerate(ntypes)
            time_measures, space_measures = process_samples_ffp(N, nt, nsamples, path)
            time_dict[N][k] = mean(time_measures)
            space_dict[N][k] = mean(space_measures)
        end
    end

    # -- Write to file --
    open(fout, "w") do f
        for N in sizes
            write(f,"$N")
            for (k, nt) in enumerate(ntypes)
                write(f, "\t$(time_dict[N][k])\t$(space_dict[N][k])")
            end
            write(f,"\n")
        end
    end
end

