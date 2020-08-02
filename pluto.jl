### A Pluto.jl notebook ###
# v0.11.2

using Markdown
using InteractiveUtils

# ╔═╡ 3031ea10-d3cf-11ea-27e8-975349cb2b63
md"""Set the simulaion parameters"""

# ╔═╡ 3a90f190-d3cf-11ea-3c85-4d0786a18819
md"""Run the simulation until time 15"""

# ╔═╡ 4170964e-d3cf-11ea-0b33-f3f0d61d400f
md"""And check what has become of `a`. This should be `[7.0, 14.0]`.""" 

# ╔═╡ 5e216f22-d3cc-11ea-3336-ff30c0560869
md"""Initialising the SimJulia package"""

# ╔═╡ 6dbc2f60-d3cc-11ea-1522-b35da75c5c26
md"""Defining a simple process"""

# ╔═╡ cec3f7c0-d3cc-11ea-11f8-59e0a647f989
md"""Set up the simulation"""

# ╔═╡ e1b276e0-d3cc-11ea-3ad8-f5a6a01276b3
md"""Add the car process to the simulation"""

# ╔═╡ 3c2f3fa0-d3cc-11ea-1a8e-f1dc3fb6324a
using SimJulia

# ╔═╡ 0b053af0-d3cd-11ea-3afc-5f193e4e9dde
parking_duration = 5

# ╔═╡ 13f9dd00-d3cd-11ea-076e-6bde39c97d9a
trip_duration = 2

# ╔═╡ 77e13b20-d3cc-11ea-06ba-41feabc0f271
@resumable function car(env::Environment,
		parking_duration::Real,
		trip_duration::Real,
		a::Vector{Float64})
	
	while true
		# println("Start parking at ", now(env))
		@yield timeout(env, max(parking_duration, 0))
		# println("Start driving at ", now(env))
		@yield timeout(env, max(trip_duration, 0))
		push!(a, now(env))
	end
end  # car(env, parking_duration, trip_duration)

# ╔═╡ c700d0d0-d3cc-11ea-15cd-0b95c16bcf52
sim = Simulation()

# ╔═╡ dff13ee0-d3cc-11ea-0b0a-8daa8a13c18b
SimJulia.run(sim, 15)

# ╔═╡ b9d7de6e-d3cd-11ea-2c4e-1dbb4fe4826e
a = Vector{Float64}()

# ╔═╡ 4b5acde0-d3cd-11ea-2560-13abe9334192
a

# ╔═╡ e9397f30-d3cc-11ea-0fcc-b14f4eb898f5
@process car(sim, parking_duration, trip_duration, a)

# ╔═╡ Cell order:
# ╟─3031ea10-d3cf-11ea-27e8-975349cb2b63
# ╠═0b053af0-d3cd-11ea-3afc-5f193e4e9dde
# ╠═13f9dd00-d3cd-11ea-076e-6bde39c97d9a
# ╟─3a90f190-d3cf-11ea-3c85-4d0786a18819
# ╠═dff13ee0-d3cc-11ea-0b0a-8daa8a13c18b
# ╟─4170964e-d3cf-11ea-0b33-f3f0d61d400f
# ╠═4b5acde0-d3cd-11ea-2560-13abe9334192
# ╟─5e216f22-d3cc-11ea-3336-ff30c0560869
# ╠═3c2f3fa0-d3cc-11ea-1a8e-f1dc3fb6324a
# ╟─6dbc2f60-d3cc-11ea-1522-b35da75c5c26
# ╠═77e13b20-d3cc-11ea-06ba-41feabc0f271
# ╟─cec3f7c0-d3cc-11ea-11f8-59e0a647f989
# ╠═c700d0d0-d3cc-11ea-15cd-0b95c16bcf52
# ╟─e1b276e0-d3cc-11ea-3ad8-f5a6a01276b3
# ╠═b9d7de6e-d3cd-11ea-2c4e-1dbb4fe4826e
# ╠═e9397f30-d3cc-11ea-0fcc-b14f4eb898f5
