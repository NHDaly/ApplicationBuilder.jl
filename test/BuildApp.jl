using Base.Test
using ApplicationBuilder; using BuildApp;

examples_blink = joinpath(@__DIR__, "..", "examples", "blink.jl")
examples_hello = joinpath(@__DIR__, "..", "examples", "hello.jl")

builddir = mktempdir()
@assert isdir(builddir)

@testset "HelloWorld.app" begin
@test 0 == BuildApp.build_app_bundle(examples_hello;
                             verbose=true, appname="HelloWorld", builddir=builddir)
@test isdir("$builddir/HelloWorld.app")
@test success(`$builddir/HelloWorld.app/Contents/MacOS/hello`)

# There shouldn't be a Libraries dir since none specified.
@test !isdir("$builddir/HelloBlink.app/Contents/Libraries")
end

@testset "HelloBlink.app" begin
blinkPkg = Pkg.dir("Blink")
httpParserPkg = Pkg.dir("HttpParser")
mbedTLSPkg = Pkg.dir("MbedTLS")

@test 0 == BuildApp.build_app_bundle(examples_blink;
    verbose = true,
    resources = [joinpath(blinkPkg, "deps","Julia.app"),
                 joinpath(blinkPkg, "src","AtomShell","main.js"),
                 joinpath(blinkPkg, "src","content","main.html"),
                 joinpath(blinkPkg, "res")],
    libraries = [joinpath(httpParserPkg, "deps","usr","lib","libhttp_parser.dylib"),
                 joinpath(mbedTLSPkg, "deps","usr","lib","libmbedcrypto.2.7.1.dylib")],
    appname="HelloBlink", builddir=builddir)

@test isdir("$builddir/HelloBlink.app")
# Test that it copied the correct files
@test isdir("$builddir/HelloBlink.app/Contents/Libraries")
@test isfile("$builddir/HelloBlink.app/Contents/Resources/main.js")

# Manually kill HelloBlink, since it waits for user input.
@async begin
    sleep(15) # wait til blink has started up
    run(`pkill blink`)
end
try # expect failure due to pkill, so not really much to test.
    run(`$builddir/HelloBlink.app/Contents/MacOS/blink`)
end

end
