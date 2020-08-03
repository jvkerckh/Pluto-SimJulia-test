### A Pluto.jl notebook ###
# v0.11.2

using Markdown
using InteractiveUtils

# ╔═╡ 08f42440-d488-11ea-27c7-37da318d5e0e
md"""Set the simulaion parameters"""

# ╔═╡ 36eec580-d488-11ea-0ca7-07f106d973a8
md"""Run the simulation until time 15 and check what has become of `a`.

These two things need to happen in a single code block since there is no way for Pluto to know that running the simulation changes `a`."""

# ╔═╡ 2f0ea0b0-d488-11ea-16f8-ddffcef284d7
md"""Initialising the SimJulia package"""

# ╔═╡ 5ead7c10-d488-11ea-1648-a993652ff6eb
md"""Defining a simple process.

The statement `empty!(a)` is needed to ensure the vector `a` is cleared at the start of the simulation. Otherwise, new values get added whenever the simulation parameters change and a new simulation is run."""

# ╔═╡ bb338ce0-d488-11ea-33f4-83d6f261c2b2
md"""Set up the simulation"""

# ╔═╡ de15c1b0-d488-11ea-0410-db15012cc98f
md"""Due to the way `SimJulia` works internally, the simulation setup must be done in a single cell.

Otherwise, Pluto doesn't realise that the @process macro changes sim."""

# ╔═╡ 4daa5230-d488-11ea-2569-f5c40e145d03
using SimJulia

# ╔═╡ 15c73900-d488-11ea-1765-f716b0cc5c9b
parking_duration = 5

# ╔═╡ 18abbb50-d488-11ea-04f4-b7fdad1ace55
trip_duration = 2

# ╔═╡ 5e3cb8e0-d488-11ea-1819-450e06af7e2b
@resumable function car(env::Environment,
		parking_duration::Real,
		trip_duration::Real,
		a::Vector{Float64})
	
	empty!(a)
	
	while true
		# println("Start parking at ", now(env))
		@yield timeout(env, max(parking_duration, 0))
		# println("Start driving at ", now(env))
		@yield timeout(env, max(trip_duration, 0))
		push!(a, now(env))
	end
end  # car(env, parking_duration, trip_duration)

# ╔═╡ 1c713ce0-d48a-11ea-37ca-4b0ba360465c
a = Vector{Float64}()

# ╔═╡ 7690e6f0-d488-11ea-2aa7-07bda19f571a
begin
	sim = Simulation()
	@process car(sim, parking_duration, trip_duration, a)
end

# ╔═╡ 1ccae080-d488-11ea-0b34-b37e5949bc3a
begin
	SimJulia.run(sim, 15)
	a
end

# ╔═╡ Cell order:
# ╟─08f42440-d488-11ea-27c7-37da318d5e0e
# ╠═15c73900-d488-11ea-1765-f716b0cc5c9b
# ╠═18abbb50-d488-11ea-04f4-b7fdad1ace55
# ╟─36eec580-d488-11ea-0ca7-07f106d973a8
# ╠═1ccae080-d488-11ea-0b34-b37e5949bc3a
# ╟─2f0ea0b0-d488-11ea-16f8-ddffcef284d7
# ╠═4daa5230-d488-11ea-2569-f5c40e145d03
# ╟─5ead7c10-d488-11ea-1648-a993652ff6eb
# ╠═5e3cb8e0-d488-11ea-1819-450e06af7e2b
# ╟─bb338ce0-d488-11ea-33f4-83d6f261c2b2
# ╠═1c713ce0-d48a-11ea-37ca-4b0ba360465c
# ╟─de15c1b0-d488-11ea-0410-db15012cc98f
# ╠═7690e6f0-d488-11ea-2aa7-07bda19f571a
