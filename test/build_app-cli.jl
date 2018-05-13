using Base.Test

julia = Base.julia_cmd().exec[1]
build_app_jl = joinpath(@__DIR__, "..", "build_app.jl")
examples_blink = joinpath(@__DIR__, "..", "examples", "blink.jl")
examples_hello = joinpath(@__DIR__, "..", "examples", "hello.jl")

builddir = mktempdir()
@assert isdir(builddir)

@testset "HelloWorld.app" begin
# Test the build_app.jl script.
ARGS = Base.shell_split("""--verbose $examples_hello "HelloWorld" $builddir""")
@test 0 == include("../build_app.jl")
@test isdir("$builddir/HelloWorld.app")
@test isfile("$builddir/HelloWorld.app/Contents/MacOS/hello")
end

@testset "HelloBlink.app" begin
# Test the build_app.jl script with complex args.
blinkPkg = Pkg.dir("Blink")
httpParserPkg = Pkg.dir("HttpParser")
mbedTLSPkg = Pkg.dir("MbedTLS")

ARGS = Base.shell_split("""--verbose
            -R $(joinpath(blinkPkg, "deps/Julia.app"))
            -R $(joinpath(blinkPkg, "src/AtomShell/main.js"))
            -R $(joinpath(blinkPkg, "src/content/main.html"))
            -R $(joinpath(blinkPkg, "res"))
            -L $(joinpath(httpParserPkg, "deps/usr/lib/libhttp_parser.dylib"))
            -L $(joinpath(mbedTLSPkg, "deps/usr/lib/libmbedcrypto.2.7.1.dylib"))
            $examples_blink "HelloBlink" $builddir""")
@test 0 == include("../build_app.jl")

@test isdir("$builddir/HelloBlink.app")
@test isfile("$builddir/HelloBlink.app/Contents/MacOS/blink")

end
