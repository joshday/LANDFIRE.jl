using Test, Landfire


@test Landfire.healthcheck().success

Landfire._update_products!!()

@testset "Attribute Tables" begin
    for (k, v) in Landfire.LANDFIRE_ATTRIBUTE_TABLES
        url = v
        res = HTTP.get(url)
        @test res.status == 200
    end
end
