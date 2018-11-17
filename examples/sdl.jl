# examples/sdl.jl
#   This is an example of an Application that uses a package containing binary
#   dependencies, in this case SimpleDirectMediaLayer.jl. The binary
#   dependencies need to be provided to ApplicationBuilder at build-time. Please
#   see the associated build file here:
# test/build_examples/sdl.jl
# https://github.com/NHDaly/ApplicationBuilder.jl/tree/master/test/build_examples/sdl.jl

using SimpleDirectMediaLayer
SDL2 = SimpleDirectMediaLayer

using Pkg

fontFile = joinpath(Pkg.dir("SimpleDirectMediaLayer"),
                        "assets","fonts","FiraCode","ttf","FiraCode-Regular.ttf")

# Override SDL libs + assets locations if this script is being compiled for mac .app builds
if get(ENV, "COMPILING_APPLE_BUNDLE", "false") == "true"
    Core.eval(SDL2, :(libSDL2 = "libSDL2.dylib"))
    Core.eval(SDL2, :(libSDL2_ttf = "libSDL2_ttf.dylib"))
    Core.eval(SDL2, :(libSDL2_mixer = "libSDL2_mixer.dylib"))

    fontFile = basename(fontFile)
end

function helloFromSDL()

    SDL2.init()

    win = SDL2.CreateWindow("Hello World!", Int32(100), Int32(100), Int32(300), Int32(400),
    UInt32(SDL2.WINDOW_SHOWN))
    renderer = SDL2.CreateRenderer(win, Int32(-1),
                UInt32(SDL2.RENDERER_ACCELERATED | SDL2.RENDERER_PRESENTVSYNC))

    running = true
    while running
        # Check for quitting
        e = SDL2.event()
        if isa(e, SDL2.QuitEvent)
            running = false
        end

        x,y = Int[1], Int[1]
        SDL2.PumpEvents()
        SDL2.GetMouseState(pointer(x), pointer(y))

        # Set background render color
        SDL2.SetRenderDrawColor(renderer, 200, 200, 200, 255)
        SDL2.RenderClear(renderer)

        # Draw over background
        SDL2.SetRenderDrawColor(renderer, 20, 50, 105, 255)
        SDL2.RenderDrawLine(renderer,0,0,800,600)


        # Create text
        if isfile(fontFile)
            font = SDL2.TTF_OpenFont(fontFile, 14)
            txt = "Hello, world!"
            text = SDL2.TTF_RenderText_Blended(font, txt, SDL2.Color(20,20,20,255))
            tex = SDL2.CreateTextureFromSurface(renderer,text)

            fx,fy = Int[1], Int[1]
            SDL2.TTF_SizeText(font, txt, pointer(fx), pointer(fy))
            fx,fy = fx[],fy[]
            SDL2.RenderCopy(renderer, tex, C_NULL, pointer_from_objref(SDL2.Rect(Int32(10), Int32(10),fx,fy)))
        end

        # Draw on mouse
        rect = SDL2.Rect(x[],y[],50,50)
        SDL2.RenderFillRect(renderer, pointer_from_objref(rect) )

        # Flip screen
        SDL2.RenderPresent(renderer)
        sleep(0.001)
    end
    # Close window
    SDL2.DestroyWindow(win)
    SDL2.Quit()
end

Base.@ccallable function julia_main(args::Vector{String})::Cint
    helloFromSDL()
    return 0
end

#julia_main([""])
