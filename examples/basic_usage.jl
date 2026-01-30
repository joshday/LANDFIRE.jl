# Basic usage examples for Landfire.jl

using Landfire

# Check API health
@info "Landfire API health check" Landfire.healthcheck()

# Browse available products
prods = Landfire.products()  # All latest products (cached)
@info "Total products available: $(length(prods))"

# Filter products
fuel_prods = Landfire.products(theme="Fuel", conus=true)
@info "Fuel products for CONUS: $(length(fuel_prods))"

# Select a specific product (FBFM13 - Fire Behavior Fuel Model)
fbfm13 = Landfire.products(layer="FBFM13", conus=true)
@info "Selected product:" fbfm13

# Define area of interest (Boulder, CO area)
# Format: "xmin ymin xmax ymax" in WGS84
aoi = "-105.5 39.9 -105.2 40.1"

# Create a Dataset (lazy - doesn't download yet)
data = Landfire.Dataset(fbfm13, aoi)
@info "Dataset created" data

# Download and extract (this makes the API call)
# Uncomment to actually download:
# tif_file = get(data)
# @info "Downloaded to:" tif_file
# @info "All files:" Landfire.files(data)

# Get attribute table for interpreting raster values
table = Landfire.attribute_table("FBFM13")
@info "Attribute table has $(length(table)) entries"
@info "First entry:" table[1]

# Full product download URLs (for large regional downloads)
url = Landfire.full_product_url("FBFM13", "CONUS", 2024)
size = Landfire.filesize(url)
@info "Full CONUS FBFM13 download" url Base.format_bytes(size)
