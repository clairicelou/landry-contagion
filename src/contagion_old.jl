using Graphs

# --- Graph setup ---
# small-world graph (watts_strogatz), feels closer to how a real social
# network is shaped, found this generator in the Graphs.jl docs
g = watts_strogatz(10, 4, 0.3)  # 10 nodes, avg degree ~4, 30% rewire probability

n = nv(g)  # number of nodes, just so I don't have to keep typing nv(g)

# state vector: 0 = susceptible, 1 = infected
# using Int instead of Bool bc it's easier to sum() later for infection counts
node_states = zeros(Int, n)

# randomly pick the starting infected node
seed_node = rand(1:n)
node_states[seed_node] = 1


"""
    step_contagion(kernel, graph, node_states)

does ONE time step of the contagion spreading. loops over every node,
if it's infected, tries to infect each susceptible neighbor based on
whatever probability the kernel function spits out.

put kernel first here bc I looked it up and apparently Julia's style
guide says function arguments should go first, something about it
letting you use do-blocks? still not 100% sure when I'd actually use
that but figured I'd follow the convention since it's technically "correct"
"""
function step_contagion(kernel, graph, node_states)
    # gotta copy this or we'd be modifying node_states while still
    # looping over it, which would mess up the results (learned this
    # the hard way in a different assignment lol)
    new_states = copy(node_states)

    for node in vertices(graph)
        # skip this node if it's not infected, nothing to spread
        node_states[node] != 1 && continue

        # go through every neighbor of this infected node
        for neighbor in neighbors(graph, node)
            # only try to infect it if it's still susceptible
            if node_states[neighbor] == 0 && rand() < kernel(node, neighbor)
                new_states[neighbor] = 1
            end
        end
    end

    return new_states
end


"""
    run_contagion(kernel, graph, node_states, steps)

runs the simulation for however many steps we want and prints out what's
happening at each step so we can actually see it spread instead of just
getting the final answer. also keeps track of how many people are infected
at each step so we can plot it later (need to figure out how to actually
make a plot in Julia still, prob Plots.jl or Makie?)
"""
function run_contagion(kernel, graph, node_states, steps)
    # start with whatever the initial infected count is (should just be 1)
    infected_counts = Int[sum(node_states)]

    for step in 1:steps
        node_states = step_contagion(kernel, graph, node_states)
        push!(infected_counts, sum(node_states))
        println("Step $step: ", node_states, "  (infected: $(sum(node_states)))")
    end

    return node_states, infected_counts
end


# --- kernel function ---
# probability of infection between two nodes, went with something
# degree-based, idea is a node with a ton of connections is "less
# focused" on any one neighbor so the per-contact chance is lower.
# not sure if this is actually how real epidemiology models do it,
# definitely a question for the meeting
degree_kernel = (node, neighbor) -> 0.6 / degree(g, neighbor)

final_states, history = run_contagion(degree_kernel, g, node_states, 10)

println("\nSeed node was: $seed_node")
println("Infected count per step: ", history)