using ApplicationBuilder

using Pkg

examples_blink = joinpath(@__DIR__, "..", "..", "examples", "blink.jl")

# Allow this file to be called either as a standalone file to build the above
# example, or from runtests.jl using a provided builddir.
@isdefined(builddir) || (builddir="builddir")

using Blink
MbedTLS = Blink.Mux.HTTP.MbedTLS

blinkPkg = dirname(dirname(pathof(Blink)))
mbedTLSPkg = dirname(dirname(pathof(MbedTLS)))

ApplicationBuilder.build_app_bundle(examples_blink;
    verbose = true,
    resources = [joinpath(blinkPkg, "deps","Julia.app"),
                 joinpath(blinkPkg, "src","AtomShell","main.js"),
                 joinpath(blinkPkg, "src","content","main.html"),
                 joinpath(blinkPkg, "res")],
    # Get the current library names directly from the packages that use them,
    # which keeps this build script robust against lib version changes.
    libraries = [MbedTLS.libmbedcrypto],
    appname="HelloBlink", builddir=builddir)
