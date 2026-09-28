using Graphs

# graph with 5 nodes connected in a path
# The graph looks like: 1 -- 2 -- 3 -- 4 -- 5
g = path_graph(5)

# Get the number of nodes (vertices) in the graph
# Here n = 5
n = nv(g)

# Create a vector of length n where every node starts with state 0
# 0 will represent "not infected"
node_states = zeros(Int, n)

# Make node 1 infected
node_states[1] = 1


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


# Create a simple contagion kernel
# 50% probability for now
kernel = node -> 0.5

# Run one contagion step
# node_states = contagion_one_step(g, kernel, node_states)

# Print the result
# println(node_states)

node_states = simulate_contagion(g, kernel, node_states, 10)