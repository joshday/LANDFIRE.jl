using LANDFIRE
using Test

@testset "LANDFIRE.jl" begin
    @test LANDFIRE.healthcheck().success

    @test length(LANDFIRE.products(product_name="Vegetation")) > 0
end
