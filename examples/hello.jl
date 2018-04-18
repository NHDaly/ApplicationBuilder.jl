#  Need this block until this is resolved: https://github.com/JuliaLang/PackageCompiler.jl/issues/47
if VERSION < v"0.7"
    try
        JULIA_HOME
    catch
        warn("JULIA_HOME is not defined, initializing manually")
        Sys.__init__()
        Base.early_init()
        JULIA_HOME
    end
end


foo() = ARGS

# Create a temporary .html file, and open it to share the greetings.
Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    cmd_strings = Base.shell_split(string(Base.julia_cmd()))
    println("cmd_strings: $cmd_strings")

    println("PROGRAM_FILE: $PROGRAM_FILE")
    println("foo: $(foo())")

    tmpdir = mktempdir()
    filename = joinpath(tmpdir, "hello.html")
    open(filename, "w") do io
        write(io, "hello, world\n")
        write(io, "pwd: $(pwd())\n")
        write(io, "ARGS: $ARGS\n")
    end
    run(`open file://$filename`)
    return 0
end
