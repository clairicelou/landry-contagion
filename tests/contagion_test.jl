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
        @test contagion_one_step(graph, kernel, node_states) == [1,1,1,1,1]
        
        # Run with 0% infection rate
        kernel = node -> 0
        @test contagion_one_step(graph, kernel, node_states) == [1,0,0,0,0]
    end

    @testset "Property-Based Tests" begin
        # Node States remain 1 after being 'infected'
        graph = complete_graph(5)
        kernel = node -> 0.5
        # node_state_example = [1, 0, 0, 0, 0]
        # Supposition.Data.example(node_state_example)
        
        @check function generate_node_states(node_states = Data.Vectors(Data.Integers(0, 1), min_size=5, max_size=5))
            new_node_states = contagion_one_step(graph, kernel, node_states)
            for (i,node) in enumerate(node_states)
                if node == 1
                    if(new_node_states[i] == 1)
                    
                    else
                        return false

                    end
                end
            end

            return true
        end

        # Add more property-based tests HERE

    end


end
