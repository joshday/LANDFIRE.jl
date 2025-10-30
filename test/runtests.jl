using LANDFIRE, Extents, Test

@testset "LANDFIRE.jl" begin
    @test LANDFIRE.healthcheck().success

    @test length(LANDFIRE.products(product_name="Vegetation")) > 0

    @test length(LANDFIRE.products(product_name = "LANDFIRE Map Zones")) == 1

    @testset "LANDFIRE.download" begin
        ex = Extent(X = (-105.69436f0, -105.052795f0), Y = (39.912888f0, 40.26297f0))
        prods = LANDFIRE.products(product_name = "13 Anderson Fire Behavior Fuel Models 2022")
        @test length(prods) == 1

        file = LANDFIRE.download(prods, ex, every=5)
        @test isfile(file)
    end
end
