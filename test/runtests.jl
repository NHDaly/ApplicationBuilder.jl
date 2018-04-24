using Base.Test

@testset "ApplicationBuilder tests" begin
    Base.invokelatest(include, "ApplicationBuilder.jl")
end
@testset "Compiling examples/*.jl" begin
    include("examples.jl")
end
