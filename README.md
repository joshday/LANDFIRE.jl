# Landfire.jl

[![Build Status](https://github.com/RallypointOne/Landfire.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/RallypointOne/Landfire.jl/actions/workflows/CI.yml?query=branch%3Amain)

A Julia client for the [LANDFIRE Product Service API](https://lfps.usgs.gov/docs/api).

## Quickstart

The LANDFIRE API requires an email address. Set it via environment variable:

```julia
ENV["LANDFIRE_EMAIL"] = "your@email.com"
```

Consider adding this to `~/.julia/config/startup.jl` for persistence.

```julia
using Landfire

# Check that API is running
Landfire.healthcheck()

# Browse available products
prods = Landfire.products()                    # All latest products
prods = Landfire.products(theme="Fuel")        # Filter by theme
prods = Landfire.products(layer="FBFM13")      # Filter by layer name
prods = Landfire.products(conus=true, ak=false) # CONUS only

# Create a Dataset for an area of interest
data = Landfire.Dataset(prods, "-105.5 39.5 -105.0 40.0")  # xmin ymin xmax ymax

# Download and extract (results are cached)
tif_file = get(data)

# List all extracted files
Landfire.files(data)

# Get attribute table for a layer
table = Landfire.attribute_table("FBFM13")
```

## API Reference

### Products

#### `products(latest=true; kw...) -> Vector{Product}`

Fetch and filter available products from the LANDFIRE API.

**Keyword Arguments** - Filter by field values. Boolean fields use exact matching, string fields use substring matching:
- `name::String` - Product name
- `theme::String` - Theme (e.g., "Fuels", "Vegetation")
- `layer::String` - Layer name (e.g., "FBFM13", "EVT")
- `version::String` - Version string
- `conus::Bool` - Available for contiguous US?
- `ak::Bool` - Available for Alaska?
- `hi::Bool` - Available for Hawaii?
- `geoAreas::String` - Geographic areas

### Dataset

#### `Dataset(products, aoi; kw...)`

Create a Dataset struct for downloading LANDFIRE data. Does not download immediately - call `get(data)` to fetch.

- `products`: Vector of `Product` structs
- `aoi`: Area of interest - can be:
  - String: `"xmin ymin xmax ymax"` bounds or WKT
  - Integer: Feature ID
  - `Extents.Extent`: Bounding box
  - Any geometry with `GeoInterface.extent`

#### `get(data::Dataset; every=5, timeout=3600)`

Download and extract the dataset. Returns the path to the `.tif` file. Results are cached in scratchspace.

#### `files(data::Dataset)`

Return paths to all files in the extracted dataset directory.

### Attribute Tables

#### `attribute_table(layer::String, year=2024)` / `attribute_table(product::Product)`

Download and parse a LANDFIRE attribute table CSV. Returns a vector of `NamedTuple`s.

```julia
table = Landfire.attribute_table("FBFM13")
# table[1] = (VALUE = "-9999", FBFM13 = "Fill-NoData", R = "255", ...)
```

### Low-Level API

#### `Job(products, aoi; kw...)`

Create a job for the LANDFIRE API. Keyword arguments:
- `output_projection`: Output projection (e.g., "EPSG:4326")
- `resample_resolution`: Resample resolution in meters
- `edit_rule`, `edit_mask`, `priority_code`: Advanced options

#### `submit(job::Job) -> job_id`

Submit a job to the API. Returns the job ID.

#### `status(job_id::String)`

Query job status. Returns a JSON object with `status` field ("Succeeded", "Failed", etc.).

#### `cancel(job_id::String)`

Cancel a submitted job.

#### `download(job::Job; every=5, timeout=3600, file=...)`

Submit, poll, and download a job result. Returns path to the zip file.

#### `extract(file, dir=tempdir())`

Extract a 7zip archive to a directory.

#### `healthcheck()`

Check if the LANDFIRE API is running.
