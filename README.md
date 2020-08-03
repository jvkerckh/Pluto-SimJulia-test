This repository gives a quick illustration of how a Pluto notebook can be used to demonstrate a SimJulia-based simulation.

Overview of the files:

* `pluto.jl` is a simple example coded exactly as you would when using the REPL. This illustrates that there are several pitfalls due to how SimJulia operates, which Pluto has no way of knowing about.

* `pluto_workaround.jl` is the same simple example, but adjusted such that it works as it should.

* `singleserverqueue.jl` is a fully realised example of a single server queue simulation with exponentially distributed arrival times for the customers, and exponentially distributed service times.