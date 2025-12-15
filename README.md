# Landfire.jl

[![Build Status](https://github.com/joshday/Landfire.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/joshday/Landfire.jl/actions/workflows/CI.yml?query=branch%3Amain)

A Julia client for the [Landfire Product Service API](https://lfps.usgs.gov/docs/api).

## Quickstart

- The LANDFIRE API requires an email address.
- Consider adding `ENV["LANDFIRE_EMAIL"] = <my email>` to `~/.julia/config/startup.jl`

```julia
using Landfire, OSMGeocoder

# Check that API is running:
Landfire.healthcheck()

# Get area of interest:
area = geocode("Boulder, CO")

# Choose Product(s):
prods = Landfire.products(name = "Fire Behavior Fuel Models")

# Get Dataset
data = Landfire.Dataset(prods, area)

# See what was downloaded:
files = Landfire.files(data)

# For low level usage (submitting Jobs, etc.), see the source code
```

## API

### `products(latest=true; kw...)`

Filter available Landfire products based on keyword arguments. Boolean arguments are exact matches. String arguments use substring matches, e.g. using name="Vegetation" will match all products with "Vegetation" in the product name.  For `latest=true`, only the latest version of each product is returned.


| Keyword | Description |
|---------|-------------|
`name` | Spoken name of layer

-  `name::String`
-  `theme::String`
-  `layer::String`
-  `version::String`
-  `conus::Bool` (available for contiguous US states?)
-  `ak::Bool` (available for Alaska?)
-  `hi::Bool`: (available for Hawaii?)
-  `geoAreas::String`
