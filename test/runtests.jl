using Landfire, Extents, Test

@testset "Landfire.jl" begin
    @test Landfire.healthcheck().success

    Landfire._update_products!!()

    @test length(Landfire.products(product_name="Vegetation")) > 0

    @test length(Landfire.products(product_name = "LANDFIRE Map Zones")) == 1

    # Service is not reliabile enough to run this regularly:

    # @testset "Landfire.download" begin
    #     ex = Extent(X = (-105.69436f0, -105.052795f0), Y = (39.912888f0, 40.26297f0))
    #     prods = Landfire.products(product_name = "13 Anderson Fire Behavior Fuel Models 2022")
    #     @test length(prods) == 1

    #     file = Landfire.download(prods, ex, every=5)
    #     @test isfile(file)
    # end
end
