# A super-simple command line program that just prints hello.
# Build this with the `commandline_app=true` flag in `ApplicationBuilder.build_app_bundle`.

Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    println("Hi what's your name?")
    name = readline()
    println("Oh hi, $name. It's a pleasure to meet you.")
    println("By the way, here's the current working directory:\n'$(pwd())'")

    println("\nGoodbye! (Press enter to exit)")
    readline()
    return 0
end
