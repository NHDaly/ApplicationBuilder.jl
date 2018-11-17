using Test

@testset "Test ApplicationBuilder (by compiling examples/*.jl)" begin
    include("ApplicationBuilder.jl")
end
@testset "Command-line interface (compiling examples/*.jl)" begin
    include("build_app-cli.jl")
end
