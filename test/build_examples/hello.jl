using ApplicationBuilder

examples_hello = joinpath(@__DIR__, "..", "..", "examples", "hello.jl")

# Allow this file to be called either as a standalone file to build the above
# example, or from runtests.jl using a provided builddir.
@isdefined(builddir) || (builddir="builddir")

ApplicationBuilder.build_app_bundle(examples_hello;
                          verbose=true, appname="HelloWorld", builddir=builddir)
