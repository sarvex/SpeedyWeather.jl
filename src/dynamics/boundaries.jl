"""Concrete struct that holds orography in grid-point space and surface geopotential in
spectral space."""
struct Orography{NF<:AbstractFloat,Grid<:AbstractGrid{NF}}
    orography::Grid                                 # height [m]
    geopot_surf::LowerTriangularMatrix{Complex{NF}} # surface geopotential, height*gravity [m²/s²]
end

"""Zonal ridge orography after Jablonowski and Williamson 2006."""
Base.@kwdef struct ZonalRidge <: AbstractOrography
    η₀ = 0.252      # conversion from σ to Jablonowski's ηᵥ-coordinates
    u₀ = 35         # max amplitude of zonal wind [m/s] that scales orography height
end

# empty structs (no parameters needed) for other orographies
struct EarthOrography <: AbstractOrography end
struct NoOrography <: AbstractOrography end

function Base.zeros(::Type{Orography},S::SpectralTransform{NF}) where NF
    @unpack Grid, nlat_half, lmax, mmax = S
    orography   = zeros(Grid{NF},nlat_half)
    geopot_surf = zeros(LowerTriangularMatrix{Complex{NF}},lmax+2,mmax+1)
    return Orography(orography,geopot_surf)
end

struct Boundaries{NF<:AbstractFloat,Grid<:AbstractGrid{NF}} <: AbstractBoundaries{NF}
    orography::Orography{NF,Grid}
    # landsea_mask::AbstractLandSeaMask{NF}
    # albedo::AbstractAlbedo{NF}
end

function Boundaries(P::Parameters,
                    S::SpectralTransform{NF},
                    G::Geometry{NF}) where NF

    orography = zeros(Orography,S)                      # allocate orography arrays
    initialize_orography!(orography,P.orography,P,S,G)  # fill them with data
    scale_orography!(orography,P)                       # make whatever mountains bigger/smaller
    return Boundaries{NF,S.Grid{NF}}(orography)
end

# recalculate spectral transform or geometry if not provided
Boundaries(P::Parameters,S::SpectralTransform) = Boundaries(P,S,Geometry(P))
Boundaries(P::Parameters) = Boundaries(P,SpectralTransform(P))

function initialize_orography!( ::Orography,
                                ::NoOrography,
                                ::Parameters{<:ModelSetup},
                                args...)
    return nothing
end

function initialize_orography!( ::Orography,
                                ::AbstractOrography,
                                ::Parameters{<:Barotropic},
                                args...)
    return nothing
end

function initialize_orography!( orog::Orography,
                                ::EarthOrography,
                                P::Parameters{M},
                                S::SpectralTransform,
                                G::Geometry) where {M<:Union{ShallowWater,PrimitiveEquation}}

    @unpack orography, geopot_surf = orog
    @unpack orography_path, orography_file = P
    @unpack gravity = P.planet
    @unpack lmax, mmax = S

    # LOAD NETCDF FILE
    if orography_path == ""
        path = joinpath(@__DIR__,"../../input_data",orography_file)
    else
        path = joinpath(orography_path,orography_file)
    end
    ncfile = NetCDF.open(path)

    orography_highres = ncfile.vars["orog"][:,:]        # height [m]

    # Interpolate/coarsen to desired resolution
    #TODO also read lat,lon from file and flip array in case it's not as expected
    recompute_legendre = true   # don't allocate large arrays as spectral transform is not reused
    Grid = FullGaussianGrid     # grid the orography file comes with
    orography_spec = spectral(orography_highres;Grid,recompute_legendre)
    
    copyto!(geopot_surf,orography_spec)     # truncates to the size of geopot_surf, no *gravity yet
    gridded!(orography,geopot_surf,S)       # to grid-point space
    geopot_surf .*= gravity                 # turn orography into surface geopotential
    spectral_truncation!(geopot_surf)       # set the lmax+1 harmonics to zero
end

function initialize_orography!( orog::Orography,
                                coefs::ZonalRidge,
                                P::Parameters{M},
                                S::SpectralTransform,
                                G::Geometry) where {M<:Union{ShallowWater,PrimitiveEquation}}

    @unpack gravity, rotation, radius = P.planet
    @unpack lmax, mmax = S

    @unpack orography, geopot_surf = orog
    @unpack η₀, u₀ = coefs

    ηᵥ = (1-η₀)*π/2                     # ηᵥ-coordinate of the surface [1]
    A = u₀*cos(ηᵥ)^(3/2)                # amplitude [m/s]
    RΩ = radius*rotation                # [m/s]
    g⁻¹ = inv(gravity)                  # inverse gravity [s²/m]
    φ = G.latds                         # latitude for each grid point [˚N]

    for ij in eachindex(φ,orography.data)
        sinφ = sind(φ[ij])
        cosφ = cosd(φ[ij])

        # Jablonowski & Williamson, 2006, eq. (7)
        orography[ij] = g⁻¹*A*(A*(-2*sinφ^6*(cosφ^2 + 1/3) + 10/63) + (8/5*cosφ^3*(sinφ^2 + 2/3) - π/4)*RΩ)
    end

    spectral!(geopot_surf,orography,S)      # to grid-point space
    geopot_surf .*= gravity                 # turn orography into surface geopotential
    spectral_truncation!(geopot_surf)       # set the lmax+1 harmonics to zero
end

function scale_orography!(  orog::Orography,
                            P::Parameters)

    @unpack orography, geopot_surf = orog
    orography .*= P.orography_scale
    geopot_surf .*= P.orography_scale
    return nothing
end