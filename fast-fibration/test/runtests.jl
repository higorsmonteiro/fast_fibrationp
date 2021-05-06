using FastFibration
using Test

@testset "FastFibration.jl" begin
    # Testing vertex obj
    @test FastFibration.Vertex(0).index == 0
    @test length(FastFibration.Vertex(0).edges_source) == 0
    @test length(FastFibration.Vertex(0).edges_target) == 0
end
