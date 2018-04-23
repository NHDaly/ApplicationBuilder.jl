using ApplicationBuilder
using Base.Test

@testset "change_dir_if_bundle" begin
global PROGRAM_FILE
global ENV

@testset "Don't change dir if not compiled." begin
global PROGRAM_FILE
PROGRAM_FILE = ""  # PROGRAM_FILE isn't in an app.
ENV["COMPILING_APPLE_BUNDLE"] = "false"  # Code isn't being compiled for an app.
reload("ApplicationBuilder")  # redefine function after changing ENV
cwd = pwd()
@test cwd == ApplicationBuilder.change_dir_if_bundle()
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

# Test
eval(Base, :(PROGRAM_FILE = $tmpAppExe))
ENV["COMPILING_APPLE_BUNDLE"] = "true"  # Code *is* being compiled
reload("ApplicationBuilder")  # redefine function after changing ENV
cwd = pwd()
# Verify we changed directory
@test cwd != ApplicationBuilder.change_dir_if_bundle()
@test Base.Filesystem.samefile(tmpAppResources, pwd())
end
end
