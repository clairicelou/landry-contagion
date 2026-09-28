using Test
using Supposition
using Graphs

# Test File for contagion.jl
include("../src/contagion.jl")


# Unit-Based Tests

@testset "contagion_one_step" begin
    graph = complete_graph(5)
    node_states = [1, 0, 0, 0, 0]


    # Run with 100% infection rate 
    kernel = node -> 1
    @test contagion_one_step(graph, kernel, node_states) == [1,1,1,1,1]

    # Run with 0% infection rate
    kernel = node -> 0
    @test contagion_one_step(graph, kernel, node_states) == [1,0,0,0,0]
end

# Property-Based Tests
