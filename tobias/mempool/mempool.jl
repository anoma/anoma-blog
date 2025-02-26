# the maximal depth of mempool hierarchies
maxDepth=5
println("Set maximal depth of hierarchies 'maxDepth' is ", maxDepth, ".")

# the number of locations at which new intents are collected
locations = 2^maxDepth
println("The number of locations 'locations' is ", locations, ".")

# the number of different kinds of resources
maxVariability = 2
println("The maximum variability of intents 'maxVariability' is ", maxVariability)

using DataStructures
using Distributions
using Random
using Plots

# An intent is issued at
# - a specific point in *time*
# - conerns only a single *resource*, and
# - occurrs at a specific *location*.
struct Intent 
    time :: Float64
    resource :: Int
    location :: UInt
end

# `generateIntents`: a function to generate intents
# The parameters are
# - the number of different resources `var`
# - the mean waiting time between intents `meanIntentWitingTime`
function generateIntents(var::Int8, meanIntentWaitingTime::Float16)::Vector{Intent}

    # We use exponentially distributed waiting times for intents
    local dist = Exponential(meanIntentWaitingTime)

    # a fresh empty list of intents
    local theList = MutableLinkedList{Intent}()

    # initialize the local sum of waiting times for new intents
    # (i.e., the time that passes until the first intent will arrive)
    local localsum = 0;
    # as long as we do not reach the end of the experiment (at time unit 1)
    while (localsum < 1)
        
        # randomly generate supply or demand for a random resource
        @assert var <= maxVariability "variability not good"
        local nextV::Int = Random.rand([x for x in -var:var if x!=0])
        local nextLoc::UInt8 = Random.rand(1:locations)
        @assert nextLoc in 1:locations
        # generate next intent ... 
        let newIntent = Intent(localsum, nextV, nextLoc)
        # ... and push it to the list (at the end)
            push!(theList, newIntent)
        end
        # update sum of the waiting times 
        localsum += Random.rand(dist);
        # ☝️ this is the arrival time of the *next* intent (or something ≥ 1)
    end
    # some "debug" printing
    local theLength = length(theList)
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
    println("Intent #theLength is $(theList[theLength])")
    for i in theList
        @assert i.location in 1:locations
    end
    return collect(theList)
end
    

# each pool 
mutable struct Pool
    contents::MutableLinkedList{Intent}
    depth::UInt8
    nextTime::Float64
    interval::Float64
    parent::Pool
    Pool(d::UInt8, t::Float64, p::Pool) =
         new(MutableLinkedList{Intent}(),d,t,t,p)
    Pool(d::UInt8, t::Float64) =
         (x = new(MutableLinkedList{Intent}(),d,t,t); x.parent = x)
end

# generate a hiearchy of pools
# - depth is the depth of the binary tree
# - tick is the solving time of leaf pool
function generatePools(depth::UInt8,tick::Float64)::Vector{Pool}
    local res = MutableLinkedList{Pool}()
    for d::UInt8 in 0:depth
        local next::Float64 = tick*2^(depth-d)
        for _ in 1:(2^d)
            if d == 0
                push!(res,Pool(d, next))
            else
                @assert d > 0 
                let parentIndex = (length(res)+1) ÷ 2
                    push!(res, Pool(d,next,res[parentIndex]))
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
    collect(res)
end

rounds = 100
#pools = generatePools(convert(UInt8, maxDepth), Float64(1.0/rounds))
#println("we have generated ", length(pools), " pools.")
#for pool in 1:length(pools)
#    println("pool ", pool, " is ", pools[pool])
#end

#leafPools = filter(p -> p.depth == pools[length(pools)].depth, pools)

#print("we have ", length(leafPools), "leaf pools")

# put order to leaves
function putOrders(leaves, intents, routing::Dict{UInt8,UInt8})
    local deadline = leaves[1].nextTime
    local first = deadline-(leaves[1].interval)
    @assert deadline > first
    local relevant = filter(i::Intent -> i.time >= first && i.time < deadline, intents)
    println("number of relevant intents is ", length(relevant))
    for i in relevant
        # println("location is ", i.location)
        @assert i.location in 1:locations 
        let j = routing[(i.location)]
            pushfirst!(leaves[j].contents, i)
        end
    end
end

# return a list of indices of matched intents for a current pool contents
function solvePool(pool::Pool)
    print("solving a pool at depth", pool.depth)
    # begin debug
    # end debug
    # the contents of solving
    local theLength = length(pool.contents)
    # print("the length of pool.contents ", theLength)
    local theContents = MutableLinkedList{Intent}()
    # there are weir errors with collect / copy of mutable linked list, it seems
    for i in 1:length(pool.contents)
        local resource = pool.contents[i].resource
        @assert resource in -maxVariability:maxVariability "wrong intent $resource"
        push!(theContents, pool.contents[i])
    end
    print(".. copied ..")
    @assert theLength == length(theContents) "copy broken"
    # the indices of matched intents (to be deleted)
    local indices = MutableLinkedList{Int64}()
    # the new solutions
    local solution = Dict()
    local balance = Dict(a => 0 for a in -maxVariability:maxVariability)
    # calculate the resource balances (this could be a field of the pool)
    for intent in theContents
        let r = intent.resource
            print("inc ", r)
            balance[r] = balance[r]+1
        end
    end
    for i in 1:length(theContents)
        let r = (theContents[i]).resource
            if balance[-r] > 0
                balance[-r] = balance[-r]-1
                # the matcing intend will take care of the other decrementt
                push!(indices, i)
                print("matched $r")
            end
        end        
    end

    print("... solving ...")

    # begin debug 
    local balancecheck = Dict(a => 0 for a in 1:maxVariability)
    for i in indices     
        @assert i in 1:length(theContents) "wrong indices for wanna be solution"
        local r = (theContents[i]).resource
        if r > 0
            balancecheck[r] = balancecheck[r]+1
        end
        if r < 0
            balancecheck[-r] = balancecheck[-r]-1
        end
    end
    for a in 1:maxVariability
        @assert balancecheck[a] == 0 "no matching at all $indices"
    end
    for j in 2:length(indices)
        @assert indices[j-1] < indices[j]
    end
    # end debug

    # extend solution and remove the matched intents

    if length(indices) > 0
        println("deleting so many indices  in numbers ", length(indices))
    end
    for i in reverse(indices)
        let intent = pool.contents[i]
            solution[intent] = (pool.nextTime, pool.depth)
        end
        # print("Delete alert ", length(pool.contents), " ", i)
        delete!(pool.contents, i)
    end

    # update next time
    pool.nextTime = pool.nextTime + pool.interval

    # check if we need to propagate the remaining contents
    if pool.depth > 0 
        if pool.parent.nextTime <= pool.nextTime
            for i in pool.contents
                @assert i.resource in -maxVariability:maxVariability "wrong resource here! $pool"
                pushfirst!(pool.parent.contents, i)
            end
            pool.contents = MutableLinkedList{Intent}()
        else
            # nothing to do but wait
        end
    end
    println("solved a pool at depth", pool.depth)
    return solution
end

# a whole solving process

function solving(leafPools, maxTime, intents, pools)
    local theSolution = Dict()
    local theTime = 0
    @assert locations >= length(leafPools) "too many pools"

    local rout::Dict{UInt8,UInt8} =
         Dict(loc => ceil(Int, loc *length(leafPools)/locations) for loc in 1:locations)
    println("the time is $theTime and maxTime is $maxTime")
    while (theTime <= maxTime)
        println("time now is $theTime")
        theTime = theTime + (last(leafPools).interval)
        putOrders(leafPools, intents, rout)
        for p in reverse(pools)
            let solution = solvePool(p)
                # println("lenght of solution is ", length(solution))
                merge!(theSolution, solution)
            end
        end
        println("time after solving is $theTime")
    end
    println("We have solved ", length(theSolution), " intents.")
    return theSolution
end



# main loop
begin
    local intentsForMatching::Vector{Intent} = 
        generateIntents(convert(Int8, maxVariability), convert(Float16, 0.01))
    for depth in 0:maxDepth
        local pools = generatePools(convert(UInt8, depth), Float64(1.0/rounds))
        println("we have generated ", length(pools), " pools.")
        #=     for pool in 1:length(pools)
                println("pool ", pool, " is ", pools[pool])
            end =#
        local leafPools = filter(p -> p.depth == pools[length(pools)].depth, pools)
        solving(leafPools,  last(intentsForMatching).time, intentsForMatching, pools)
    end
end

