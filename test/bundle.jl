# Windows and Linux tests

push!(LOAD_PATH, "..\\..\\")
using Test
using Pkg
using ApplicationBuilder

builddir = mktempdir()
@assert isdir(builddir)

@testset "HelloWorld.app" begin
    @test 0 == include("build_examples/commandline_hello.jl")
    @test isdir(joinpath(builddir, "hello"))
    p = joinpath(builddir,"hello", "bin", "hello")
    @test success(`$p`)
    #@test success(`open $builddir/hello.app`)
end
