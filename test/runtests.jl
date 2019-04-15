using Test

# TODO: Make the tests work on Windows and Linux!!! :'(
@static if Sys.isapple()

@testset "ApplicationBuilder.jl" begin
@testset "Test ApplicationBuilder (by compiling examples/*.jl)" begin
    include("ApplicationBuilder.jl")
end
@testset "Command-line interface (compiling examples/*.jl)" begin
    include("build_app-cli.jl")
end
end

end
