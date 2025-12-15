using Landfire, HTTP, Extents, Test

@testset "Landfire.jl" begin

    @testset "Product struct" begin
        p = Landfire.Product("Test Product", "TestTheme", "TestLayer", "1.0.0", true, false, true, "US")
        @test p.name == "Test Product"
        @test p.theme == "TestTheme"
        @test p.layer == "TestLayer"
        @test p.version == "1.0.0"
        @test p.conus == true
        @test p.ak == false
        @test p.hi == true
        @test p.geoAreas == "US"

        # Test show method doesn't error
        io = IOBuffer()
        show(io, p)
        @test length(String(take!(io))) > 0
    end

    @testset "products() filtering" begin
        # Test basic filtering
        @test length(Landfire.products(name = "Vegetation")) > 0
        @test length(Landfire.products(name = "LANDFIRE Map Zones")) == 1
        @test length(Landfire.products(false)) > length(Landfire.products(true))

        # Test theme filtering
        fuel_products = Landfire.products(theme = "Fuels")
        @test all(p -> occursin("Fuels", p.theme), fuel_products)

        # Test boolean filtering (exact match)
        conus_only = Landfire.products(conus = true, ak = false, hi = false)
        @test all(p -> p.conus && !p.ak && !p.hi, conus_only)

        # Test version filtering
        v250_products = Landfire.products(version = "2.5.0")
        @test all(p -> p.version == "2.5.0", v250_products)

        # Test layer filtering
        @test length(Landfire.products(layer = "FBFM13")) > 0

        # Test multiple filters
        veg_latest = Landfire.products(true, theme = "Vegetation")
        @test all(p -> occursin("Vegetation", p.theme), veg_latest)

        # Test only_latest flag
        all_fbfm13 = Landfire.products(false, layer = "FBFM13")
        latest_fbfm13 = Landfire.products(true, layer = "FBFM13")
        @test length(all_fbfm13) >= length(latest_fbfm13)
    end

    @testset "area_of_interest" begin
        # Test Integer input
        @test Landfire.area_of_interest(123) == "123"

        # Test String input
        @test Landfire.area_of_interest("test") == "test"

        # Test Extent input
        ext = Extents.Extent(X = (-120.0, -110.0), Y = (35.0, 40.0))
        aoi = Landfire.area_of_interest(ext)
        @test aoi == "-120.0 35.0 -110.0 40.0"
    end

    @testset "Job construction" begin
        prods = Landfire.products(layer = "250FBFM13")
        @test length(prods) > 0

        # Test Job construction with Extent
        ext = Extents.Extent(X = (-120.0, -110.0), Y = (35.0, 40.0))
        job = Landfire.Job(prods, ext)
        @test job.layers == prods
        @test job.area_of_interest == "-120.0 35.0 -110.0 40.0"
        @test isnothing(job.output_projection)
        @test isnothing(job.resample_resolution)

        # Test Job construction with keyword arguments
        job2 = Landfire.Job(prods, ext, output_projection = "EPSG:4326", resample_resolution = 30)
        @test job2.output_projection == "EPSG:4326"
        @test job2.resample_resolution == 30

        # Test Job construction with String AOI
        job3 = Landfire.Job(prods, "123")
        @test job3.area_of_interest == "123"

        # Test Job construction with Integer AOI
        job4 = Landfire.Job(prods, 456)
        @test job4.area_of_interest == "456"
    end

    @testset "Constants" begin
        # Test LANDFIRE_ATTRIBUTE_TABLES is populated
        @test length(Landfire.LANDFIRE_ATTRIBUTE_TABLES) > 0
        @test haskey(Landfire.LANDFIRE_ATTRIBUTE_TABLES, "FBFM13")
        @test haskey(Landfire.LANDFIRE_ATTRIBUTE_TABLES, "EVT")
        @test all(v -> startswith(v, "https://"), values(Landfire.LANDFIRE_ATTRIBUTE_TABLES))

        # Test BASE_URL is correct
        @test Landfire.BASE_URL == "https://lfps.usgs.gov/api"
    end

    @testset "PRODUCTS availability" begin
        # Test PRODUCTS is loaded and non-empty
        @test length(Landfire.PRODUCTS) > 0
        @test all(p -> p isa Landfire.Product, Landfire.PRODUCTS)

        # Test PRODUCTS are sorted by name
        names = [p.name for p in Landfire.PRODUCTS]
        @test issorted(names)
    end

end
