println("Hello!")


maxDepth=5
println("Set maximal depth of hierarchies 'maxDepth' is ", maxDepth, ".")

locations = 2^maxDepth
println("The number of locations 'locations' is ", locations, ".")

rounds = 5

println("The number of rounds of solving 'rounds' is ", rounds, ".")

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

begin
# ---
	# preparations
	# ---
	# reset the intents list (just in case)
	if !isempty(theMutableIntentsList)
		let theLenght = length(theMutableIntentsList)
		in 
			println("Note that we already had a list of length $theLenght‌!");
			print("new ")
		end
		while !isempty(theMutableIntentsList)
			pop!(theMutableIntentsList)
		end
	end
	# which ressources are we considering?
	local candidateArray = union(-maxVariability:-1, 1:maxVariability)
	# initialize local sum of waiting times for new intents, i.e., the time we have to wait for the first intent to arrive
	local localsum = Random.rand(intentsWaitingTimes);
	# as long as we do not reach the end of the experiment (at time unit 1)
	while (localsum < 1)
		# randomly generate supply or demand for a random resource
		nextV = Random.rand(candidateArray)
		# generate next intent ... 
		let newIntent = (localsum, nextV, Random.rand(1:locations))
			# ... and push it to the list (at the end)
			push!(theMutableIntentsList, newIntent)
		end
		# update sum of the waiting times 
		localsum += Random.rand(intentsWaitingTimes);
		# ☝️ this is the arrival time of the *next* intent (if not too late)
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
		in 
		println("Intent #$index is $(thePeek[i])")
		end
	end
	println("Intent #theLength is $(theMutableIntentsList[theLength])")

end

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

# return a list of indices of matched intents for a current pool contents
function slowSolve(contents)
    local res = MutableLinkedList{Tuple{Int64}}()
    local balance = Dict(a => 0 for a in -variabiity:variability)
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
    local balancecheck = Dict(a => 0 for a in 1:variability)
    for i in res     
        local (_, r, _) = contents[i]
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
    # end debug 
end

struct Intent 
    time :: Float64
    resource :: Int
    location :: UInt
    Intent(t,r,l)
end

function generateIntents(maxVariability::UInt, intentsWaitingTimes::Float64)
    local theMutableIntentsList = MutableLinkedList{Intent}()
    # which ressources are we considering?
    local candidateArray = union(-maxVariability:-1, 1:maxVariability)
    # initialize local sum of waiting times for new intents, i.e., the time we have to wait for the first intent to arrive
    local localsum = Random.rand(intentsWaitingTimes);
    # as long as we do not reach the end of the experiment (at time unit 1)
    while (localsum < 1)
    # randomly generate supply or demand for a random resource
    local nextV = Random.rand(candidateArray)
    # generate next intent ... 
        let newIntent = (localsum, nextV, Random.rand(1:locations))
            # ... and push it to the list (at the end)
            push!(theMutableIntentsList, newIntent)
        end
            # update sum of the waiting times 
            localsum += Random.rand(intentsWaitingTimes);
            # ☝️ this is the arrival time of the *next* intent (if not too late)
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
            in 
            println("Intent #$index is $(thePeek[i])")
            end
        end
        println("Intent #theLength is $(theMutableIntentsList[theLength])")
    
    end
    

mutable struct Pool
    contents::MutableLinkedList{Intent}
    parent::Pool
    leaf::Bool
    nextTime::Float64
    Pool(c) = (x = new(); x.parent = x; x.contents = c; x.leaf=false)
    Pool(c,p,l) = (x = new(); x.parent = p; x.contents = c; x.leaf=l)
end

# return a list of indices of matched intents for a current pool contents
function solvePool(pool::Pool)
    local contents::LinkedList{Intent} = collect(pool.contents)
    local res = MutableLinkedList{Tuple{Int64}}()
    local balance = Dict(a => 0 for a in -variabiity:variability)
    for intent in contents
        local r = intent.resource
        balance[r] = balance[r]+1
    end
    for i in 1:length(contents)
        local r = (contents[i]).resource
        if balance[-r] > 0
            balance[-r] = balance[-r]-1
            push!(res, i)
        end
    end

    # begin debug 
    local balancecheck = Dict(a => 0 for a in 1:variability)
    for i in res     
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
    # end debug 
end