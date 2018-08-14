using Compat

using Compat.Test
using Compat.Pkg
using ApplicationBuilder

const julia_v07 = VERSION > v"0.7-"

builddir = mktempdir()
@assert isdir(builddir)

@testset "make_bundle_identifier Utils" begin
@test occursin(r"""^com.[a-z0-9]+.myappnamedthisapp22$""",
            ApplicationBuilder.make_bundle_identifier("My app named this_app22")
      )
end

@testset "HelloWorld.app" begin
@test 0 == include("build_examples/hello.jl")
@test isdir("$builddir/HelloWorld.app")
@test success(`$builddir/HelloWorld.app/Contents/MacOS/hello`)

# There shouldn't be a Libraries dir since none specified.
@test !isdir("$builddir/HelloWorld.app/Contents/Libraries")

# Ensure all dependencies on Julia libs are internal, so the app is portable.
@testset "No external Dependencies" begin
@test !success(pipeline(
                `otool -l "$builddir/HelloWorld.app/Contents/MacOS/hello"`,
                `grep 'julia'`,  # Get all julia deps
                `grep -v '@rpath'`))  # make sure all are relative.
end
end

@testset "commandline_app" begin
@test 0 == include("build_examples/commandline_hello.jl")
@test success(`open $builddir/hello.app`)
end


function testRunAndKillProgramSucceeds(cmd, timeout=10)
    out, _, p = readandwrite(cmd) # Make sure it runs correctly
    sleep(1)
    process_exited(p) && (println("Test Failed: failed to launch: \n", readstring(out)); return false)
    sleep(timeout)
    process_exited(p) && (println("Test Failed: Process died: \n", readstring(out)); return false)
    # Manually kill program after it's been running for a bit.
    kill(p); sleep(1)
    process_exited(p) || (println("Test Failed: Process failed to exit: \n", readstring(out)); return false)
    return true
end

# Test that it can run without .julia directory (Dangerous!)
function testBundledSuccessfully_macro(cmd_expr, timeout=10)
    quote
        val = false
        mv(Pkg.dir(), Pkg.dir()*".bak")  # NOTE: MUST mv() THIS BACK
        try
            val = testRunAndKillProgramSucceeds($cmd_expr, $timeout)
        catch
        end
        mv(Pkg.dir()*".bak", Pkg.dir())  # NOTE: MUST RUN THIS LINE IF ABOVE IS RUN
        val
    end
end
macro testBundledSuccessfully(expr...)
    testBundledSuccessfully_macro(expr...)
end

if !julia_v07  # Blink and SDL don't yet work on julia v0.7.

# Disabling the SDL tests since Cairo is currently broken in METADATA.
#@testset "sdl: simple example of binary dependencies" begin
#@test 0 == include("build_examples/sdl.jl")
## Test that it runs correctly
#@test testRunAndKillProgramSucceeds(`$builddir/HelloSDL2.app/Contents/MacOS/sdl`)
## Test that it can run without .julia directory
#@test @testBundledSuccessfully(`$builddir/HelloSDL2.app/Contents/MacOS/sdl`, 3)
#end

@testset "HelloBlink.app" begin
@test 0 == include("build_examples/blink.jl")

@test isdir("$builddir/HelloBlink.app")
# Test that it copied the correct files
@test isdir("$builddir/HelloBlink.app/Contents/Libraries")
@test isfile("$builddir/HelloBlink.app/Contents/Resources/main.js")
# Test that it runs correctly
@test testRunAndKillProgramSucceeds(`$builddir/HelloBlink.app/Contents/MacOS/blink`)
# Test that it can run without .julia directory
@test @testBundledSuccessfully(`$builddir/HelloBlink.app/Contents/MacOS/blink`, 10)
end
end
