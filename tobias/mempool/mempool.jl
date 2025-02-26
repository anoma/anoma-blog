
# the maximal depth of mempool hierarchies
maxDepth=5
println("Set maximal depth of hierarchies 'maxDepth' is ", maxDepth, ".")

# the number of locations at which new intents are collected
locations = 2^maxDepth
println("The number of locations 'locations' is ", locations, ".")

# the number of rounds of solving batch auctions at the global pool
rounds = 5
println("The number of rounds of solving 'rounds' is ", rounds, ".")


# the number of different kinds of resources
maxVariability = 8
println("The maximum variability of intents 'maxVariability' is ", maxVariability)

using DataStructures
# an empty list of the required type: time, resource +/-, location
theMutableIntentsList = MutableLinkedList{Tuple{Float64, Int64, Int64}}()

expectedWaitingTime = 1 / (rounds * locations * maxVariability * 4)
print("expectedWaitingTime ", expectedWaitingTime)

using Distributions
intentsWaitingTimes = Distributions.Exponential{Float64}(expectedWaitingTime)

using Random

theIntents = collect(theMutableIntentsList)

using Plots
begin
	# this should be quick, so no more than 1000 samples
	local theLength = min(1000,length(theIntents)-2);
	# the precision determines the bucket size, depending on the waiting times
	local precision = 2+convert(Int64,round(digits=0,log(10,1/expectedWaitingTime)));
	let s = theIntents[1:theLength-1],
		e = theIntents[2:theLength]
	in
		local diffs = [y[1]-x[1] for (x,y) in zip(s,e)]
		diffs = map(x -> round(digits=precision,x), diffs);
		Plots.bar(reverse(sort(diffs)), size = (800,400);
			label="occurrence numbers for waiting times for the next intent")
	end;
end


# a function to map depth in a complete binary tree to the indices

function poolRange(depth::Int)
	@assert depth > -1 
		"No such thing as negative depth!"
	return 2^depth:2^(depth+1)-1
	# for depth 0, this is 1:(2-1) = 1:1
    @assert 2^0 == 2^(0+1)-1 "calculation error"
end


function parentOf(pool::Int)
	@assert pool > 1 "This pool has no pool number!"
	div(pool, 2)
end

println("pool ranges and parents")
for i in 0:5

    println(poolRange(i))
    println("i.e., ")
    pr = poolRange(i)
    for j in pr
        print(j)
        if j != maximum(pr)
            print(", ")
        end
    end
    println(" with parents:")

    if i > 0 
        for j in pr
            print(parentOf(j))
            if j != maximum(pr)
                print(", ")
            end
        end
    end
    println(".")
end

function leafOfLocation(depth::Int, location::Int)
    local pr = poolRange(depth)
    local min = minimum(pr)
    local max = maximum(pr)
    local len = max-min+1
    @assert (len == length(pr))
    @assert locations >= len "not enough locations"
    local pos = (ceil(Int, location * len / locations))
    @assert pos <= len
    pr[pos]
end

function solve(intents, depth::Int, slowdown::Float64; variability=maxVariability)
	# ---
	# check proper inputs
	# ---
	# the slowdown must be at least 1.0
	@assert slowdown >= 1.0
		"Slowdown must be a factor greater than or equal to one!"
	# the depth must be non-negative
	@assert depth >= 0
		"The depth must be non-negative."
    # ---
	# define relevant constants
    # ---
	
	# the number of all pools
    local poolCount = (2^(depth+1))-1
    @assert (1 == (2^(0+1))-1) "At depth zero, we have one pool, numbered 1"
	# define the range/list of indices of the leaf pools
    local leafPools = poolRange(depth); #poolRange is a function
    print("leaf pool indices")
    for i in leafPools
        print("i", i )
    end
	# the possible intents
    @assert (variability >= 1) "we must at least have one resource"
	local allIs = union(-variability:-1, 1:variability);
	# ---
	# define and initialize variables
    # ---
	# the balances (initially all zero)
	local balance = [Dict(a => 0 for a in allIs)
						for x = 1:poolCount
					]
	# the pool contents (initially empty)
	local contents = [MutableLinkedList() for x=1:poolCount]
	# the solution (initially empty)
	local solution = Dict()
	
    #----
	#### the main loop 
    #----

	# index into the intent list (mathematical index, starting at one)
	local idx = 1

    # duration of a *leaf* batch (note: the whole experiment takes 'slowdown' time units)
	local duration = slowdown/(rounds * 2^depth) #rounds is global

    local tickNumber = floor(Int, 1/duration)
	# for each *tick* (*defined* as the sequence number of leaf level batch)
	for tick in 1:tickNumber
        print("alive", tick)
		local endOfTick = tick * duration;
		# before the end of this tick we do the following…
		# …put in new intents at the leaf pools (yes, that happens for every tick)
		# for all next intents with arival before the end of the tick
        local nextIntent = intents[idx];
		while nextIntent[1] < endOfTick # time is the first component
			# insert intent and update the balance
			let (_, r, location) = nextIntent
				# put the intent into the pool .. 
                leafIndex = leafOfLocation(depth, location)

				pushfirst!(contents[leafIndex], nextIntent)
				# ... an update the balance accordingly: increse r-surplus
				balance[leafIndex][r] += 1
			end # added intent with index `idx` to the respective leaf pool
			# look at the next intent (or break)
			if idx < length(intents)
				idx += 1;
			else
                println("Last intent processed before ", endOfTick, ".")
				break
			end
		end # done putting new intents before the end of the tick
		
		# ---
		# do the actual solving
		# ---
	
		# go ᴛᴏᴘ ᴅᴏᴡɴ (breadth first, to be precise) through all pools
		# for each depth d
		for d in 0:depth
			# should we do solving (after taking in new leaf intents)?
			if mod(tick, 2^(depth-d)) == 0
				@assert mod(tick, 1) == 0
					"Just in case."
				# for every pool at depth d
				for pool in poolRange(d)
					# for every index j of the contents of the pool 
					for j in reverse(1:length(contents[pool]))
						# fetch the intent
						local intent = contents[pool][j]
						# match time t and resource r
						local (t, r, _) = intent
						# chack if the intent can be matched (note the `-r`!)
						if balance[pool][-r] > 0
							# if matchable, add the intent to the solution and … 
							solution[intent] = endOfTick
						    # … adapt the balance (to avoid over-matching) and …
						    balance[pool][-r] += -1
                            # (note that the counterpart intent will be also matched)
							# … remove the intent from the pool (at index j)
							delete!(contents[pool], j)
						else # if not matchable 
							# check if we are at the root / top-level
							if d == 0
								# at the root, there is nothing to do (but wait)
							else # at a "properly" inner pool or a leaf
								@assert d > 0 "just in case"
								# compute "next tick is parent's solving time?"
								local timeToForward =
									# TODO think about the height to stop
									# next tick is ~tick+1~ tick+2^(depth-d)
									# parent pool is at depth d-1
									mod(tick+2^(depth-d), 2^(depth-(d-1))) == 0;
                                    # if at leaf, d=depth
                                    #  - tick+2^(depth-d) = tick+1
                                    #  - 2^(depth-(d-1)) = 2
                                    # thus in the odd ticks, we forward, so that 
                                    # in the next tick the upper pool starts solving
								# now, in case we need to forward
								if timeToForward
									# forward intent to the parent, i.e.,
									# delete intent from pool's contents
									delete!(contents[pool], j)
									# adapt the pool's balance (remove r)
									balance[pool][r] += -1
									# compute the parent's pool index
									local parent = parentOf(pool)
									# add the intent to the parent's pool contents
									pushfirst!(contents[parent], intent)
									# adapt the balances of the parent (add r)
									balance[parent][r] += 1
								end #finished forwarding
							end # treat intent if not matchable
						end # do match if poosible
					end # loop through intents of the pool (for solving/matching/…)
				end # loop through pools at height d
			end # do solving at depth d (if it is the time to do so)
		end # cycle through depths
	end # cycle through ticks
	let remaining = length(intents) - idx, last = intents[idx], matched = length(solution)
		println("Number of remaining intents $remaining at depth $depth")
		println("last intent was $last");
		println("number of intents satisfied $matched")
		println("number of intents processed $idx")
	end
	return solution
end

# someSolutions =  [solve(theIntents, d, 1.0) for d in 0:maxDepth]

########################

# now systematically: 

########################


# an intent is issued at a specific point in time, 
struct Intent 
    time :: Float64
    resource :: Int
    location :: UInt
end

# return a list of indices of matched intents for a current pool contents
function slowSolve(contents)
    local res = MutableLinkedList{Tuple{Int64}}()
    local balance = Dict(a => 0 for a in -maxVariability:maxVariability)
    for intent in contents
        local (_, r, _) = intent
        balance[r] = balance[r]+1
    end
    for i in 1:length(contents)
        local (_,r,_) = contents[i]
        if balance[-r] > 0
            balance[-r] = balance[-r]-1
            push!(res, i)
        end
    end

    # begin debug 
    local balancecheck = Dict(a => 0 for a in 1:maxVariability)
    for i in res     
        local (_, r, _) = contents[i]
        if r > 0
            balancecheck[r] = balancecheck[r]+1
        end
        if r < 0
            balancecheck[r] = balancecheck[r]-1
        end
    end
    for a in 1:maxVariability
        @assert balancecheck[a] == 0 "no matching at all"
    end
    # end debug 
end


# `generateIntents`: a function to generate intents
# parameters are
# - `maxVariability`: the number of different resources
# - `meanIntentWaitingTime`: the mean waiting time between intents
function generateIntents(maxVariability::UInt8, meanIntentWaitingTime::Float16)::Vector{Intent}
    # generate the list of resource offers/requests to sample from
    local orderTypes = union(-maxVariability:-1, 1:maxVariability)

    # We use exponentially distributed waiting times for intents
    local dist = Exponential(meanIntentWaitingTime)

    # a fresh empty list of intents
    local theMutableIntentsList = MutableLinkedList{Intent}()

    # initialize the local sum of waiting times for new intents
    # (i.e., the time that passes until the first intent will arrive)
    local localsum = 0;
    # as long as we do not reach the end of the experiment (at time unit 1)
    while (localsum < 1)
        # randomly generate supply or demand for a random resource
        local nextV = Random.rand(orderTypes)
        local nextLoc = Random.rand(1:locations)
        # generate next intent ... 
        let newIntent = Intent(localsum, nextV, UInt(nextLoc))
        # ... and push it to the list (at the end)
            push!(theMutableIntentsList, newIntent)
        end
        # update sum of the waiting times 
        localsum += Random.rand(dist);
        # ☝️ this is the arrival time of the *next* intent (or something ≥ 1)
    end
    # some "debug" printing
    local theLength = length(theMutableIntentsList)
    local thePeek = (getindex(theMutableIntentsList, div(theLength, 2)-1),
                        getindex(theMutableIntentsList, div(theLength, 2)),
                        getindex(theMutableIntentsList, div(theLength, 2)+1))
    println("intents created: $theLength \n‌and the first, median three, and last:\n");
    println("Intent #1 is $(theMutableIntentsList[1])")
    for i in eachindex(thePeek)
        let index = i + (div(theLength, 2)-2)
            println("Intent #$index is $(thePeek[i])")
        end
    end
    println("Intent #theLength is $(theMutableIntentsList[theLength])")
    return collect(theMutableIntentsList)
end
    
# this is a global variable: that's OK, because it is one experiment at a time
intentsForMatching = generateIntents(convert(UInt8,16), convert(Float16,0.1))
println("We have generated ", length(intentsForMatching), " intents.")

# each pool 
mutable struct Pool
    contents::MutableLinkedList{Intent}
    depth::UInt8
    nextTime::Float64
    interval::Float64
    parent::Pool
    Pool(c::MutableLinkedList{Intent}, d::UInt8, t::Float64, p::Pool) =
         new(c,d,t,t,p)
    Pool(c::MutableLinkedList{Intent}, d::UInt8, t::Float64) =
         (x = new(c,d,t,t); x.parent = x)
end

# generate a hiearchy of pools
# - depth is the depth of the binary tree
# - tick is the solving time of leaf pool
function generatePools(depth::UInt8,tick::Float64)::Vector{Pool}
    local res = MutableLinkedList{Pool}()
    for d in 0:depth
        local next::Float64 = tick*2^(depth-d)
        for _ in 1:(2^d)
            let c = MutableLinkedList{Intent}()
                if d == 0
                    push!(res,Pool(c, convert(UInt8, d), next))
                else
                    @assert d > 0 
                    let parentIndex = (length(res)+1) ÷ 2
                        push!(res,Pool(c,convert(UInt8, d),next,res[parentIndex]))
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
    collect(res)
end

pools = generatePools(0x04,Float64(1.0))
println("we have generated ", length(pools), " pools.")
for pool in 1:length(pools)
    println("pool ", pool, " is ", pools[pool])
end

leafPools = pools |> filter(p -> p.depth == pools[length(pools)].depth)

print("we have ", length(leafPools), "leaf pools")

# put order to leaves
function putOrders(leaves, intents, routing)
    local deadline = leaves[1].nextTime
    local first = deadline-leaves[1].interval
    local relevant = intents |> filter(i::Intent -> i.time >= first && i.time < deadline)
    for i in relevant
        let j = routing(i.location)
            pushfirst!(leaves[j],i)
        end
    end
end

# return a list of indices of matched intents for a current pool contents
function solvePool(pool::Pool)
    # the contents of solving
    local contents::Vector{Intent} = collect(pool.contents)
    # the indices of matched intents (to be deleted)
    local indices = MutableLinkedList{Tuple{Int64}}()
    # the new solutions
    local solution = Dict()
    local balance = Dict(a => 0 for a in -maxVariability:maxVariability)
    for intent in contents
        local r = intent.resource
        balance[r] = balance[r]+1
    end
    for i in 1:length(contents)
        local r = (contents[i]).resource
        if balance[-r] > 0
            balance[-r] = balance[-r]-1
            push!(indices, i)
        end
    end

    # begin debug 
    local balancecheck = Dict(a => 0 for a in 1:variability)
    for i in indices     
        local r = (contents[i]).resource
        if r > 0
            balancecheck[r] = balancecheck[r]+1
        end
        if r < 0
            balancecheck[r] = balancecheck[r]-1
        end
    end
    for a in 1:variability
        @assert balancecheck[a] == 0 "no matching at all"
    end
    for j in 2:length(indices)
        @assert indices[j-1] < indices
    end
    # end debug

    # extend solution and remove the matched intents
    
    for i in reverse(indices)
        let intent = pool.contents[i]
            solution[intent] = (pool.nextTime, pool.depth)
        end
        delete!(pool.contents, i)
    end

    # update next time
    pool.nextTime = pool.nextTime + pool.interval

    # check if we need to propagate the remaining contents
    if pool.depth > 0 
        if pool.parent.nextTime <= pool.nextTime
            append!(pool.contents, pool.parent.contents)
            pool.parent.contents = pool.contents
            pool.contents = MutableLinkedList{Intent}()
        else
            # nothing to do but wait
        end
    end
    return solution
end

# now the main loop

begin
    local theSolution = Dict()
    local theTime = 0
    local maxTime = last(intentsForMatching).time
    local rout = Dict(loc => loc for loc in 1:locations)
    print("the time $theTime")
    while (theTime <= maxTime)
        theTime = theTime + (last(leafPools).nextTime)
        putOrders(leafPools, theIntents, rout)
        for p in reverse(pools)
            let solution = solvePool(p)
                merge!(theSolution, solution)
            end
        end
    end
end