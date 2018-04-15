# Create a temporary .html file, and open it to share the greetings.
Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    tmpdir = mktempdir()
    filename = joinpath(tmpdir, "hello.html")
    open(filename, "w") do io
        write(io, "hello, world\n")
    end
    run(`open file://$filename`)
    return 0
end
