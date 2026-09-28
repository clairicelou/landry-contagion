using Test
using Supposition
using Graphs

# Test File for contagion.jl
include("../src/contagion.jl")


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

    @testset "Property-Based Tests" begin
        graph = complete_graph(5)
        kernel = node -> 0.5
        # node_state_example = [1, 0, 0, 0, 0]
        # Supposition.Data.example(node_state_example)

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
end