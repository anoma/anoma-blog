# the maximal depth of mempool hierarchies
const maxDepth=5
println("Set maximal depth of hierarchies 'maxDepth' is $maxDepth.")

# the number of locations at which intents flow in (derived from maxDepth)
const locations = 2^maxDepth
println("The number of locations 'locations' is $locations.")

# the number of different kinds of resources
const maxVariability = 2
println("The maximum variability of intents 'maxVariability' is $maxVariability.")

# An intent is issued at
# - a specific point in *time*
# - conerns only a single *resource*, and
# - occurrs at a specific *location*.
# an id is added for avoiding aliasing
struct Intent 
    time :: Float64
    resource :: Int
    location :: UInt
    id :: Int
end

using DataStructures
using Distributions
using Random
Random.seed!(123)

# We use `generateIntents`, a function, to generate intents for the experiment.
# The parameters of `generateIntents` are
# - the number of different resources: `var`
# - the mean waiting time between intents: `meanIntentWitingTime`
# (Note tha the number of locations is fixed as a global constant.)
function generateIntents(var::Int8, meanIntentWaitingTime::Float16)::Vector{Intent}
    
    print("Generating intents with variability $var")
    println(" and mean waiting time $meanIntentWaitingTime.")
    
    # We use exponentially distributed waiting times for intents
    local dist = Exponential(meanIntentWaitingTime)
    
    # a fresh empty list of intents
    local theList = MutableLinkedList{Intent}()
    
    # initialize the local sum of waiting times for new intents
    local localsum = 0;
    # sequence number for intents (as othewise we get aliasing of intents with the same time)
    local seq = 0;
    # as long as we do not reach the end of the experiment (at time unit 1)
    while (localsum < 1)
        # sample new waiting time and update sum of waiting times
        localsum += Random.rand(dist)
        # ☝️ this is the arrival time of the *next* intent
        seq += 1
        
        # randomly generate supply or demand for a random resource
        @assert var <= maxVariability && 0 < var "variability not good"
        local nextResource::Int = Random.rand([x for x in -var:var if x!=0])
        # randomly choose a location of where the intent flows into the system
        local nextLoc::UInt8 = Random.rand(1:locations)        
        @assert nextLoc in 1:locations
        # collect these data into the next next intent ... 
        let newIntent = Intent(localsum, nextResource, nextLoc, seq)
            # ... and push it to the list—at the ᴇɴᴅ
            push!(theList, newIntent)
        end
        
    end
    # some "info" printing
    local theLength = length(theList)
    @assert theLength > 3 "not enough intents!"
    
    local thePeek = (getindex(theList, div(theLength, 2)-1),
    getindex(theList, div(theLength, 2)),
    getindex(theList, div(theLength, 2)+1))
    println("intents created: $theLength \n‌and the first, median three, and last:\n");
    println("Intent #1 is $(theList[1])")
    for i in eachindex(thePeek)
        let index = i + (div(theLength, 2)-2)
            println("Intent #$index is $(thePeek[i])")
        end
    end
    println("Intent #$theLength is $(theList[theLength])")
    for i in theList
        @assert i.location in 1:locations
    end
    return collect(theList)
end

# each pool has 
# - a list of intents as `contents`, initially empty
# - a `depth`` in the hierarchy
# - a time stamp `nextTime` at which the next solving will happen
# - an `interval` for the time in between solving times
# - a `parent` pool (which points to "self" if it the root)
mutable struct Pool
    contents::MutableLinkedList{Intent}
    depth::UInt8
    nextTime::Float64
    interval::Float64
    now::Float64
    parent::Pool
    # the constructor for the root pool (the paramter is `interval`)
    Pool(t::Float64) =
    (x = new(MutableLinkedList{Intent}(),0,t,t,0); x.parent = x)
    # a constructor for non-root pools, also need `parent` and `depth` info
    Pool(d::UInt8, t::Float64, p::Pool) =
    new(MutableLinkedList{Intent}(),d,t,t,0,p)
    
end

# We generate a hiearchy of pools with the function `generatePools`:
# - depth is the depth of the binary tree
# - tick is the interval of leaf pools
function generatePools(depth::UInt8, tick::Float64)::Vector{Pool}
    # the linked list of pools to create the result
    local res = MutableLinkedList{Pool}()
    @assert depth <= maxDepth "Hierarchy too deep!"
    # starting from the root, generate pools
    for d::UInt8 in 0:depth
        # the interval and nextTime are doubling each time we go "up" in the hiearchy
        local next::Float64 = tick*2^(depth-d)
        # create 2^d pools at depth d
        for _ in 1:(2^d)
            if d == 0
                # this is ᴛʜᴇ root pool
                push!(res, Pool(next))
            else
                @assert d > 0 "just FYI (or Julia is broken)"
                # calculate parent index in the initial part of the list
                let parentIndex = (length(res)+1) ÷ 2
                    # fetch the parent pool 
                    let parent = res[parentIndex]
                        # add the next pool at depth d
                        push!(res, Pool(d,next,parent))
                    end
                end
            end
        end
    end
    # begin debug
    for i in 2:length(res)
        local pool = res[i]
        @assert pool.depth == 1+pool.parent.depth "depth messed up"
        @assert 2*pool.nextTime == pool.parent.nextTime "solving time messed up"        
        @assert 2*pool.interval == pool.parent.interval "interval time messed up"
    end
    # end debug
    
    # done and return 
    return collect(res)
end


# We use the function to put new orders to the leaf nodes (dependeing on their nextTime)
# - leaves is the list of leaf nodes
# - intents is the list of all intents
# - routing maps locations to indices of leaf pools in the `leaves` list
# The `nextTime` and `interval` are assumed to be the same for all leaves
function putOrders(leaves, intents, routing::Dict{UInt8,UInt8})
    # checks
    for l in leaves
        @assert l.nextTime == leaves[1].nextTime "The `nextTime`s are messed up!"
        @assert l.interval == leaves[1].interval "The `interval`s are messed up!"        
    end
    
    # the deadline for solving
    local deadline = leaves[1].nextTime
    # the first time at which new intents are to be considered
    local first = deadline-(leaves[1].interval)
    @assert deadline > first "FYI (that cannot be)"
    # filter the relevant intents
    local relevant = [i for i in intents if i.time >= first && i.time < deadline]
    @assert length(relevant) == length(intents) "stupid bug ???"
    if length(relevant) > 0
        # println("Number of relevant intents for next tick is $(length(relevant)).")
    end
    for intent in relevant
        @assert intent.location in 1:locations "intent location messed up"
        @assert routing[intent.location] in 1:length(leaves) "routing messed up"
        let j = routing[intent.location]
            # put the intent in the pool to which it is routed
            pushfirst!(leaves[j].contents, intent)
            # NB: we push to the head of the list
        end
    end
end

# Solving is done by `solvePool`
# - pool is the pool for solving
function solvePool(pool::Pool)
    if !(pool.now >= pool.nextTime)
        return Dict()
    end
    local checksum = sum([intent.resource for intent in pool.contents])
    local oldLength = length(pool.contents)
    ## print("Solving a pool at depth ", pool.depth, "... ")
    # the indices of matched intents (to be deleted)
    local indices = MutableLinkedList{Int64}()
    # the dictionrary for the solution
    local solution = Dict()
    # initialize balances of resources (resource kind 0 does not hurt here)
    local balance = Dict(a => 0 for a in -maxVariability:maxVariability)
    # calculate the resource balances (this could be a field of the pool to save compute)
    for intent in pool.contents
        let r = intent.resource
            # print("inc ", r)
            balance[r] = balance[r]+1
        end
    end
    # do the actual solving for each intent
    for index in reverse(1:length(pool.contents))
        # now index is the index of an intent
        let r = (pool.contents[index]).resource
            # now r is the rsource at index
            # check if there is some (unspecified) intent that is matching
            if balance[-r] > 0
                # the intent i is matched!
                # adapt balance 
                balance[-r] = balance[-r]-1
                # Note: balance[r] will be adapte or has been already adapted by the counterpart
                
                # remember only the index
                pushfirst!(indices, index)
                # print("matched $r")
            end
        end        
    end
    
    # print("... solving ...")
    
    # begin debug 
    local balancecheck = Dict(a => 0 for a in 1:maxVariability)
    for index in indices     
        # check that indices are fine
        @assert index in 1:length(pool.contents) "wrong indices for wanna be solution"
        # the resource of the intent with index i
        local r = (pool.contents[index]).resource
        if r > 0
            # the intent was a surplus to be given away
            balancecheck[r] = balancecheck[r]+1
        end
        if r < 0
            # the intent was demand/need to be received
            balancecheck[-r] = balancecheck[-r]-1
        end
    end
    # check that the solution is actually a solution — better than a proof ;-)
    for a in 1:maxVariability
        @assert balancecheck[a] == 0 "no matching at all $indices"
    end
    # make sure the order of indices is ascending 
    for j in 2:length(indices)
        @assert indices[j] > indices[j-1]
    end
    # end debug
    
    ### 
    
    # next up: produce the solution and remove the matched intents
    
    #if length(indices) > 0
    #println("deleting so many indices in numbers ", length(indices))
    #end
    # starting with the biggest indices, loop over indices
    for i in reverse(1:length(indices))
        local index = indices[i]
        # put the intent to the solution
        let intent = pool.contents[index]
            @assert intent.time <= pool.nextTime "we cannot have negative solving time !!! "
            # remove it from the pool contents
            delete!(pool.contents, index)
            solution[intent] = (pool.now, pool.depth, pool)
        end
    end
    
    @assert checksum == sum([intent.resource for intent in pool.contents]) "error???"
    @assert oldLength == length(pool.contents) + length(indices)
    
    # update next time
    pool.nextTime = pool.nextTime + pool.interval
    
    ##println(" ... solved!")
    return solution
end

function printPercentages(solution)
    local ds::Vector{Int} = collect(Set([ (v[2]) for (_,v) in solution]))
    ds = sort(ds)
    local counts = Dict(p => length([ 1 for (k,v) in solution if v[2]==p]) for p in ds)
    for d in ds
        for _ in 1:div(counts[d]*80,length(solution))
            print("", convert(Int, d))
        end
    end
    println("")
end
    
    
function propagateContents(pool::Pool)
    # if it is time to do so, propagate the remaining contents (unless pool is the root)
    @assert pool.depth > 0
    @assert pool.now < pool.nextTime "unrealistic, because propagation is after solving and nextTime is updated"
    
    # if the parent pool will solve earlier (or the same time) than the current pool
    if pool.parent.nextTime <= pool.nextTime
        # propagate intents one by one (julia quirks ...)
        for index in reverse(1:length(pool.contents))
            local intent = pool.contents[index]
            delete!(pool.contents, index)
            @assert intent.resource in -maxVariability:maxVariability "wrong resource here! $pool"
            @assert intent.time <= pool.parent.nextTime "no time machine!"
            push!(pool.parent.contents, intent)
        end
        # check emptiness of the current pool
        @assert isempty(pool.contents) "not everything transferred !!!"
    else
        # nothing to do but wait
    end
end

# a whole solving round is done by `solving`
# - leafpools is where the new orders are going to be put
# - maxTime is the end of the experiment (typiclly 1)
# - intents is the set of intents from which we take new orders
# - pools is the list of all pools 
function solving(leafPools, maxTime, intents, pools)
    local tick = (last(leafPools).interval)
    # the solution to be returned as global solution
    local theSolution = Dict()
    # we start at time 0
    local globalTime = 0
    # a useful assumption (no point in having more than one pool per location)
    @assert locations >= length(leafPools) "too many pools or not enough locations"
    
    # calculate the routing of locations to leaf pools
    local rout::Dict{UInt8,UInt8} =
    Dict(loc => ceil(Int, loc *length(leafPools)/locations) for loc in 1:locations)
    
    # double check that this routing works         
    for i in 1:locations
        @assert rout[i] in 1:length(leafPools) "routing is incorrectly constructed"
    end
    
    # check the proper inputs for pools
    # leaves accounted for
    for l in leafPools
        @assert l in pools "spurious leaf or pools missing leaves"
    end
    # pools properly constructed
    for index in reverse(1:length(pools))
        let p = pools[index]
            @assert p.parent in pools
            @assert p.parent.depth < p.depth  || p.depth == 0 "depths relation wrong"
            if index > 1
                @assert p.depth >= pools[index-1].depth "deeper pools not to the right"
            else
                @assert p.depth == 0 "root pool wrong"
            end
        end
    end
    
    local runningIntents = 0
    local leftovers::Bool = true
    
    # println("the time is $theTime and maxTime is $maxTime")
    while (globalTime <= maxTime || leftovers)
        
        #println("time now is $theTime")
        # update time (lest we forget) -- it is just for the loop
        local oldTime = globalTime
        globalTime = globalTime + tick
        # update time
        for p in pools  
            p.now = globalTime
        end
        
        # in the current "tick", we first put new orders to the leaves
        local relevant = [i for i in intents if i.time >= oldTime && i.time < globalTime]
        putOrders(leafPools, relevant, rout)
        runningIntents += length(relevant)
        
        @assert runningIntents == length(theSolution) + sum([length(p.contents) for p in pools]) "oh noooo what?"
        
        # starting from deepest/rightmost pools (i.e., leaves) going "left/up"
        for i in 1:length(pools)
            local p = pools[i]
            let solution = solvePool(p)
                # println("lenght of solution is ", length(solution))
                for k in keys(solution)
                    @assert !(k in keys(theSolution)) "key present $k !"
                end
                merge!(theSolution, solution)
            end
        end
        @assert runningIntents == length(theSolution) + sum([length(p.contents) for p in pools]) "oh noooo, this is bad!"
        
        
        # after all solving is done for this time "now", we propagate 
        for i in 2:length(pools)
            propagateContents(pools[i])
        end

        # update secondary condition for loop termination
        leftovers = 0 < sum([length(p.contents) for p in pools if p!=pools[1]])
        
        @assert runningIntents == length(theSolution) + sum([length(p.contents) for p in pools]) "oh noooo, also bad!"
        # println("time after solving is $theTime")
    end
    
    # final solve of top level pool
    pools[1].now = pools[1].nextTime
    let solution = solvePool(pools[1])
        # println("lenght of solution is ", length(solution))
        for k in keys(solution)
            @assert !(k in keys(theSolution)) "key present $k !"
        end
        merge!(theSolution, solution)
    end
    
    println("We have solved ", length(theSolution), " intents.")
    return theSolution
end


using Plots

# the number of rounds of solving to happen at top level
const rounds = 20

# main loop
begin
    local someSolutions = MutableLinkedList()
    local someLeftovers = MutableLinkedList()
    local expectedWaitingTime::Float16 = 0.0001
    local theIntents::Vector{Intent} = 
    generateIntents(convert(Int8, maxVariability), expectedWaitingTime)
    
    # this should be quick, so no more than 1000 samples
    local theLength = min(1000,length(theIntents)-2);
    # the precision determines the bucket size, depending on the waiting times
    local precision = 10+convert(Int64,round(digits=10,log(10,1/expectedWaitingTime)));
    local diffs
    let s = theIntents[1:theLength-1], e = theIntents[2:theLength]
        diffs = [y.time-x.time for (x,y) in zip(s,e)]
        diffs = map(x -> round(digits=precision, x), diffs);
        display(Plots.bar(reverse(sort(diffs)), size = (800,400);
        label="occurrence numbers for waiting times for the next intent"))
    end
    for depth in 0:maxDepth
        local pools = generatePools(convert(UInt8, depth), Float64(.999/(rounds*2^depth)))
        println("we have generated ", length(pools), " pools.")
        #=     for pool in 1:length(pools)
            println("pool ", pool, " is ", pools[pool])
        end =#
        local leafPools = filter(p -> p.depth == pools[length(pools)].depth, pools)
        push!(someSolutions, solving(leafPools,  last(theIntents).time, theIntents, pools))
        push!(someLeftovers, sum([length(p.contents) for p in pools]))
    end
    # println("calculated $(length(someSolutions)) solutions.")
    for i in 1:length(someSolutions)
        @assert length(someSolutions[i]) == length(someSolutions[1]) "oh nooooo!"
        # println("Solution $i) has length: ", length(someSolutions[i]), " with left overs ", someLeftovers[i], ".")
    end

    let tenth = div(length(someSolutions[1]),10)
        for s in someSolutions
            delete!(s,length(s)-tenth:length(s))
            
            delete!(s,1:tenth)
            local stuckTimes = [s[k][1]-k.time for k in keys(s)]
            local valueLost = sum([MathConstants.e^(t) for t in stuckTimes])
            println("Value lost due to waiting: $valueLost.")
            println("Rough picture of percentages per depth:")
            printPercentages(s)
            println("")
        end
    end
    
    begin
        solvingTime = [
        [round(digits=5, someSolutions[k][i][1]-i.time) for i in theIntents if 
        haskey(someSolutions[k],i)] for k in 1:length(someSolutions)
        ]
        #= display(Plots.bar([reverse(sort(solvingTime[j])) 
        for j in 1:length(someSolutions)], 
        ylabel = "Width", size = (800,400*4);
        layout = (length(someSolutions), 1))) =#
    end
end

# println("press key to exit")

# _ = readline()