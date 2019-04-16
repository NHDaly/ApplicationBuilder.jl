using Test

@testset "ApplicationBuilder.jl" begin

# TODO: Make the tests work on Windows and Linux!!! :'(
@static if Sys.isapple()

@testset "Test ApplicationBuilder (by compiling examples/*.jl)" begin
    include("ApplicationBuilder.jl")
end
@testset "Command-line interface (compiling examples/*.jl)" begin
    include("build_app-cli.jl")
end

else  # Windows and Linux

@testset "bundle.jl" begin
    include("bundle.jl")
end

end
end
