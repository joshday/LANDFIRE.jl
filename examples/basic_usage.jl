# Basic usage examples for Landfire.jl

using Pkg
Pkg.activate(temp = true)
Pkg.add("OSMGeocoder")
Pkg.develop(path=joinpath(@__DIR__, ".."))

using Landfire, OSMGeocoder

@info "Landfire API up and running?" Landfire.healthcheck()

# Get area of interest
area = geocode("Boulder, CO")
@info "Area of Interest: $(area[1].display_name)"

# Choose Products
prods = Landfire.products(product_name = "13 Anderson Fire Behavior Fuel Models 2022")
@info "Selected Product: $(prods[1].product_name)"

@info "Downloading data..."
file = Landfire.download(prods, area)

@info "Done!  Downloaded file at: $file"
