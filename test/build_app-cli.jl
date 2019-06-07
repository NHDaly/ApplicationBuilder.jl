
using Test

# prevent shell_split on removing all slashes
path_to_cmd(path::String) = replace(path, "\\" => "\\\\")

julia = Base.julia_cmd().exec[1]
build_app_jl = joinpath(abspath(@__DIR__, ".."), "build_app.jl")
examples_hello = joinpath(abspath(@__DIR__, ".."), "examples", "hello.jl")

builddir = mktempdir()
@assert isdir(builddir)

@testset "Basic file resource args" begin
# Test the build_app.jl script CLI args.
  res1 = @__FILE__ # haha copy this file itself as a "resource"!
  res2 = joinpath(@__DIR__, "runtests.jl") # lol sure this is a resource, why not.
  
  NEWARGS = Base.shell_split("""--verbose
          -R $(path_to_cmd(res1)) --resource $(path_to_cmd(res2)) -L $(path_to_cmd(res1)) --lib $(path_to_cmd(res2))
          $(path_to_cmd(examples_hello)) "HelloWorld" $(path_to_cmd(builddir))""")
  eval(:(ARGS = $NEWARGS))
  
  @test 0 == include(build_app_jl)
  println("=== Build Directory ===")
  println(readdir(builddir))
  println(readdir("$builddir/HelloWorld"))
  println(readdir("$builddir/HelloWorld/bin"))
  println(readdir("$builddir/HelloWorld/res"))
  println(readdir("$builddir/HelloWorld/lib"))

  if Sys.isapple()
    @test isdir("$builddir/HelloWorld.app")
    @test isfile("$builddir/HelloWorld.app/Contents/MacOS/hello")

    # Make sure the specified resources and libs were copied:
    @test isfile("$builddir/HelloWorld.app/Contents/Resources/$(basename(res1))")
    @test isfile("$builddir/HelloWorld.app/Contents/Resources/$(basename(res2))")
    @test isfile("$builddir/HelloWorld.app/Contents/Libraries/$(basename(res1))")
  else
    @test isdir("$builddir/HelloWorld")
    @test isdir("$builddir/HelloWorld/bin")
    @test isfile("$builddir/HelloWorld/bin/hello.exe")
    @test isfile("$builddir/HelloWorld/bin/hello.dll")
    @test isfile("$builddir/HelloWorld/bin/hello.a")

    # Make sure the specified resources and libs were copied:
    @test isfile("$builddir/HelloWorld/res/$(basename(res1))")
    @test isfile("$builddir/HelloWorld/res/$(basename(res2))")
    @test isfile("$builddir/HelloWorld/lib/$(basename(res1))")
  end
end

@testset "Exits without juliaprog_main" begin
  @test !success(`$julia $build_app_jl --verbose`)  # no main.jl
end
