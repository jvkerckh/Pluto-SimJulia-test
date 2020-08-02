using SimJulia

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


sim = Simulation()

a = Vector{Float64}()
parking_duration = 5
trip_duration = 2
@process car(sim, parking_duration, trip_duration, a)

SimJulia.run(sim, 15)
display(a)