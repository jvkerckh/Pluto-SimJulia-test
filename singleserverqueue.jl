### A Pluto.jl notebook ###
# v0.11.2

using Markdown
using InteractiveUtils

# ╔═╡ bdfde0c0-d4e6-11ea-019d-6b1ee1941043
md"# Simple single server queue"

# ╔═╡ 8e8aea70-d4b1-11ea-36b9-a97a7a011344
md"## Configuration"

# ╔═╡ 90590d00-d4ac-11ea-270d-c75e1c45c1c7
md"### Parameters"

# ╔═╡ 32d3c120-d55b-11ea-0850-634f10402ef3
md"""`meanArrivalTime` is the average time between two customers arriving. This time follows an exponential distribution.

`meanServiceTime` is the average time it takes for a server to serve a customer. This time follows an exponential distribution.

`nCustomers` is the number of customers that need to be served before the simulation terminates."""

# ╔═╡ c5f383d0-d4ae-11ea-3b87-0946a351744d
md"##### Simulation seeds"

# ╔═╡ 6872b6b0-d55b-11ea-22aa-b93a09eb84c2
md"""`arrivalSeed` is the seed of the arrival time random stream.

`serviceSeed` is the seed of the service time random stream."""

# ╔═╡ 8175cb00-d4ae-11ea-2fb1-91a11a30ce61
md"## Simulation"

# ╔═╡ 61a76b70-d4e6-11ea-2ee0-b3a8f81197cc
md"If the seeds are < 0, re-evaluating the line above will result in new, and different, results."

# ╔═╡ ae740382-d4b1-11ea-34a5-73b18d144608
md"## Results"

# ╔═╡ 4dbdf6e0-d4ac-11ea-145e-bda00be7cf74
md"## Function definitions"

# ╔═╡ 86959420-d4aa-11ea-0a50-dfa2d4327986
md"##### Needed packages"

# ╔═╡ 23acb610-d4b2-11ea-2a91-350c61fb70ee
md"##### Simulation functions"

# ╔═╡ 09a250b0-d4ab-11ea-2fc0-23964b7c6857
md"""This is the structure `SingleServiceQueue` that holds all the relevant information for the simulation of a single service queue.

It also defines a shorthand `SSQ` and an initialisation function. These need to appear in a single cell because of a circular reference."""

# ╔═╡ e932c990-d4aa-11ea-18ca-71c6971a0951
md"This function runs the simulation."

# ╔═╡ 9d3ef860-d4aa-11ea-3cbf-61ed5de1b652
md"This process generates a customers with random inter-arrival times."

# ╔═╡ 3cb62400-d4aa-11ea-2e8e-57b60f915350
md"This process creates a single customer, enters them into the service queue, and serves them once the server is available and no one's in the queue in front of them."

# ╔═╡ ad564200-d4b2-11ea-0e10-a547e82bb55f
md"##### Data extraction functions"

# ╔═╡ 96d17bc0-d4bd-11ea-0005-67c9a0bc9035
begin
	using Pkg
	Pkg.activate(".")
end

# ╔═╡ c68caa00-d4c3-11ea-294a-5f789dc8f632
begin
	using Plots
	plotly()
end

# ╔═╡ 8d98ed80-d4aa-11ea-060f-95bbe948bd1a
using DataFrames,
	  Distributions,
	  Random,
	  SimJulia

# ╔═╡ 8f167ae0-d4ac-11ea-305b-1d031cad24c3
meanArrivalTime = 1.0;

# ╔═╡ 8ee04fb0-d4ac-11ea-37aa-e1763fa755a6
meanServiceTime = 0.8;

# ╔═╡ 8eb40f90-d4ac-11ea-26e1-1d5cb739a2a1
nCustomers = 25;

# ╔═╡ c1aab690-d4ae-11ea-1358-69afe35fd094
arrivalSeed = -1;

# ╔═╡ c12050e0-d4ae-11ea-3f45-63bc77f9b8e2
serviceSeed = -1;

# ╔═╡ 1837fd00-d4ab-11ea-34d5-674ae7beffe0
begin
	mutable struct SingleServiceQueue
	    # Simulation parameters.
	    meanArrivalTime::Float64
	    meanServiceTime::Float64
	    nCustomers::Int
	
	    # Distributions & RNGs.
	    arrivalDist::Exponential
	    serviceDist::Exponential
	    arrivalRNG::MersenneTwister
	    serviceRNG::MersenneTwister
	
	    # Simulation results.
	    results::DataFrame
	    nCustomersServed::Int
	
	    # Simulation objects.
	    sim::Simulation
	    server::Resource
	
	    function SingleServiceQueue( ; mat::Real=1.0, mst::Real=0.8,
	        nc::Integer=1000 )::SSQ
	        newSSQ = new()
	
	        newSSQ.meanArrivalTime = mat > 0.0 ? mat : 1.0
	        newSSQ.meanServiceTime = mst > 0.0 ? mst : 1.0
	        newSSQ.nCustomers = nc > 0 ? nc : 1000
	
	        newSSQ.arrivalDist = Exponential( newSSQ.meanArrivalTime )
	        newSSQ.serviceDist = Exponential( newSSQ.meanServiceTime )
	
	        newSSQ.results = DataFrame()
	
	        initialize( newSSQ, -1, -1 )
	        return newSSQ
	    end  # SSQ( mat, mst, nc )
	end  # mutable struct SingleServiceQueue
	
	const SSQ = SingleServiceQueue
	
	function initialize( ssq::SSQ, aseed::Int, sseed::Int )
		ssq.arrivalRNG = MersenneTwister( aseed < 0 ? nothing : aseed )
		ssq.serviceRNG = MersenneTwister( sseed < 0 ? nothing : sseed )

		ssq.nCustomersServed = 0

		ssq.sim = Simulation()
		ssq.server = Resource( ssq.sim, 1 )
	end  # initialize( ssq, aseed, sseed )
end

# ╔═╡ 5f55e6b0-d4ac-11ea-0064-ffb407d0788a
ssq = SSQ(
	mat=meanArrivalTime,
	mst=meanServiceTime,
	nc=nCustomers )

# ╔═╡ 07ce9790-d4aa-11ea-31ee-631837666f1a
@resumable function customerProcess( sim::Simulation, ssq::SSQ, ii::Int,
    results::Vector{Vector{Float64}} )
    # Wait for server.
    @yield request( ssq.server )
    results[2][ii] = now( sim )

    # Get served.
    serviceTime = rand( ssq.serviceRNG, ssq.serviceDist )
    @yield timeout( ssq.sim, serviceTime, priority=1 )
    results[3][ii] = now( sim )
    @yield release( ssq.server )

    # Wrap up.
    ssq.nCustomersServed += 1

    if ssq.nCustomersServed == ssq.nCustomers
        throw( StopSimulation() )
    end  # if ssq.nCustomersServed == ssq.nCustomers
end  # customerProcess( sim, ssq, ii, results )

# ╔═╡ bccbe7b0-d4aa-11ea-13f8-411bcef49858
@resumable function customerGenerationProcess( sim::Simulation, ssq::SSQ,
    results::Vector{Vector{Float64}} )
    ii = 0

    while true
        ii += 1

        # Customer arrives.
        arrivalTime = rand( ssq.arrivalRNG, ssq.arrivalDist )
        @yield timeout( sim, arrivalTime )
        push!( results[1], now( sim ) )
        push!.( results[2:3], Inf )

        @process customerProcess( sim, ssq, ii, results )
    end  # while true
end  # customerGenerationProcess( sim, ssq, results )

# ╔═╡ ef344350-d4aa-11ea-1c77-c736b588fdeb
function simulateSSQ( ssq::SSQ; aseed::Int=-1, sseed::Int=-1 )
    initialize( ssq, aseed, sseed )
    results = map( ii -> Vector{Float64}(), 1:3 )

    @process customerGenerationProcess( ssq.sim, ssq, results )
    run( ssq.sim )
    
    ssq.results = DataFrame( hcat( eachindex( results[1] ), results... ),
        ["Customer", "Arrival time", "Service start time", "Service end time"] )
	return true
end  # simulateSSQ( ssq, aseed, sseed )

# ╔═╡ 8d8baa40-d4ae-11ea-356b-cd04b5a0e62d
hasFinished = simulateSSQ(ssq, aseed=arrivalSeed, sseed=serviceSeed);

# ╔═╡ b7024d30-d4b2-11ea-21dd-5b8829c46ea4
function generateEventList( ssq::SSQ, hasFinished::Bool )
    # States are:
    #   1. In queue
    #   2. Being served
	singleEvents = [
         1  0  # Customers enters queue
        -1  1  # Service starts
         0 -1  # Service ends
    ]
    nCustomers = size( ssq.results, 1 )
    customerEvents = Matrix( ssq.results[:, 2:end] )

	# Build event list.
    inds = ones( Int, 3 )
    ii = 1
    tmpEventTimes = zeros( nCustomers * 3 )
    tmpEvents = zeros( Int, nCustomers * 3, 2 )

	while any( inds .<= nCustomers )
        nextTimes = [inds[1] > nCustomers ? NaN :
            ssq.results[inds[1], "Arrival time"],
            inds[2] > nCustomers ? NaN :
            ssq.results[inds[2], "Service start time"],
            inds[3] > nCustomers ? NaN :
            ssq.results[inds[3], "Service end time"]]
        tmpEventTimes[ii] = minimum( filter( tm -> !isnan( tm ), nextTimes ) )
        nextEvent = findlast( nextTimes .== tmpEventTimes[ii] )
        tmpEvents[ii, :] = singleEvents[nextEvent, :]

        ii += 1
        inds[nextEvent] += 1
    end  # while any( inds .<= nCustomers )

	eventTimes = vcat( 0, unique( tmpEventTimes )[1:(end-1)] )
    events = map( eventTimes ) do eventTime
        eventMatch = findall( tmpEventTimes .== eventTime )
        return sum( tmpEvents[eventMatch, :], dims=1)
    end  # map( ... ) do eventTime
    events = cumsum( vcat( events... ), dims=1 )

	return DataFrame( hcat( eventTimes, events ),
		["Time", "Customers in queue", "Customers being served"] )
end  # generateEventList( ssq, hasFinished )

# ╔═╡ 56e62b10-d4b7-11ea-31fc-a5e39951db94
function computeStats( ssq::SSQ, hasFinished::Bool )
	# Easily computable stats.
    delays = ssq.results[:, "Service start time"] -
        ssq.results[:, "Arrival time"]
    delays = delays[1:ssq.nCustomers]

    arrivalTimes = ssq.results[1:ssq.nCustomers, "Arrival time"]
    arrivalTimes = arrivalTimes - vcat( 0, arrivalTimes[1:(end-1)] )

    serviceTimes = ssq.results[:, "Service end time"] -
        ssq.results[:, "Service start time"]
    serviceTimes = serviceTimes[1:ssq.nCustomers]

    totalSimTime = maximum( filter( tm -> tm < Inf,
        ssq.results[:, "Service end time"] ) )
    averageDelay = mean( delays )
    averageArrivalTime = mean( arrivalTimes )
    averageServiceTime = mean( serviceTimes )
    averageTimeInSystem = averageDelay + averageServiceTime
    maximumDelay = maximum( delays )
    maximumTimeInSystem = maximum( delays + serviceTimes )
    longDelayProportion = count( delays .>= 1 ) / ssq.nCustomers
	
	# Stats requiring event list.
	eventList = generateEventList( ssq, hasFinished )
	eventTimes = eventList[:, "Time"]
	eventTimes = vcat( eventTimes[2:end], totalSimTime ) - eventTimes

	averageInQueue = transpose( eventList[:, "Customers in queue"] ) * eventTimes /
		totalSimTime
    serverOccupation = transpose( eventList[:, "Customers being served"] ) *
		eventTimes / totalSimTime
    averageInSystem = averageInQueue + serverOccupation
    maximumQueueLength = Int( maximum( eventList[:, "Customers in queue"] ) )
	
	statNames = [
		"Av. arrival time",
		"Av. service time",
		"Total sim time",
		"Av. delay",
		"Av. customers in queue",
		"Av. server occupation",
		"Av. in system",
		"Av. time in system",
		"Max. queue length",
		"Max. delay",
		"Max. time in system",
		"Prop. customers with long delay"
	]
	stats = [averageArrivalTime, averageServiceTime,
        totalSimTime, averageDelay, averageInQueue, serverOccupation,
        averageInSystem, averageTimeInSystem, maximumQueueLength,
        maximumDelay, maximumTimeInSystem, longDelayProportion]
	
	return hcat( statNames, stats )
end  # computeStats( ssq, hasFinished )

# ╔═╡ 4bc7f240-d4b7-11ea-1c51-85fe4ff95a10
summaryStats = computeStats( ssq, hasFinished )

# ╔═╡ c58a39ae-d4b9-11ea-1323-679dcdd0dea7
function plotResults( ssq::SSQ, hasFinished::Bool, plotType::Symbol )
	if !in( plotType, [:server, :queue, :system] )
		return
	end
	
	eventList = generateEventList( ssq, hasFinished )
	plotInfo = Dict(
		:server => ("Server occupation", :darkgreen),
		:queue => ("Queue length", :red),
		:system => ("Customers in system", :darkblue)
	)
	serverOccupation = eventList[:, "Customers being served"]
	queueSize = eventList[:, "Customers in queue"]
	
	if plotType === :server
		plotData = serverOccupation
	elseif plotType === :queue
		plotData = queueSize
	else
		plotData = serverOccupation + queueSize
	end
	
	nEvents = length( plotData )
	eventTimes = map( 1:(2*nEvents - 1) ) do ii
		eventList[floor( Int, ii/2 ) + 1, "Time"]
	end # map( 1:(2*nEvents - 1) ) do ii
	plotData = plotData[ceil.( Int, (1:(2*nEvents - 1)) / 2 )]
	
	ymax = max( maximum( plotData ), 15 )
	plt = plot( eventTimes,  plotData, ylim=[0, ymax], lw=2,
		label=plotInfo[plotType][1], lc=plotInfo[plotType][2], fill=0,
		fc=plotInfo[plotType][2], fa=0.3 )

end  # plotResults( ssq, hasFinished )

# ╔═╡ d9723400-d4b9-11ea-1869-9365b720d99c
plotResults( ssq, hasFinished, :server )

# ╔═╡ f5bd7af0-d4bb-11ea-1c72-6d275d3ea6d8
plotResults( ssq, hasFinished, :queue )

# ╔═╡ 2ea77cd0-d4bc-11ea-202f-6bdaec046385
plotResults( ssq, hasFinished, :system )

# ╔═╡ Cell order:
# ╟─bdfde0c0-d4e6-11ea-019d-6b1ee1941043
# ╟─8e8aea70-d4b1-11ea-36b9-a97a7a011344
# ╟─90590d00-d4ac-11ea-270d-c75e1c45c1c7
# ╟─32d3c120-d55b-11ea-0850-634f10402ef3
# ╠═8f167ae0-d4ac-11ea-305b-1d031cad24c3
# ╠═8ee04fb0-d4ac-11ea-37aa-e1763fa755a6
# ╠═8eb40f90-d4ac-11ea-26e1-1d5cb739a2a1
# ╟─c5f383d0-d4ae-11ea-3b87-0946a351744d
# ╟─6872b6b0-d55b-11ea-22aa-b93a09eb84c2
# ╠═c1aab690-d4ae-11ea-1358-69afe35fd094
# ╠═c12050e0-d4ae-11ea-3f45-63bc77f9b8e2
# ╟─8175cb00-d4ae-11ea-2fb1-91a11a30ce61
# ╠═5f55e6b0-d4ac-11ea-0064-ffb407d0788a
# ╠═8d8baa40-d4ae-11ea-356b-cd04b5a0e62d
# ╟─61a76b70-d4e6-11ea-2ee0-b3a8f81197cc
# ╟─ae740382-d4b1-11ea-34a5-73b18d144608
# ╟─4bc7f240-d4b7-11ea-1c51-85fe4ff95a10
# ╟─d9723400-d4b9-11ea-1869-9365b720d99c
# ╟─f5bd7af0-d4bb-11ea-1c72-6d275d3ea6d8
# ╟─2ea77cd0-d4bc-11ea-202f-6bdaec046385
# ╟─4dbdf6e0-d4ac-11ea-145e-bda00be7cf74
# ╟─86959420-d4aa-11ea-0a50-dfa2d4327986
# ╠═96d17bc0-d4bd-11ea-0005-67c9a0bc9035
# ╠═c68caa00-d4c3-11ea-294a-5f789dc8f632
# ╠═8d98ed80-d4aa-11ea-060f-95bbe948bd1a
# ╟─23acb610-d4b2-11ea-2a91-350c61fb70ee
# ╟─09a250b0-d4ab-11ea-2fc0-23964b7c6857
# ╟─1837fd00-d4ab-11ea-34d5-674ae7beffe0
# ╟─e932c990-d4aa-11ea-18ca-71c6971a0951
# ╟─ef344350-d4aa-11ea-1c77-c736b588fdeb
# ╟─9d3ef860-d4aa-11ea-3cbf-61ed5de1b652
# ╟─bccbe7b0-d4aa-11ea-13f8-411bcef49858
# ╟─3cb62400-d4aa-11ea-2e8e-57b60f915350
# ╟─07ce9790-d4aa-11ea-31ee-631837666f1a
# ╟─ad564200-d4b2-11ea-0e10-a547e82bb55f
# ╟─b7024d30-d4b2-11ea-21dd-5b8829c46ea4
# ╟─56e62b10-d4b7-11ea-31fc-a5e39951db94
# ╟─c58a39ae-d4b9-11ea-1323-679dcdd0dea7
