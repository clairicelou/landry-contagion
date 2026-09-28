# Load the functions from my src/contagion.jl file so I can test them
using Test
using Graphs
using Supposition
using Supposition.Data

include("../src/contagion.jl")



# UNIT TESTS
# First test: Check if the contagion_one_step function works correctly
@testset "contagion_one_step" begin  # This creates a group of tests for contagion_one_step.
    # Create a simple graph
    graph = path_graph(3)

    node_states = [1, 0, 0]  # Node 1 is infected, nodes 2 and 3 are not
    kernel = node -> 0.0  # 0% probability of infection

    result = contagion_one_step(graph, kernel, node_states) # Call the function
    @test result == [1, 0, 0]  # Expect no change since probability is 0/Julia checks whether the result is exactly what we expected.

end

# Second test: Check using 100% probability of infection
@testset "contagion_one_step with 100% probability" begin
    graph = path_graph(3)

    node_states = [1, 0, 0]  # Node 1 is infected, nodes 2 and 3 are not
    kernel = node -> 1.0  # 100% probability of infection

    result = contagion_one_step(graph, kernel, node_states) # Call the function
    @test result == [1, 1, 0]  # Expect node 2 to be infected
end

# Third test: Check if the simulate_contagion function works correctly
@testset "simulate_contagion" begin
    graph = path_graph(3)
    node_states = [1, 0, 0]  # Node 1 is infected, nodes 2 and 3 are not
    kernel = node -> 1.0  # 100% probability of infection
    result = simulate_contagion(graph, kernel, node_states, 2) # Simulate for 2 steps
    @test result == [1, 1, 1]  # Expect all nodes to be infected after 2 steps
end

# Fourth test: if already infected nodes stay infected
@testset "infected nodes stay infected" begin
    graph = path_graph(3)
    node_states = [1, 1, 0]  # Nodes 1 and 2 are infected, node 3 is not
    kernel = node -> 0.0  # 0% probability of infection
    result = contagion_one_step(graph, kernel, node_states)
    @test result == [1, 1, 0]  # Expect no change after 1 step
end



# PROPERTY TESTS
# 1st test: Check if the number of infected nodes never decreases
@testset "number of infected nodes never decreases" begin
    graph = path_graph(3)
    node_states = [1, 0, 1]  # Node 1 is infected, node 2 is not, node 3 is infected
    kernel = node -> 0.5  # 50% probability of infection

    result = contagion_one_step(graph, kernel, node_states)

    @test sum(result) >= sum(node_states)  # Expect the number of infected nodes to never decrease
    # sum(node_states) counts the infected nodes because the vector contains only 0s and 1s
end

# 2nd test: supposition test to check if the number of infected nodes never decreases
# Supposition generates different states vectors and checks the property
@check function test_infected_never_decreases(

    # Generate a vector containing 0s and 1s, with between 1 and 5 nodes
    states = Data.Vectors(Data.Integers(0, 1); min_size=1, max_size=5)
) 
    # Create a path graph with the same number of nodes as the states vector
    graph = path_graph(length(states))

    # Set the infection probability to 50%
    kernel = node -> 0.5

    # Run one step of the contagion process using the generated states
    result = contagion_one_step(graph, kernel, states)

    # Check that the number of infected nodes did not decrease
    sum(result) >= sum(states)
end
