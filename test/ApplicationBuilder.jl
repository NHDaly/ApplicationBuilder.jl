using Base.Test

# Test that change_dir_if_bundle actually changes behavior based on ENV variable
# set up fake .App
tmpdir = mktempdir()
tmpAppResources = joinpath(tmpdir, "Tmp.app/Contents/Resources")
tmpAppMacOS = joinpath(tmpdir, "Tmp.app/Contents/MacOS")
tmpAppExe = joinpath(tmpdir, "Tmp.app/Contents/MacOS/tmp")
mkpath(tmpAppMacOS)
mkpath(tmpAppResources)

# Set up test script. (Must be run as a separate process to allow the ENV
# variable to generate different code at compile-time.)
testScript = joinpath(tmpdir, "test.jl")
write(testScript, """
        # ApplicationBuilder expects to be inside an App structure.
        eval(Base, :(PROGRAM_FILE = "$tmpAppExe"))
        # change_dir_if_bundle() will be differently based on the ENV variable.
        using ApplicationBuilder; ApplicationBuilder.App.change_dir_if_bundle(); println(pwd());
    """)

# Without ENV variable set, it should do nothing.
@test pwd() == readlines(`julia $testScript`)[end]
# With the ENV variable false, it should do nothing.
@test pwd() == withenv(()->(readlines(`julia $testScript`)[end]),
             "COMPILING_APPLE_BUNDLE"=>"false")  # Code is not being compiled.

# With COMPILING_APPLE_BUNDLE == true, the dir should change since it thinks the
# code is being compiled as an app.
@test pwd() != withenv(()->(readlines(`julia $testScript`)[end]),
             "COMPILING_APPLE_BUNDLE"=>"true")  # Code is not being compiled.
