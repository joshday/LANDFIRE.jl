module Landfire

using HTTP, JSON3, Extents, Dates, Downloads, StyledStrings
using p7zip_jll: p7zip
import GeoInterface as GI

public healthcheck, products, Job, submit, cancel, status, download, extract, Dataset

#-----------------------------------------------------------------------------# constants
const BASE_URL = "https://lfps.usgs.gov/api"
const HEADER = Dict("Accept" => "application/json", "Content-Type" => "application/json")

#-----------------------------------------------------------------------------# data_dictionary_urls
const LANDFIRE_ATTRIBUTE_TABLES = Dict(
    "FBFM13" => "https://landfire.gov/sites/default/files/CSV/LF2024/LF2024_FBFM13.csv",
    "FBFM40" => "https://landfire.gov/sites/default/files/CSV/LF2024/LF2024_FBFM40.csv",
    "EVT"  => "https://landfire.gov/sites/default/files/CSV/LF2024/LF2024_EVT.csv",
    "EVC"  => "https://landfire.gov/sites/default/files/CSV/LF2024/LF2024_EVC.csv",
    "FVT"  => "https://landfire.gov/sites/default/files/CSV/LF2024/LF2024_FVT.csv",
    "FVC"  => "https://landfire.gov/sites/default/files/CSV/LF2024/LF2024_FVC.csv",
    "FRG"    => "https://landfire.gov/sites/default/files/CSV/LF2024/LF2024_FRG.csv",
    "SCLASS" => "https://landfire.gov/sites/default/files/CSV/LF2024/LF2024_SCLASS.csv",
    "FDIST" => "https://landfire.gov/sites/default/files/CSV/LF2024/LF2024_FDIST.csv",
    "HDIST" => "https://landfire.gov/sites/default/files/CSV/LF2024/LF2024_HDIST.csv",
    "BPS"  => "https://landfire.gov/sites/default/files/CSV/LF2024/LF2024_BPS.csv",
)

#-----------------------------------------------------------------------------# healthcheck
healthcheck() = JSON3.read(HTTP.get("$(BASE_URL)/healthCheck", HEADER).body)

#-----------------------------------------------------------------------------# Products
"""
A struct representing a product in the LANDFIRE API.
- Reference: [https://lfps.usgs.gov/products](https://lfps.usgs.gov/products)
"""
struct Product
    name::String
    theme::String
    layer::String
    version::String
    conus::Bool
    ak::Bool
    hi::Bool
    geoAreas::String
end
function Base.show(io::IO, p::Product)
    print(io, "Product: ", styled"{bright_cyan:$(p.name)} {bright_yellow:$(p.theme)}")
    print(io, styled" {bright_magenta:$(p.layer)}, {bright_black:$(p.version)}")
    for k in (:conus, :ak, :hi)
        getfield(p, k) ? print(io, styled" {bright_green:$(k)}") : print(io, styled" {bright_red:$(k)}")
    end
    print(io, " ", p.geoAreas)
end

include("products.jl")

"""
    products(only_latest=true; kw...)

Filter available LANDFIRE products based on keyword arguments.  Boolean arguments are exact matches.
String arguments use substring matches, e.g. using `name="Vegetation"` will match all
products with "Vegetation" in the product name.  If `only_latest=true` (default), only the most
recent version of each product is returned.
$(join(["- `$k::$v`" for (k,v) in zip(fieldnames(Product), fieldtypes(Product))], "\n"))
"""
function products(only_latest::Bool = true; kw...)
    out = filter(PRODUCTS) do p
        all(kw) do (k, v)
            val = getfield(p, k)
            val isa Bool ? (val == v) : occursin(v, val)
        end
    end
    if only_latest
        versions = Dict{String, Vector{String}}()
        for p in out
            push!(get!(versions, p.name, String[]), p.version)
        end
        filter!(out) do prod
            prod.version == maximum(versions[prod.name]) &&
                !occursin("2019", prod.name) &&
                !occursin("2020", prod.name) &&
                !occursin("2022", prod.name)
        end
    end
    return out
end

"""
    _update_products!!()

Replace the global `PRODUCTS` variable with the latest data from the LANDFIRE API.

If this is required to get latest LANDFIRE products, please open an issue in Landfire.jl.
"""
function _update_products!!()
    url = "$BASE_URL/products"
    response = HTTP.get(url, HEADER)
    obj = JSON3.read(response.body)
    global PRODUCTS = map(obj.products) do x
        Product(x.productName, x.theme, x.layerName, x.version, x.conus, x.ak, x.hi, x.geoAreas)
    end
    sort!(PRODUCTS, by = p -> p.name)
end



#-----------------------------------------------------------------------------# Jobs
@kwdef struct Job
    email::String = haskey(ENV, "LANDFIRE_EMAIL") ? ENV["LANDFIRE_EMAIL"] : error("Please set LANDFIRE_EMAIL environment variable.")
    layers::Vector{Product}
    area_of_interest::String
    output_projection::Union{Nothing, String} = nothing
    resample_resolution::Union{Nothing, Int} = nothing
    edit_rule::Union{Nothing, String} = nothing
    edit_mask::Union{Nothing, String} = nothing
    priority_code::Union{Nothing, String} = nothing
end

Job(layers::Vector{Product}, aoi; kw...) = Job(; layers, area_of_interest = area_of_interest(aoi), kw...)

area_of_interest(x::Integer) = string(x)
area_of_interest(s::String) = s
area_of_interest((; X, Y)::Extents.Extent) = join(string.([X[1], Y[1], X[2], Y[2]]), ' ')
area_of_interest(geom) = area_of_interest(GI.extent(geom))

#-----------------------------------------------------------------------------# submit
"""
    submit(job::Job) --> job_id::String

Submits a job to the LANDFIRE API.  Returns the job ID as a string.
"""
function submit(job::Job)
    url = BASE_URL * "/job/submit"
    body = Dict(
        "Email" => job.email,
        "Layer_List" => join(map(x -> x.layer, job.layers), ';'),
        "Area_of_Interest" => job.area_of_interest,
    )
    isnothing(job.output_projection) || (body["Output_Projection"] = job.output_projection)
    isnothing(job.resample_resolution) || (body["Resample_Resolution"] = job.resample_resolution)
    isnothing(job.edit_rule) || (body["Edit_Rule"] = job.edit_rule)
    isnothing(job.edit_mask) || (body["Edit_Mask"] = job.edit_mask)
    isnothing(job.priority_code) || (body["Priority_Code"] = job.priority_code)
    res = HTTP.post(url, HEADER, JSON3.write(body))
    id = JSON3.read(res.body).jobId
    @info "Job submitted.  View job messages at: https://lfps.usgs.gov/job/$id"
    return id
end

#-----------------------------------------------------------------------------# cancel
"""
    cancel(job_id::String) --> obj::JSON3.Object
Cancels a submitted job.  Returns a JSON3.Object with job details.
"""
function cancel(job_id::String)
    url = BASE_URL * "/job/cancel"
    res = HTTP.get(url, HEADER; query=Dict("JobId" => job_id))
    JSON3.read(res.body)
end

#-----------------------------------------------------------------------------# status
"""
    status(job_id::String) --> obj::JSON3.Object

Queries the status of a submitted job.  Returns a JSON3.Object with job details.
If `obj.status == "Succeeded"`, the output zipfile can be downloaded from URL `obj.outputFile`.
"""
function status(job_id::String)
    url = BASE_URL * "/job/status"
    res = HTTP.get(url, HEADER; query=Dict("JobId" => job_id))
    JSON3.read(res.body)
end

#-----------------------------------------------------------------------------# download
"""
    download(job::Job; every=5, file)
    download(layers::Vector{Product}, area_of_interest; every, file, kw...)

Submits a job for the specified `layers` and `area_of_interest`, then polls the job status every `every` seconds.
When the job completes successfully, downloads and returns the path to the output zipfile.  Keyword arguments are passed to the `Job` constructor.
"""
function download(job::Job; file=tempname() * ".zip", every::Integer=5)
    id = submit(job)
    @info "Submitted job with ID: $id.  Checking job every $every seconds."
    while true
        for i in 1:every
            sleep(1)
            print('.')
        end
        obj = status(id)
        @info "Job Status: $(obj.status)"
        if obj.status == "Succeeded"
            file = Downloads.download(obj.outputFile, file)
            return file
        elseif obj.status == "Failed"
            error("Job failed: $(obj)")
        end
    end
end

download(layers::Vector{Product}, aoi; file=tempname() * ".zip", every = 5, kw...) = download(Job(layers, aoi; kw...); file, every)



function extract(file::AbstractString, dir::AbstractString = tempdir())
    run(`$(p7zip()) x $file -o$dir -y`)
    return dir
end

#-----------------------------------------------------------------------------# Dataset
"""
    Dataset(products::Vector{Product}, aoi; dir=mktempdir(), kw...)

A convenience struct that encapsulates a complete LANDFIRE dataset download and extraction.

- `products`: Vector of `Product` structs to download
- `aoi`: Area of interest (see `Job` constructor for accepted formats)
- `dir`: Directory to extract files to (default: temporary directory)
- `kw...`: Additional keyword arguments passed to the `Job` constructor and `download` function.
"""
struct Dataset
    products::Vector{Product}
    job::Job
    file::String
    dir::String

    function Dataset(products::Vector{Product}, aoi; file=tempname() * ".zip", dir=mktempdir(), every=5, kw...)
        job = Job(products, aoi; kw...)
        file = download(job; every, file)
        dir = extract(file, dir)
        new(products, job, file, dir)
    end
end

function Base.show(io::IO, data::Dataset)
    println(io, styled"{bright_cyan:Landfire.Dataset}")
    println(io, " Area of Interest: ", data.job.area_of_interest)
    for p in data.products
        println(io, " - ", p)
    end
end

files(data::Dataset) = readdir(data.dir; join=true)


end # module
