# A super-simple command line program that just prints hello.
# Build this with the `commandline_app=true` flag in `BuildApp.build_app_bundle`.

Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    println("Oh hi, World!")
    println("Current working directory: $(pwd())")
    return 0
end
