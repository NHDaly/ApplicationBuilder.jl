using ApplicationBuilder

# Create a temporary .html file, and open it to share the greetings.
Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    ApplicationBuilder.change_dir_if_bundle()

    tmpdir = mktempdir()
    filename = joinpath(tmpdir, "hello.html")
    open(filename, "w") do io
        write(io, "Hello, World!\n")
        write(io, "<br>    -- Love, $PROGRAM_FILE\n")
        write(io, """<br><br>Current working directory: <a href="file://$(pwd())">$(pwd())</a>\n""")
    end
    run(`open file://$filename`)
    return 0
end
