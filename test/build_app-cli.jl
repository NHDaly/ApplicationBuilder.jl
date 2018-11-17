using Test

julia = Base.julia_cmd().exec[1]
build_app_jl = joinpath(@__DIR__, "..", "build_app.jl")
examples_hello = joinpath(@__DIR__, "..", "examples", "hello.jl")

builddir = mktempdir()
@assert isdir(builddir)

@testset "Basic file resource args" begin
# Test the build_app.jl script CLI args.
res1 = @__FILE__ # haha copy this file itself as a "resource"!
res2 = joinpath(@__DIR__, "runtests.jl") # lol sure this is a resource, why not.
NEWARGS = Base.shell_split("""--verbose
        -R $res1 --resource $res2 -L $res1 --lib $res2
        $examples_hello "HelloWorld" $builddir""")
eval(:(ARGS = $NEWARGS))
@test 0 == include("$build_app_jl")
@test isdir("$builddir/HelloWorld.app")
@test isfile("$builddir/HelloWorld.app/Contents/MacOS/hello")

# Make sure the specified resources and libs were copied:
@test isfile("$builddir/HelloWorld.app/Contents/Resources/$(basename(res1))")
@test isfile("$builddir/HelloWorld.app/Contents/Resources/$(basename(res2))")
@test isfile("$builddir/HelloWorld.app/Contents/Libraries/$(basename(res1))")
end

@testset "Exits without juliaprog_main" begin
  @test !success(`$julia $build_app_jl --verbose`)  # no main.jl
end
