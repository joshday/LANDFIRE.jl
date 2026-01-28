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

    @testset "products() function" begin
        # Test fetching products from API
        all_products = Landfire.products(false)
        @test length(all_products) > 0
        @test all(p -> p isa Landfire.Product, all_products)

        # Test latest filtering returns fewer products
        latest_products = Landfire.products(true)
        @test length(latest_products) > 0
        @test length(all_products) >= length(latest_products)

        # Test products are sorted by name
        names = [p.name for p in latest_products]
        @test issorted(names)
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
        # Create a test product
        p = Landfire.Product("Test", "Theme", "250FBFM13", "1.0.0", true, false, false, "US")
        prods = [p]

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
        # Test attribute_table_url function
        @test length(Landfire.LAYERS) > 0
        @test "FBFM13" in Landfire.LAYERS
        @test "EVT" in Landfire.LAYERS
        @test startswith(Landfire.attribute_table_url("FBFM13"), "https://")
        @test Landfire.attribute_table_url("FBFM13", 2024) == "https://www.landfire.gov/sites/default/files/CSV/2024/LF2024_FBFM13.csv"
        @test Landfire.attribute_table_url("EVT", 2023) == "https://www.landfire.gov/sites/default/files/CSV/2023/LF2023_EVT.csv"

        # Test BASE_URL is correct
        @test Landfire.BASE_URL == "https://lfps.usgs.gov/api"
    end

    @testset "Dataset construction" begin
        # Create a test product and Dataset
        p = Landfire.Product("Test", "Theme", "250FBFM13", "1.0.0", true, false, false, "US")
        prods = [p]
        ext = Extents.Extent(X = (-120.0, -110.0), Y = (35.0, 40.0))

        data = Landfire.Dataset(prods, ext)

        # Test Dataset fields are set correctly
        @test data.products == prods
        @test data.job.layers == prods
        @test data.job.area_of_interest == "-120.0 35.0 -110.0 40.0"

        # Test paths are set based on job hash
        h = hash(data.job)
        @test endswith(data.file, "job_$h.zip")
        @test endswith(data.dir, "job_$h")

        # Test show method doesn't error
        io = IOBuffer()
        show(io, data)
        @test length(String(take!(io))) > 0
    end

    @testset "Dataset caching" begin
        # Create a Dataset with a unique AOI to avoid conflicts
        p = Landfire.Product("CacheTest", "Theme", "250FBFM13", "1.0.0", true, false, false, "US")
        ext = Extents.Extent(X = (-99.0, -98.0), Y = (30.0, 31.0))
        data = Landfire.Dataset([p], ext)

        # Create a mock cached directory with a .tif file
        mkpath(data.dir)
        tif_path = joinpath(data.dir, "test_layer.tif")
        write(tif_path, "mock tif data")

        try
            # First call should use cached directory and log the cache message
            result1 = @test_logs (:info, "Using cached directory: $(data.dir)") get(data)
            @test result1 == tif_path

            # Second call should also log the cache message
            result2 = @test_logs (:info, "Using cached directory: $(data.dir)") get(data)
            @test result1 == result2
        finally
            # Clean up
            rm(data.dir; recursive=true, force=true)
        end
    end

end
