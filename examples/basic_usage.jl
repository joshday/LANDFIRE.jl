# Basic usage examples for Landfire.jl

using Landfire, OSMGeocoder

@info "Landfire API up and running?" Landfire.healthcheck()

# Get area of interest
area = geocode(city="Boulder", state="CO")
@info "Area of Interest: $(area[1].display_name)"

# Choose Products
# See Landfire.products() for full list
prods = Landfire.products(layer = "250FBFM13", conus=true)
@info "Selected Product: $(prods[1].name)"


@info "Retrieving data"
data = Landfire.Dataset(prods, area)

@info "Files downloaded" Landfire.files(data)
