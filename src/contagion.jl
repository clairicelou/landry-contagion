using Graphs


function contagion_one_step(graph, kernel, node_states)

    # Create a copy to store the updated states
    new_states = copy(node_states)

    # Check each node in the graph
    for node in vertices(graph)

        # Check if the node is infected
        if node_states[node] == 1

            # Check each neighbor of the infected node
            for neighbor in neighbors(graph, node)

                # If the neighbor is not infected, infect it
                if node_states[neighbor] == 0
                    probability = kernel(neighbor)
                    
                    if rand() < probability
                        new_states[neighbor] = 1
                    end 
                end
            end
        end
    end

    # Return the updated states
    return new_states
end


function simulate_contagion(graph, kernel, node_states, steps)

    for step in 1:steps
        node_states = contagion_one_step(graph, kernel, node_states)
        println("Step $step: ", node_states)
    end

    return node_states
end