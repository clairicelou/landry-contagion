using Graphs
using Random

# A node can be infected by the nodes it follows (its out-neighbors)

# One step of contagion, also returns (parent, child) for each new infection
function contagion_step_with_parents(graph, kernel, node_states, rng=Random.default_rng())

    # Create a copy to store the updated states
    new_states = copy(node_states)
    new_infections = Tuple{Int,Int}[]

    for node in vertices(graph)

        # Only susceptible nodes can be infected
        node_states[node] == 0 || continue

        # Infected neighbors of this node
        infected_neighbors = [nb for nb in outneighbors(graph, node) if node_states[nb] == 1]

        # Skip nodes with no infected neighbors
        isempty(infected_neighbors) && continue

        # Apply the kernel based on the number of infected neighbors
        probability = kernel(length(infected_neighbors))

        # Infect the node based on the probability
        if rand(rng) < probability
            new_states[node] = 1
            push!(new_infections, (rand(rng, infected_neighbors), node))
        end
    end

    return new_states, new_infections
end


# Returns only the updated states
function contagion_one_step(graph, kernel, node_states)
    new_states, _ = contagion_step_with_parents(graph, kernel, node_states)
    return new_states
end


function simulate_contagion(graph, kernel, node_states, steps)

    for step in 1:steps
        node_states = contagion_one_step(graph, kernel, node_states)
        println("Step $step: ", node_states)
    end

    return node_states
end


# Run a cascade from one seed node and record who infected whom
function run_cascade(graph, kernel, seed_node, steps; rng=Random.default_rng())
    n = nv(graph)
    node_states = zeros(Int, n)
    node_states[seed_node] = 1

    parents = zeros(Int, n)
    infection_step = fill(-1, n)
    infection_step[seed_node] = 0

    for step in 1:steps
        node_states, new_infections = contagion_step_with_parents(graph, kernel, node_states, rng)
        for (parent, child) in new_infections
            parents[child] = parent
            infection_step[child] = step
        end
    end

    return parents, infection_step
end
