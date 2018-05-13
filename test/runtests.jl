using Base.Test

@testset "ApplicationBuilder tests" begin
    Base.invokelatest(include, "ApplicationBuilder.jl")
end
@testset "Test BuildApp (by compiling examples/*.jl)" begin
    include("BuildApp.jl")
end
@testset "Command-line interface (compiling examples/*.jl)" begin
    include("build_app-cli.jl")
end
