# Basic usage examples for LANDFIRE.jl

using Pkg
Pkg.activate(temp = true)
Pkg.add("OSMGeocoder")
Pkg.develop(path=joinpath(@__DIR__, ".."))

using LANDFIRE, OSMGeocoder

@info "LANDFIRE API up and running?" LANDFIRE.healthcheck()

# Get area of interest
aoi = geocode("Boulder, CO")
@info "Area of Interest: $(aoi[1].display_name)"

# Choose Products
prods = LANDFIRE.products(product_name = "13 Anderson Fire Behavior Fuel Models 2022")
@info "Selected Product: $(prods[1].product_name)"

@info "Downloading data..."
file = LANDFIRE.download(prods, aoi)

@info "Done!  Downloaded file at: $file"
