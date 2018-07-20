using ApplicationBuilder; using BuildApp

examples_blink = joinpath(@__DIR__, "..", "..", "examples", "blink.jl")

# Allow this file to be called either as a standalone file to build the above
# example, or from runtests.jl using a provided builddir.
isdefined(:builddir) || (builddir=mktempdir())

blinkPkg = Pkg.dir("Blink")
httpParserPkg = Pkg.dir("HttpParser")
mbedTLSPkg = Pkg.dir("MbedTLS")

@assert blinkPkg != nothing "Blink is not installed!"

BuildApp.build_app_bundle(examples_blink;
    verbose = true,
    resources = [joinpath(blinkPkg, "deps","Julia.app"),
                 joinpath(blinkPkg, "src","AtomShell","main.js"),
                 joinpath(blinkPkg, "src","content","main.html"),
                 joinpath(blinkPkg, "res")],
    libraries = [joinpath(httpParserPkg, "deps","usr","lib","libhttp_parser.dylib"),
                 joinpath(mbedTLSPkg, "deps","usr","lib","libmbedcrypto.2.dylib")],
    appname="HelloBlink", builddir=builddir)
