include(joinpath("..","src","ApplicationBuilder.jl"))  # redefine function after changing ENV
using Base.Test

@testset "Don't change dir if not compiled." begin
eval(Base, :(PROGRAM_FILE = ""))
withenv(()->(include(joinpath("..","src","ApplicationBuilder.jl"))),
     "COMPILING_APPLE_BUNDLE"=>"false")  # Code is not being compiled.
sleep(1)  # wait for reload to kick in
cwd = pwd()
#  (must use `invokelatest` after `reload` to fix world-age problem.)
@test cwd == Base.invokelatest(ApplicationBuilder.App.change_dir_if_bundle)
@test cwd == pwd()  # didn't change
end

@testset "*Do* change dir if compiled as app." begin
# set up fake .App
tmpdir = mktempdir()
tmpAppResources = joinpath(tmpdir, "Tmp.app/Contents/Resources")
tmpAppMacOS = joinpath(tmpdir, "Tmp.app/Contents/MacOS")
tmpAppExe = joinpath(tmpdir, "Tmp.app/Contents/MacOS/tmp")
mkpath(tmpAppMacOS)
mkpath(tmpAppResources)
# Verify we change directory
eval(Base, :(PROGRAM_FILE = $tmpAppExe))
withenv(()->(include(joinpath("..","src","ApplicationBuilder.jl"))),
     "COMPILING_APPLE_BUNDLE"=>"true")  # Code *is* being compiled
cwd = pwd()
#  (must use `invokelatest` after `reload` to fix world-age problem.)
# TODO: except that doesn't work... why doesn't it find the latest function?
@test_broken cwd != Base.invokelatest(ApplicationBuilder.App.change_dir_if_bundle)
@test_broken Base.Filesystem.samefile(tmpAppResources, pwd())

# Teardown (reset working directory)
cd(cwd)
end

# TODO: not sure why the above tests are broken... I tried making a simple toy
# example, but this one passes... I'm not sure why.
#
#module M
#    foo() = 1
#end
#@testset "false" begin
#withenv(()->(eval(M, :(if get(ENV, "TEST", "false") == "true"; foo() = 2; end))),
#    "TEST"=>"false")
#@test 1 == M.foo()
#@test 1 == Base.invokelatest(M.foo)
#end
#@testset "true" begin
#withenv(()->(eval(M, :(if get(ENV, "TEST", "false") == "true"; foo() = 2; end))),
#    "TEST"=>"true")
#@test 1 == M.foo()
#@test 2 == Base.invokelatest(M.foo)
#end
#
