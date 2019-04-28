# Create a temporary .html file, and open it to share the greetings.
Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    tmpdir = mktempdir()
    filename = joinpath(tmpdir, "hello.html")
    open(filename, "w") do io
        println(io, "Hello, World!")
        println(io, "<br>    -- Love, $PROGRAM_FILE")
        println(io, """<br><br>Current working directory: <a href="file://$(pwd())">$(pwd())</a>""")
        @show Main.ApplicationBuilderUtils
        @show Main.ApplicationBuilderUtils.cd_to_bundle_resources
        Main.ApplicationBuilderUtils.cd_to_bundle_resources()
        println(io, """<br><br>After cd to resources directory: <a href="file://$(pwd())">$(pwd())</a>""")
    end
    run(`open file://$filename`)
    return 0
end
