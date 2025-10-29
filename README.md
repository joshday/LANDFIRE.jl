# LANDFIRE.jl

[![Build Status](https://github.com/joshday/LANDFIRE.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/joshday/LANDFIRE.jl/actions/workflows/CI.yml?query=branch%3Amain)

A Julia client for the [LANDFIRE Product Service API](https://lfps.usgs.gov/docs/api).

## Overview

LANDFIRE.jl provides a convenient Julia interface to access LANDFIRE (Landscape Fire and Resource Management Planning Tools) data products through the USGS LANDFIRE Product Service API. LANDFIRE offers comprehensive geospatial data describing vegetation, wildland fuel, and fire regimes across the United States.

## Installation

```julia
using Pkg
Pkg.add("LANDFIRE")
```

Or for development:

```julia
using Pkg
Pkg.develop("LANDFIRE")
```

## Quick Start

```julia
using LANDFIRE

# Create a client
client = LANDFIREClient()

# Check API health
status = healthcheck(client)

# Get available products
products = get_products(client)

# Submit a job
params = Dict(
    "product" => "140CC",
    "aoi" => "POLYGON((-120 40, -119 40, -119 41, -120 41, -120 40))"
)
job = submit_job(client, params, method=:POST)

# Check job status
status = get_job_status(client, job.jobId)

# Cancel a job if needed
cancel_job(client, job.jobId)
```

## API Reference

### Client

```julia
LANDFIREClient(base_url="https://lfps.usgs.gov/api"; headers=Dict{String,String}())
```

Create a LANDFIRE API client. By default, connects to the production API endpoint.

**Arguments:**
- `base_url`: Base URL for the API (optional)
- `headers`: Custom HTTP headers to include with requests (optional)

### Functions

#### `healthcheck(client::LANDFIREClient)`

Check the health status of the LANDFIRE API.

**Returns:** Health check response from the API

#### `get_products(client::LANDFIREClient)`

Retrieve the list of available LANDFIRE products.

**Returns:** Array of available products with their metadata

#### `submit_job(client::LANDFIREClient, job_params::Dict; method::Symbol=:GET)`

Submit a job to process LANDFIRE data.

**Arguments:**
- `job_params`: Dictionary containing job parameters such as:
  - `product`: Product code (e.g., "140CC")
  - `aoi`: Area of interest (WKT polygon or shapefile reference)
  - Other product-specific parameters
- `method`: HTTP method to use (`:GET` or `:POST`, default: `:GET`)

**Returns:** Job submission response containing job ID and initial status

#### `get_job_status(client::LANDFIREClient, job_id::String; method::Symbol=:GET)`

Get the status of a submitted job.

**Arguments:**
- `job_id`: Job identifier returned from `submit_job`
- `method`: HTTP method to use (`:GET` or `:POST`, default: `:GET`)

**Returns:** Job status information including progress and download links when complete

#### `cancel_job(client::LANDFIREClient, job_id::String)`

Cancel a running job.

**Arguments:**
- `job_id`: Job identifier to cancel

**Returns:** Cancellation confirmation response

#### `upload_shapefile(client::LANDFIREClient, shapefile_path::String)`

Upload a shapefile to define an area of interest.

**Arguments:**
- `shapefile_path`: Path to a zipped shapefile (.zip containing .shp, .shx, .dbf, etc.)

**Returns:** Upload response containing a reference ID for use in job submissions

## Example Workflow

```julia
using LANDFIRE

# Initialize client
client = LANDFIREClient()

# Check available products
products = get_products(client)
println("Available products: ", length(products))

# Option 1: Submit job with WKT polygon
job_params = Dict(
    "product" => "140CC",
    "aoi" => "POLYGON((-120.5 40.0, -119.5 40.0, -119.5 41.0, -120.5 41.0, -120.5 40.0))",
    "projection" => "EPSG:4326"
)
job = submit_job(client, job_params, method=:POST)
println("Job submitted: ", job.jobId)

# Option 2: Submit job with uploaded shapefile
shapefile_ref = upload_shapefile(client, "path/to/aoi.zip")
job_params = Dict(
    "product" => "140CC",
    "aoiReference" => shapefile_ref.id
)
job = submit_job(client, job_params, method=:POST)

# Monitor job status
while true
    status = get_job_status(client, job.jobId)
    println("Status: ", status.status)

    if status.status == "completed"
        println("Download URL: ", status.downloadUrl)
        break
    elseif status.status == "failed"
        println("Job failed: ", status.error)
        break
    end

    sleep(5)  # Wait 5 seconds before checking again
end
```

## Testing

Run the test suite:

```julia
using Pkg
Pkg.test("LANDFIRE")
```

To skip network tests (useful in CI environments):

```bash
export LANDFIRE_SKIP_NETWORK_TESTS=true
julia --project -e 'using Pkg; Pkg.test()'
```

## Resources

- [LANDFIRE Product Service API Documentation](https://lfps.usgs.gov/docs/api)
- [LANDFIRE Homepage](https://landfire.gov/)
- [LANDFIRE Products](https://lfps.usgs.gov/products)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See [LICENSE](LICENSE) file for details.
