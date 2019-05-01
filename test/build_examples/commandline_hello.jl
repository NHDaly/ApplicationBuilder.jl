using ApplicationBuilder

# Allow this file to be called either as a standalone file to build the above
# example, or from runtests.jl using a provided builddir.
@isdefined(builddir) || (builddir="builddir")

build_app_bundle(joinpath(abspath(@__DIR__,"..",".."),"examples","commandline_hello.jl"),
                 appname="hello", binary_name="hello",
                 commandline_app=true, builddir=builddir)
