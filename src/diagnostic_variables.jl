"""Struct holding the tendencies of the prognostic spectral variables plus some additional tendencies used in their calculation"""
struct Tendencies{NF<:AbstractFloat}
    vor_tend        ::Array{Complex{NF},3}      # Vorticity of horizontal wind field
    div_tend        ::Array{Complex{NF},3}      # Divergence of horizontal wind field
    temp_tend       ::Array{Complex{NF},3}      # Absolute temperature [K]
    pres_tend       ::Array{Complex{NF},2}      # Log of surface pressure [log(Pa)]
    humid_tend      ::Array{Complex{NF},3}      # Specific humidity [g/kg]
    u_tend          ::Array{NF,3}               # zonal velocity
    v_tend          ::Array{NF,3}               # meridonal velocity
end

"""
Generator function for the Tendencies struct. Initialises with zeros.
"""
function Tendencies(G::GeoSpectral{NF}) where NF

    @unpack lmax, mmax = G.spectral_transform   # 0-based degree l, order m of the spherical harmonics
    @unpack nlon,nlat,nlev = G.geometry         # number of longitudes, latitudes, vertical levels

    lmax, mmax = lmax+1,mmax+1                  # convert to 1-based
    vor_tend    = zeros(Complex{NF},lmax,mmax,nlev)     # vorticity
    div_tend    = zeros(Complex{NF},lmax,mmax,nlev)     # divergence
    temp_tend   = zeros(Complex{NF},lmax,mmax,nlev)     # absolute Temperature
    pres_tend   = zeros(Complex{NF},lmax,mmax)          # logarithm of surface pressure
    humid_tend  = zeros(Complex{NF},lmax,mmax,nlev)     # specific humidity
    u_tend      = zeros(NF,nlon,nlat,nlev)              # zonal velocity
    v_tend      = zeros(NF,nlon,nlat,nlev)              # meridonal velocity

    return Tendencies(vor_tend,div_tend,temp_tend,pres_tend,humid_tend,u_tend,v_tend)
end

"""Struct holding the core prognostic spectral variables in grid point space, plus some additional grid quantities"""
struct GridVariables{NF<:AbstractFloat}
    vor_grid            ::Array{NF,3}   # Gridpoint field of vorticity
    div_grid            ::Array{NF,3}   # Gridpoint field of divergence
    temp_grid           ::Array{NF,3}   # Gridpoint field of absolute temperature [K]
    pres_grid           ::Array{NF,2}   # Gridpoint field of surface pressure logarithm [log(Pa)]
    humid_grid          ::Array{NF,3}   # Gridpoint field of specific_humidity
    geopot_grid         ::Array{NF,3}   # Gridpoint field of geopotential
    # tr_grid             ::Array{NF,3}   # Gridpoint field of tracers
    U_grid              ::Array{NF,3}   # Gridpoint field of zonal velocity *coslat [m/s]
    V_grid              ::Array{NF,3}   # Gridpoint field of meridional velocity *coslat [m/s]
    temp_grid_anomaly   ::Array{NF,3}   # Gridpoint field of absolute temperature anomaly [K]
end

"""
Generator function for the GridVariables struct. Initialises with zeros.
"""
function GridVariables(G::GeoSpectral{NF}) where NF

    @unpack nlon,nlat,nlev = G.geometry     # number of longitudes, latitudes, vertical levels

    vor_grid            = zeros(NF,nlon,nlat,nlev)  # vorticity
    div_grid            = zeros(NF,nlon,nlat,nlev)  # divergence
    temp_grid           = zeros(NF,nlon,nlat,nlev)  # absolute Temperature
    pres_grid           = zeros(NF,nlon,nlat)       # logarithm of surface pressure
    humid_grid          = zeros(NF,nlon,nlat,nlev)  # specific humidity
    geopot_grid         = zeros(NF,nlon,nlat,nlev)  # geopotential
    # tr_grid            = zeros(NF,nlon,nlat,nlev)  # tracers
    U_grid              = zeros(NF,nlon,nlat,nlev)  # zonal velocity *coslat
    V_grid              = zeros(NF,nlon,nlat,nlev)  # meridonal velocity *coslat
    temp_grid_anomaly   = zeros(NF,nlon,nlat,nlev)  # absolute temperature anolamy

    return GridVariables(vor_grid,div_grid,temp_grid,pres_grid,humid_grid,geopot_grid,
                        # tr_grid,
                        U_grid,V_grid,temp_grid_anomaly)
end

"""
Struct holding quantities calculated from the physical parameterisations. All quantities
are in grid-point space.
"""
struct ParametrizationVariables{NF<:AbstractFloat}
    sat_vap_pressure   ::Array{NF,3}   # Saturation vapour pressure
    sat_spec_humidity  ::Array{NF,3}   # Saturation specific humidity
    cloud_top          ::Array{Int,2}  # Cloud-top
    precip_large_scale ::Array{NF,2}   # Large-scale precipitation
    humid_tend_lsc     ::Array{NF,3}   # Humidity tendencies due to large-scale condensation
    temp_tend_lsc      ::Array{NF,3}   # Temperature tendencies due to large-scale condensation
end

"""
Generator function for the ParametrizationVariables struct. Initialises with zeros.
"""
function ParametrizationVariables(G::GeoSpectral{NF}) where NF
    @unpack nlon, nlat, nlev = G.geometry

    sat_vap_pressure   = zeros(NF,nlon,nlat,nlev)  # Saturation vapour pressure
    sat_spec_humidity  = zeros(NF,nlon,nlat,nlev)  # Saturation specific humidity
    cloud_top          = zeros(Int,nlon,nlat)      # Cloud-top
    precip_large_scale = zeros(NF,nlon,nlat)       # Large-scale precipitation
    humid_tend_lsc     = zeros(NF,nlon,nlat,nlev)  # Humidity tendencies due to large-scale condensation
    temp_tend_lsc      = zeros(NF,nlon,nlat,nlev)  # Temperature tendencies due to large-scale condensation

    return ParametrizationVariables(sat_vap_pressure,
                                    sat_spec_humidity,
                                    cloud_top,
                                    precip_large_scale,
                                    humid_tend_lsc,
                                    temp_tend_lsc,
                                    )
end

"""Struct holding intermediate quantities that are used and shared when calculating tendencies"""
struct IntermediateVariables{NF<:AbstractFloat}

    ### VORTICITY INVERSION
    velocity_potential  ::Array{Complex{NF},3}      # = ϕ/R, scaled by 1/radius
    stream_function     ::Array{Complex{NF},3}      # = ΨR, scaled by radius
    coslat_u            ::Array{Complex{NF},3}      # = U = cosθ*u, zonal velocity *cos(latitude)
    coslat_v            ::Array{Complex{NF},3}      # = V = cosθ*v, meridional velocity *cos(latitude)

    # VORTICITY ADVECTION
    Uω_grid         ::Array{NF,3}                   # = U(ζ+f) on the grid
    Vω_grid         ::Array{NF,3}                   # = V(ζ+f) on the grid
    Uω              ::Array{Complex{NF},3}          # = U(ζ+f) in spectral space
    Vω              ::Array{Complex{NF},3}          # = V(ζ+f) in spectral space
    ∂Uω_∂lon        ::Array{Complex{NF},3}          # their zonal and
    ∂Vω_∂lat        ::Array{Complex{NF},3}          # meridional derivatives

    # SHALLOW WATER
    bernoulli_grid  ::Array{NF,3}           # bernoulli potential on the grid = 1/2(u^2+v^2) + gη
    bernoulli       ::Array{Complex{NF},3}  # spectral bernoulli potential
    ∂Uω_∂lat        ::Array{Complex{NF},3}  # off-diagonal derivatives of vorticity fluxes
    ∂Vω_∂lon        ::Array{Complex{NF},3}

    Uh_grid         ::Array{NF,3}           # volume flux U*h on grid
    Vh_grid         ::Array{NF,3}           # volume flux V*h on grid
    Uh              ::Array{Complex{NF},3}  # Uh in spectral
    Vh              ::Array{Complex{NF},3}  # Vh in spectral
    ∂Uh_∂lon        ::Array{Complex{NF},3}  # 1st component of ∇⋅(UV*h)
    ∂Vh_∂lat        ::Array{Complex{NF},3}  # 2nd component of ∇⋅(UV*h)

    ###------Defined in surface_pressure_tendency!()
    u_mean             ::Array{NF,2}  # Mean gridpoint zonal velocity over all levels
    v_mean             ::Array{NF,2}  # Mean gridpoint meridional velocity over all levels
    div_mean           ::Array{NF,2}  # Mean gridpoint divergence over all levels

    pres_gradient_spectral_x ::Array{Complex{NF},2} #X Gradient of the surface pressure, spectral space
    pres_gradient_spectral_y ::Array{Complex{NF},2} #Y Gradient of the surface pressure, spectral space

    pres_gradient_grid_x ::Array{NF,2} #X Gradient of the surface pressure, grid point space
    pres_gradient_grid_y ::Array{NF,2} #X Gradient of the surface pressure, grid point space

    ###------Defined in vertical_velocity_tendency!()
    sigma_tend ::Array{NF,3} #vertical velocity in sigma coords
    sigma_m    ::Array{NF,3} #some related quantity. What is this physically?
    puv        ::Array{NF,3} #(ug -umean)*px + (vg -vmean)*py

    ###------Defined in zonal_wind_tendency!()
    sigma_u ::Array{NF,3}  #some quantity used for later calculations

    ###------Defined in vor_div_tendency_and_corrections!()
    L2_velocity_complex ::Array{Complex{NF},2} # -laplacian(0.5*(u**2+v**2))

    ###-----Defined in tendencies.jl/get_spectral_tendencies!()
    vertical_mean_divergence ::Array{Complex{NF},2}
    sigdtc ::Array{Complex{NF},3} # what is this quantity, physically?
    dumk ::Array{Complex{NF},3} #ditto
    spectral_geopotential ::Array{Complex{NF},3} #This should probably go elsewhere
end

"""
Generator function for the IntermediateVariables struct. Initialises with zeros.
"""
function IntermediateVariables(G::GeoSpectral{NF}) where NF

    @unpack nlon,nlat,nlev = G.geometry         # number of longitudes, latitudes, vertical levels
    @unpack lmax, mmax = G.spectral_transform   # 0-based max degree l, order m of the spherical harmonics

    # BAROTROPIC VORTICITY EQUATION
    velocity_potential = zeros(Complex{NF},lmax+1,mmax+1,nlev)
    stream_function = zeros(Complex{NF},lmax+1,mmax+1,nlev)
    coslat_u = zeros(Complex{NF},lmax+2,mmax+1,nlev)
    coslat_v = zeros(Complex{NF},lmax+2,mmax+1,nlev)

    # VORTICITY ADVECTION
    Uω_grid  = zeros(NF,nlon,nlat,nlev)
    Vω_grid  = zeros(NF,nlon,nlat,nlev)
    Uω       = zeros(Complex{NF},lmax+2,mmax+1,nlev)
    Vω       = zeros(Complex{NF},lmax+2,mmax+1,nlev)
    ∂Uω_∂lon = zeros(Complex{NF},lmax+2,mmax+1,nlev)
    ∂Vω_∂lat = zeros(Complex{NF},lmax+2,mmax+1,nlev)

    # SHALLOW WATER
    bernoulli_grid  = zeros(NF,nlon,nlat,nlev)
    bernoulli       = zeros(Complex{NF},lmax+1,mmax+1,nlev)
    ∂Uω_∂lat = zeros(Complex{NF},lmax+2,mmax+1,nlev)
    ∂Vω_∂lon = zeros(Complex{NF},lmax+2,mmax+1,nlev)

    Uh_grid = zeros(NF,nlon,nlat,nlev)
    Vh_grid = zeros(NF,nlon,nlat,nlev)
    Uh = zeros(Complex{NF},lmax+2,mmax+1,nlev)
    Vh = zeros(Complex{NF},lmax+2,mmax+1,nlev)
    ∂Uh_∂lon = zeros(Complex{NF},lmax+2,mmax+1,nlev)
    ∂Vh_∂lat = zeros(Complex{NF},lmax+2,mmax+1,nlev)

    u_mean      = zeros(NF,nlon,nlat)           # Mean gridpoint zonal velocity over all levels
    v_mean      = zeros(NF,nlon,nlat)           # Mean gridpoint meridional velocity over all levels
    div_mean    = zeros(NF,nlon,nlat)           # Mean gridpoint divergence over all levels

    # one more l for recursion in meridional gradients
    # X,Y gradient of the surface pressure in spectral space
    pres_gradient_spectral_x = zeros(Complex{NF},lmax+2,mmax+1)
    pres_gradient_spectral_y = zeros(Complex{NF},lmax+2,mmax+1)

    # X,Y gradient of the surface pressure in grid space
    pres_gradient_grid_x = zeros(NF,nlon,nlat)
    pres_gradient_grid_y = zeros(NF,nlon,nlat)

    sigma_tend  = zeros(NF,nlon,nlat,nlev+1)
    sigma_m     = zeros(NF,nlon,nlat,nlev+1)
    puv         = zeros(NF,nlon,nlat,nlev)
    sigma_u     = zeros(NF,nlon,nlat,nlev+1)

    L2_velocity_complex         = zeros(Complex{NF},lmax+2,mmax+1)

    vertical_mean_divergence    = zeros(Complex{NF},lmax+2,mmax+1)
    sigdtc                      = zeros(Complex{NF},lmax+2,mmax+1,nlev+1)
    dumk                        = zeros(Complex{NF},lmax+2,mmax+1,nlev+1)
    spectral_geopotential       = zeros(Complex{NF},lmax+2,mmax+1,nlev)

    return IntermediateVariables(   velocity_potential, stream_function,
                                    coslat_u, coslat_v,
                                    Uω_grid,Vω_grid,
                                    Uω,Vω,∂Uω_∂lon,∂Vω_∂lat,
                                    bernoulli_grid,bernoulli,
                                    ∂Uω_∂lat,∂Vω_∂lon,
                                    Uh_grid,Vh_grid,Uh,Vh,∂Uh_∂lon,∂Vh_∂lat,
                                    u_mean,v_mean,div_mean,
                                    pres_gradient_spectral_x,pres_gradient_spectral_y,
                                    pres_gradient_grid_x,pres_gradient_grid_y,
                                    sigma_tend,sigma_m,puv,sigma_u,L2_velocity_complex,
                                    vertical_mean_divergence,sigdtc,dumk,spectral_geopotential)
end

"""Struct holding the diagnostic variables."""
struct DiagnosticVariables{NF<:AbstractFloat}
    tendencies                ::Tendencies{NF}
    grid_variables            ::GridVariables{NF}
    intermediate_variables    ::IntermediateVariables{NF}
    parametrization_variables ::ParametrizationVariables{NF}
end

"""Generator function for Diagnostic Variables """
function DiagnosticVariables(G::GeoSpectral)
    tendencies                = Tendencies(G)
    grid_variables            = GridVariables(G)
    intermediate_variables    = IntermediateVariables(G)
    parametrization_variables = ParametrizationVariables(G)
    return DiagnosticVariables( tendencies,
                                grid_variables,
                                intermediate_variables,
                                parametrization_variables,
                                )
end