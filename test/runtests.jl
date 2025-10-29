using LANDFIRE
using Test

@testset "LANDFIRE.jl" begin
    @testset "Client Creation" begin
        # Test default client
        client = LANDFIREClient()
        @test client.base_url == "https://lfps.usgs.gov/api"
        @test haskey(client.headers, "Accept")
        @test client.headers["Accept"] == "application/json"

        # Test custom client
        custom_client = LANDFIREClient("https://custom.url", headers=Dict("Custom" => "Header"))
        @test custom_client.base_url == "https://custom.url"
        @test haskey(custom_client.headers, "Custom")
        @test haskey(custom_client.headers, "Accept")
    end

    @testset "API Functions" begin
        # These tests require network access and will only work if the API is available
        # You may want to skip these in CI or mock the HTTP responses

        if get(ENV, "LANDFIRE_SKIP_NETWORK_TESTS", "false") != "true"
            client = LANDFIREClient()

            @testset "Health Check" begin
                try
                    result = healthcheck(client)
                    @test result !== nothing
                    println("Health check result: ", result)
                catch e
                    @warn "Health check failed (this is expected if API is unavailable)" exception=e
                end
            end

            @testset "Get Products" begin
                try
                    products = get_products(client)
                    @test products !== nothing
                    println("Products retrieved: ", length(products))
                catch e
                    @warn "Get products failed (this is expected if API is unavailable)" exception=e
                end
            end
        else
            @info "Skipping network tests (LANDFIRE_SKIP_NETWORK_TESTS=true)"
        end
    end

    @testset "Function Interfaces" begin
        # Test that functions accept correct arguments without calling the API
        client = LANDFIREClient()

        # These just test that the function signatures are correct
        @test applicable(healthcheck, client)
        @test applicable(get_products, client)
        @test applicable(submit_job, client, Dict("test" => "param"))
        @test applicable(get_job_status, client, "job123")
        @test applicable(cancel_job, client, "job123")
    end
end
