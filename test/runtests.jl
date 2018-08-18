using Compat
using Compat.Test

@static if Compat.Sys.isapple()
    @testset "Test ApplicationBuilder (by compiling examples/*.jl)" begin
    include("ApplicationBuilder.jl")
    end
    @testset "Command-line interface (compiling examples/*.jl)" begin
    include("build_app-cli.jl")
    end
else
    include("bundle-windows.jl")
end
