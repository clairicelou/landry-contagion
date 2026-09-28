# Load the functions from my src/contagion.jl file so I can test them
using Test
using Supposition
using Supposition.Data
using Graphs

include("../src/contagion.jl")


# UNIT TESTS

# First test: Check if the contagion_one_step function works correctly
@testset "contagion_one_step" begin

    # Create a simple graph
    graph = path_graph(3)

    node_states = [1, 0, 0]  # Node 1 is infected, nodes 2 and 3 are not
    kernel = node -> 0.0  # 0% probability of infection

    result = contagion_one_step(graph, kernel, node_states) # Call the function
    @test result == [1, 0, 0]  # Expect no change since probability is 0/Julia checks whether the result is exactly what we expected.


    # Second test: Check using 100% probability of infection
    graph = path_graph(3)

    node_states = [1, 0, 0]  # Node 1 is infected, nodes 2 and 3 are not
    kernel = node -> 1.0  # 100% probability of infection

    result = contagion_one_step(graph, kernel, node_states) # Call the function
    @test result == [1, 1, 0]  # Expect node 2 to be infected


    # Fourth test: if already infected nodes stay infected
    graph = path_graph(3)
    node_states = [1, 1, 0]  # Nodes 1 and 2 are infected, node 3 is not
    kernel = node -> 0.0  # 0% probability of infection
    result = contagion_one_step(graph, kernel, node_states)
    @test result == [1, 1, 0]  # Expect no change after 1 step
end


# Third test: Check if the simulate_contagion function works correctly
@testset "simulate_contagion" begin
    graph = path_graph(3)
    node_states = [1, 0, 0]  # Node 1 is infected, nodes 2 and 3 are not
    kernel = node -> 1.0  # 100% probability of infection
    result = simulate_contagion(graph, kernel, node_states, 2) # Simulate for 2 steps
    @test result == [1, 1, 1]  # Expect all nodes to be infected after 2 steps
end


@testset "contagion_one_step" begin
    @testset "Unit-Based Tests" begin
        graph = complete_graph(5)
        node_states = [1, 0, 0, 0, 0]

        # Run with 100% infection rate
        kernel = node -> 1
        @test contagion_one_step(graph, kernel, node_states) == [1, 1, 1, 1, 1]

        # Run with 0% infection rate
        kernel = node -> 0
        @test contagion_one_step(graph, kernel, node_states) == [1, 0, 0, 0, 0]
    end
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


@testset "contagion_one_step properties" begin

    graph = complete_graph(5)
    kernel = node -> 0.5

    # Infected nodes remain infected after a step
    @check function infected_stay_infected(
        node_states = Data.Vectors(Data.Integers(0, 1); min_size=5, max_size=5),
    )
        new_states = contagion_one_step(graph, kernel, node_states)
        return all(new_states[i] == 1 for i in eachindex(node_states) if node_states[i] == 1)
    end

    # Only 0s and 1s ever appear, and the vector length doesn't change
    @check function states_stay_valid(
        node_states = Data.Vectors(Data.Integers(0, 1); min_size=5, max_size=5),
    )
        new_states = contagion_one_step(graph, kernel, node_states)
        return length(new_states) == length(node_states) &&
               all(s -> s in (0, 1), new_states)
    end

    # The input vector isn't mutated (the function returns a copy)
    @check function input_not_mutated(
        node_states = Data.Vectors(Data.Integers(0, 1); min_size=5, max_size=5),
    )
        original = copy(node_states)
        contagion_one_step(graph, kernel, node_states)
        return node_states == original
    end

    # A 0% kernel never changes anything, whatever the starting states
    @check function zero_kernel_is_identity(
        node_states = Data.Vectors(Data.Integers(0, 1); min_size=5, max_size=5),
    )
        zero_kernel = node -> 0
        return contagion_one_step(graph, zero_kernel, node_states) == node_states
    end
end