using ApplicationBuilder

using Compat
using Compat.Pkg

examples_blink = joinpath(@__DIR__, "..", "..", "examples", "blink.jl")

# Allow this file to be called either as a standalone file to build the above
# example, or from runtests.jl using a provided builddir.
Compat.isdefined(:builddir) || (builddir="builddir")

blinkPkg = Pkg.dir("Blink")
httpParserPkg = Pkg.dir("HttpParser")
mbedTLSPkg = Pkg.dir("MbedTLS")

@assert blinkPkg != nothing "Blink is not installed!"

using Blink

ApplicationBuilder.build_app_bundle(examples_blink;
    verbose = true,
    resources = [joinpath(blinkPkg, "deps","Julia.app"),
                 joinpath(blinkPkg, "src","AtomShell","main.js"),
                 joinpath(blinkPkg, "src","content","main.html"),
                 joinpath(blinkPkg, "res")],
    # Get the current library names directly from the packages that use them,
    # which keeps this build script robust against lib version changes.
    libraries = [HttpParser.lib,
                 MbedTLS.libmbedcrypto],
    appname="HelloBlink", builddir=builddir)
