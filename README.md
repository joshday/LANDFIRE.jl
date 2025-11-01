# Landfire.jl

[![Build Status](https://github.com/joshday/Landfire.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/joshday/Landfire.jl/actions/workflows/CI.yml?query=branch%3Amain)

A Julia client for the [Landfire Product Service API](https://lfps.usgs.gov/docs/api).

## Quickstart

```julia
using Landfire, OSMGeocoder

# Check that API is running:
Landfire.healthcheck()

# Get area of interest:
area = geocode("Boulder, CO")

# Choose Product(s):
prods = Landfire.products(product_name = "13 Anderson Fire Behavior Fuel Models 2022")

# Download .zip file:
file = Landfire.download(prods, area)
```

## API

### `products(; kw...)`

Filter available Landfire products based on keyword arguments. Boolean arguments are exact matches. String arguments use substring matches, e.g. using product_name="Vegetation" will match all products with "Vegetation" in the product name.

-  `product_name::String`
-  `theme::String`
-  `layer_name::String`
-  `version::String`
-  `conus::Bool`
-  `ak::Bool`
-  `hi::Bool`
-  `geoAreas::String`

### `download(layers, area_of_interest; every=5, kw...)`

Submits a job to the Landfire API where:

- `layers::Vector{Product}`
- `area_of_interest` can be one of `String`/`Integer` (inserted verbatim), an `Extents.Extent`, or a GeoInterface-compatible geometry.

This function is blocking.  To run simultaneous jobs, you'll need to use the lower level `Job` struct and `submit` function.
