using Compat

using Compat.Test
using Compat.Pkg
using ApplicationBuilder

const julia_v07 = VERSION > v"0.7-"

builddir = mktempdir()
@assert isdir(builddir)

#@testset "make_bundle_identifier Utils" begin
#@test occursin(r"""^com.[a-z0-9]+.myappnamedthisapp22$""",
#            ApplicationBuilder.make_bundle_identifier("My app named this_app22")
#      )
#end

@testset "HelloWorld.app" begin
@test 0 == include("build_examples/hello.jl")
#@test isdir("$builddir/HelloWorld.app")
#@test success(`$builddir/HelloWorld.app/Contents/MacOS/hello`)

# There shouldn't be a Libraries dir since none specified.
#@test !isdir("$builddir/HelloWorld.app/Contents/Libraries")
#
# Ensure all dependencies on Julia libs are internal, so the app is portable.
#@testset "No external Dependencies" begin
#@test !success(pipeline(
#                `otool -l "$builddir/HelloWorld.app/Contents/MacOS/hello"`,
#                `grep 'julia'`,  # Get all julia deps
#                `grep -v '@rpath'`))  # make sure all are relative.
#end
end

@testset "commandline_app" begin
@test 0 == include("build_examples/commandline_hello.jl")
#@test success(`open $builddir/hello.app`)
end
