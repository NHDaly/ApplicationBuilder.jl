# Windows and Linux tests

using Test
using Pkg
using ApplicationBuilder

builddir = mktempdir()
@assert isdir(builddir)

@testset "HelloWorld.app" begin
    @test 0 == include("build_examples/commandline_hello.jl")
    @test isdir(joinpath(builddir, "hello"))
    @test success(`$builddir/hello/bin/hello`)
    #@test success(`open $builddir/hello.app`)
end
