using Test
using Supposition
using Graphs

# Test File for contagion.jl

# Unit-Based Tests

@testset "contagion_one_step" begin
    # Run with 100% infection rate 
    kernel = node -> 1
    # graph = 
    node_states = zeros(Int, 10)
    node_states[1] = 1
    @Test contagion_one_step(complete_graph(5), node -> 1, [1,0,0,0,0])
end
# Property-Based Tests
