using Test
using Pkg
using ApplicationBuilder

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
    p = open(cmd, "r+") # Make sure it runs correctly
    sleep(1)
    process_exited(p) && (println("Test Failed: failed to launch: \n", read(p.out, String)); return false)
    sleep(timeout)
    process_exited(p) && (println("Test Failed: Process died: \n", read(p.out, String)); return false)
    # Manually kill program after it's been running for a bit.
    kill(p); sleep(1)
    return true
end

# Test that it can run without .julia directory (Dangerous!)
function testBundledSuccessfully_macro(cmd_expr, timeout=10)
    quote
        val = false
        julia_dir = Pkg.Pkg2._pkgroot()
        mv(julia_dir, julia_dir*".bak")  # NOTE: MUST mv() THIS BACK
        try
            val = testRunAndKillProgramSucceeds($cmd_expr, $timeout)
        catch
        end
        mv(julia_dir*".bak", julia_dir)  # NOTE: MUST RUN THIS LINE IF ABOVE IS RUN
        val
    end
end
macro testBundledSuccessfully(expr...)
    testBundledSuccessfully_macro(expr...)
end

# Disabling the SDL tests since Cairo is currently broken in METADATA.
#@testset "sdl: simple example of binary dependencies" begin
#@test 0 == include("build_examples/sdl.jl")
## Test that it runs correctly
#@test testRunAndKillProgramSucceeds(`$builddir/HelloSDL2.app/Contents/MacOS/sdl`)
## Test that it can run without .julia directory
#@test @testBundledSuccessfully(`$builddir/HelloSDL2.app/Contents/MacOS/sdl`, 3)
#end

# Disabling Blink Tests since Blink has changed and this no longer works.
#@testset "HelloBlink.app" begin
#@test 0 == include("build_examples/blink.jl")
#
#@test isdir("$builddir/HelloBlink.app")
## Test that it copied the correct files
#@test isdir("$builddir/HelloBlink.app/Contents/Libraries")
#@test isfile("$builddir/HelloBlink.app/Contents/Resources/main.js")
## Test that it runs correctly
#@test testRunAndKillProgramSucceeds(`$builddir/HelloBlink.app/Contents/MacOS/blink`)
## Test that it can run without .julia directory
#
## TODO: This is broken because Blink currently can't be statically compiled
## https://github.com/JunoLab/Blink.jl/pull/174
## (It appears to work in this test, but the application does nothing because it errors.)
##  @test @testBundledSuccessfully(`$builddir/HelloBlink.app/Contents/MacOS/blink`, 10)
## Replacing with a test_broken so we remember.
#@test_broken false
#end
