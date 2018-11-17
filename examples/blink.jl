# examples/blink.jl
#   This is an example of an Application that uses a package containing binary
#   dependencies, in this case Blink.jl.
#   When building such an Application, you must provide its dependencies
#   via `-L` and `-R`.
# Build this file with the following command:
# $ julia ~/.julia/v0.6/ApplicationBuilder/build_app.jl \
#      -R ~/.julia/v0.6/Blink/deps/Julia.app \
#      -R ~/.julia/v0.6/Blink/src/AtomShell/main.js \
#      -R ~/.julia/v0.6/Blink/src/content/main.html \
#      -R ~/.julia/v0.6/Blink/res \
#      -L ~/.julia/v0.6/HttpParser/deps/usr/lib/libhttp_parser.dylib \
#      -L ~/.julia/v0.6/MbedTLS/deps/usr/lib/libmbedcrypto.2.7.1.dylib \
#      examples/blink.jl "HelloBlink"

using Blink

# In order to distribute this Application, we've copied all its dependencies
# into the .app bundle via the -R and -L build flags.
# Now, here, we have to update the Packages that use those dependencies to find
# them in the right place. These changes take place at compile time. We override
# the paths to all be relative paths, so that the app bundle can be moved.
if get(ENV, "COMPILING_APPLE_BUNDLE", "false") == "true"
    println("Overriding Blink dependency paths.")
    println("Overriding Blink dependency paths.")
    Core.eval(Blink.AtomShell, :(_electron = "Julia.app/Contents/MacOS/Julia"))
    Core.eval(Blink.AtomShell, :(mainjs = "main.js"))
    Core.eval(Blink, :(buzz = "main.html"))
    Core.eval(Blink, :(resources = Dict("spinner.css" => "res/spinner.css",
                             "blink.js" => "res/blink.js",
                             "blink.css" => "res/blink.css",
                             "reset.css" => "res/reset.css")))
    # Clear out Blink.__inits__, since it will attempt to evaluate hardcoded paths.
    # (We've defined all the variables manually, above: `resources` and `port`.)
    Core.eval(Blink, :(empty!(__inits__)))

    Core.eval(Blink.Mux.HTTP.MbedTLS, :(const libmbedcrypto = basename(libmbedcrypto)))

#    WebSockets = Blink.WebSockets
#    Core.eval(WebSockets, :(using HttpServer))  # needed to cause @require lines to execute & compile
#    Core.eval(WebSockets,
#        :(include(joinpath(Pkg.dir("WebSockets"),"src/HttpServer.jl"))))  # Manually load this from the @requires line.

    println("Done changing dependencies.")
end

# Simple HTML example: "Hello" with an input field to change name being greeted.
html() = """
    Hello, <span id=namespan>World</span>! -- Love, Blink.
    <br><br>Type a new name and press enter: <input id="nameentry"></input>
    <script>
      nameEntry = document.getElementById("nameentry")
      function setName(name) { document.getElementById("namespan").innerText = name }
    </script>
 """

function helloFromBlink()
    # Set Blink port randomly before anything else.
    Blink.port[] = get(ENV, "BLINK_PORT", rand(2_000:10_000))

    # Create Blink window and load HTML.
    win = Blink.Window(Blink.shell(), Dict(:width=>850)); sleep(5.0)
    Blink.body!(win, html(); fade=false) ; sleep(1)
    Blink.tools(win)
    sleep(2)  # wait for js to initialize

    # Example javascript interaction.
    Blink.@js_ win console.log("HELLO!")
    cwd_str = "pwd(): $(pwd())"
    Blink.@js_ win console.log($cwd_str)
    Blink.@js_ win setName("Nathan")  # Calling a js function.

    # Set up the js to call a julia callback that calls back to js! haha :)
    # (This could be all done within js, but it's fun to see the full round trip.)
    Blink.handlers(win)["changeNameJulia"] = (n) -> (println("msg from js: $n"); Blink.@js_ win setName($n))
    # Set the input field to call the above julia callback when it's changed.
    Blink.@js_ win nameEntry.onchange = (e) -> (Blink.msg("changeNameJulia", nameEntry.value); console.log("sent msg to julia!"); e.returnValue=false)

    while Blink.active(win)
        sleep(1)
    end
end

Base.@ccallable function julia_main(args::Vector{String})::Cint
    # Apparently starting Electron too quickly means the OS doesn't get a
    # chance to find the name of the application...
    sleep(2)

    helloFromBlink()
    return 0
end
