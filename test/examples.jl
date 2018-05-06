using Base.Test

julia = Base.julia_cmd().exec[1]
build_app_jl = joinpath(@__DIR__, "..", "build_app.jl")
examples_blink = joinpath(@__DIR__, "..", "examples", "blink.jl")
examples_hello = joinpath(@__DIR__, "..", "examples", "hello.jl")

builddir = mktempdir()
@assert isdir(builddir)

@testset "HelloWorld.app" begin
# Test the build_app.jl script.
# `@test contains(readstring(cmd), "Done building")` tests that the command
# runs, and that gets all the way to the end. This is prefereable to
# `@test success(cmd)`, because `success` suppresses the cmd's output, so we
# can't see where the test is failing.
@test contains(readstring(`$julia $build_app_jl --verbose $examples_hello "HelloWorld" $builddir`),
               "Done building")
@test isdir("$builddir/HelloWorld.app")
@test success(`$builddir/HelloWorld.app/Contents/MacOS/hello`)
end

@testset "HelloBlink.app" begin
blinkPkg = Pkg.dir("Blink")
httpParserPkg = Pkg.dir("HttpParser")
mbedTLSPkg = Pkg.dir("MbedTLS")

@test contains(readstring(`$julia $build_app_jl --verbose
            -R $(joinpath(blinkPkg, "deps/Julia.app"))
            -R $(joinpath(blinkPkg, "src/AtomShell/main.js"))
            -R $(joinpath(blinkPkg, "src/content/main.html"))
            -R $(joinpath(blinkPkg, "res"))
            -L $(joinpath(httpParserPkg, "deps/usr/lib/libhttp_parser.dylib"))
            -L $(joinpath(mbedTLSPkg, "deps/usr/lib/libmbedcrypto.2.7.1.dylib"))
            $examples_blink "HelloBlink" $builddir`),
    "Done building")

@test isdir("$builddir/HelloBlink.app")

# Manually kill HelloBlink, since it waits for user input.
@async begin
    sleep(15) # wait til blink has started up
    run(`pkill blink`)
end
try # expect failure due to pkill, so not really much to test.
    run(`$builddir/HelloBlink.app/Contents/MacOS/blink`)
end

end
