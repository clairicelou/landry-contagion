
using Graphs
using Random # randomly sample degrees and select nodes later

function create_static_network(n)
    # Create a directed graph with n nodes and no edges
    graph = SimpleDiGraph(n)

    return graph
end

function sample_power_law(n, alpha, max_degree)
    # Possible degree values
    degrees = collect(1:max_degree)

    # Calculate the probability weight for each degree
    weights = [1 / k^alpha for k in degrees]

    # Convert weights into probabilities
    probabilities = weights / sum(weights)

    # Sample one degree for each node
    samples = Int[]

    # Sample a degree for each node
    for i in 1:n
        r = rand() # Generate a random number between 0 and 1
        cumulative = 0.0 # Start the cumulative probability at 0
# This loop checks the possible degrees one at a time until it finds which one corresponds to our random number.
        for k in eachindex(degrees)
            cumulative += probabilities[k] # Add the current degree's probability
# Check if the random number falls within this degree's range
            if r < cumulative
                push!(samples, degrees[k])  # Add the selected degree to samples
                break # Stop checking degrees for this node
            end
        end
    end

    return samples # Return the sampled degrees for all nodes
end


# Attempt to add one random directed edge
function add_random_edge!(graph, kin, kout)

    # Randomly select two different nodes
    i, j = randperm(nv(graph))[1:2]

    # Randomly decide which node is the source and target
    if rand() < 0.5 # Generates a random number between 0 and 1. There is a 50% chance that the condition is true.
        source = i
        target = j # If the condition is true, node i sends the edge to node j.
    else # If the condition is false, we reverse the direction.
        source = j
        target = i  # Now node j sends the edge to node i.
    end

    # Print the selected source and target
    println("Source: ", source)
    println("Target: ", target)

    # Check if the source can send, the target can receive, and the edge does not already exist
    if kout[source] > 0 && kin[target] > 0 && !has_edge(graph, source, target)

        # Add a directed edge from source to target
        add_edge!(graph, source, target)
        println("Edge added!")

        # Decrease the remaining degrees after adding the edge
        kout[source] -= 1
        # This decreases the target's remaining in-degree by 1 because it just received an edge.
        kin[target] -= 1

        return true
    else
        println("Invalid connection!")
    end

    return false
end



# Check basic requirements for directed degree sequences
function valid_degree_totals(kin, kout)
    n = length(kin) # Gets the number of nodes.

    # Each node needs an in-degree and out-degree
    if length(kout) != n # Makes sure every node has both an incoming and outgoing degree
        return false
    end

    # Degrees must be between 0 and n-1
    if any(k -> k < 0 || k >= n, kin) || # Checks whether any degree is negative or too large
       any(k -> k < 0 || k >= n, kout)
        return false
    end

    # Total incoming edges must equal total outgoing edges
    return sum(kin) == sum(kout) 
end


# Check whether the degree sequences can form a directed graph
function is_graphical(kin, kout)
    if !valid_degree_totals(kin, kout)
        return false
    end

    n = length(kin)
    graph = SimpleDiGraph(n)

    return can_complete(graph, copy(kin), copy(kout))
end

# Try all possible valid edges until the degrees are filled
function can_complete(graph, kin, kout)
    if all(kin .== 0) && all(kout .== 0)
        return true
    end
    # Try each possible source and target
    for source in vertices(graph)
        for target in vertices(graph)
            if source != target &&
               kout[source] > 0 &&
               kin[target] > 0 &&
               !has_edge(graph, source, target)

                add_edge!(graph, source, target)
                kout[source] -= 1
                kin[target] -= 1

                if can_complete(graph, kin, kout)
                    return true
                end

                rem_edge!(graph, source, target)
                kout[source] += 1
                kin[target] += 1
            end
        end
    end

    return false
end




# Check whether any valid directed edges remain
function has_valid_edges(graph, kin, kout)

    # Check every possible source node
    for source in vertices(graph)

        # Check every possible target node
        for target in vertices(graph)

            # Check if the nodes can still be connected
            if source != target && kout[source] > 0 && kin[target] > 0 && !has_edge(graph, source, target)
                return true
            end
        end
    end

    return false
end



# Generate a static directed network
function generate_network(n)

    # Create an empty directed graph
    graph = create_static_network(n)

# randomly generate the in-degree and out-degree for every node in my directed network
kin = sample_power_law(n, 2.5, n - 1)
kout = sample_power_law(n, 2.5, n - 1)

# Keep sampling until the degree sequences can form a valid network
while !is_graphical(kin, kout) # Keeps looping while the sampled degrees cannot form a valid directed network.
    kin = sample_power_law(n, 2.5, n - 1) # Samples a new set of incoming degrees.
    kout = sample_power_law(n, 2.5, n - 1) # Samples a new set of outgoing degrees.
end

# Print the degree sequences
println("In-degrees: ", kin)
println("Out-degrees: ", kout)

# Check the total number of incoming and outgoing edges
println("Total in-degree: ", sum(kin))
println("Total out-degree: ", sum(kout))

# Check if the total in-degree equals the total out-degree
if sum(kin) == sum(kout) # adds all the incoming edges = adds all the outgoing edges
    println("Degree totals match!")
else
    println("Degree totals do not match!")
end




# Find a complete set of edges using backtracking
success = can_complete(graph, kin, kout)

# Check whether all requested degrees were filled
if all(kin .== 0) && all(kout .== 0)
    println("Success! All degrees were filled.")
else
    println("Network incomplete! Some degrees remain unfilled.")
end


# Print the final results
println("Number of edges: ", ne(graph))
println("Remaining in-degrees: ", kin)
println("Remaining out-degrees: ", kout)
println("Valid edges remaining: ", has_valid_edges(graph, kin, kout))
# Show how many edges were created and whether any degrees remain unfilled.



# Check the actual in-degrees and out-degrees of the finished graph
println("Actual in-degrees: ", [indegree(graph, i) for i in vertices(graph)])
println("Actual out-degrees: ", [outdegree(graph, i) for i in vertices(graph)])


    # Only return the graph if all degrees were filled
    if all(kin .== 0) && all(kout .== 0) # Checks that every requested incoming and outgoing edge was successfully added.
        return graph # Returns the completed network if all degrees were filled.
    else # Handles the situation where some degrees remain unfilled.
        return nothing # Indicates that the attempt failed instead of returning an incomplete network.
    end
end # - The first end closes the if statement, the second closes the function.


# Try generating a complete network up to 10 times
graph = nothing

for attempt in 1:10
    println("Network attempt: ", attempt)
    global graph = generate_network(5)

    if graph !== nothing
        break
    end
end

if graph === nothing
    println("Failed to generate a complete network after 10 attempts.")
else
    println("Successfully generated a complete network!")
end