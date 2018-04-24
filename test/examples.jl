using Base.Test

julia = Base.julia_cmd().exec[1]
build_app_jl = joinpath(@__DIR__, "..", "build_app.jl")
examples_blink = joinpath(@__DIR__, "..", "examples", "blink.jl")
examples_hello = joinpath(@__DIR__, "..", "examples", "hello.jl")

@testset "HelloWorld.app" begin
@test success(`$julia $build_app_jl $examples_hello "HelloWorld"`)
@test success(`./builddir/HelloWorld.app/Contents/MacOS/hello`)
end

@testset "HelloBlink.app" begin
blinkPkg = Pkg.dir("Blink")
httpParserPkg = Pkg.dir("HttpParser")
mbedTLSPkg = Pkg.dir("MbedTLS")

@test success(`$julia $build_app_jl
    -R $(joinpath(blinkPkg, "deps/Julia.app"))
    -R $(joinpath(blinkPkg, "src/AtomShell/main.js"))
    -R $(joinpath(blinkPkg, "src/content/main.html"))
    -R $(joinpath(blinkPkg, "res"))
    -L $(joinpath(httpParserPkg, "deps/usr/lib/libhttp_parser.dylib"))
    -L $(joinpath(mbedTLSPkg, "deps/usr/lib/libmbedcrypto.2.7.1.dylib"))
    $examples_blink "HelloBlink"`)

@test success(`./builddir/HelloBlink.app/Contents/MacOS/blink`)
end
