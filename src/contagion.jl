using Graphs


function contagion_one_step(graph, kernel, node_states)

    # Create a copy to store the updated states
    new_states = copy(node_states)

    # Check each node in the graph
    for node in vertices(graph)

        # Check if the node is not infected
        if node_states[node] == 0

            # Count how many neighbors are infected
            infected_neighbors = 0

            # Check each neighbor of the current node
            for neighbor in neighbors(graph, node)
                if node_states[neighbor] == 1
                    infected_neighbors += 1
                end
            end

            # Apply the kernel based on the number of infected neighbors
            probability = kernel(infected_neighbors)

            # Infect the node based on the probability
            if rand() < probability
                new_states[node] = 1
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