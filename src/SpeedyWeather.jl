module SpeedyWeather

    # STRUCTURE
    import Parameters: @with_kw, @unpack

    # NUMERICS
    import FastGaussQuadrature
    import AssociatedLegendrePolynomials
    import FFTW
    import Primes
    import LinearAlgebra

    # INPUT OUTPUT
    import Dates: Dates, DateTime
    import Printf: @sprintf
    import NetCDF: NetCDF, NcFile, NcDim, NcVar
    import BitInformation: round, round!
    import UnicodePlots
    import ProgressMeter

    # EXPORT MAIN INTERFACE TO SPEEDY
    export run_speedy, initialize_speedy

    # EXPORT STRUCTS
    export Parameters, GenLogisticCoefs,
        GeoSpectral, Boundaries, Constants, Geometry, SpectralTransform,
        PrognosticVariables, DiagnosticVariables

    # EXPORT SPECTRAL FUNCTIONS
    export  spectral, gridded,
        spectral_truncation, spectral_interpolation,
        triangular_truncation

    include("utility_functions.jl")
    include("parameter_structs.jl")
    include("spectral_truncation.jl")

    include("default_parameters.jl")        # defines Parameters
    include("constants.jl")                 # defines Constants
    include("geometry.jl")                  # defines Geometry
    include("spectral_transform.jl")        # defines SpectralTransform, Geospectral
    include("spectral_gradients.jl")
    include("distributed_vertical.jl")

    include("boundaries.jl")                # defines Boundaries
    include("horizontal_diffusion.jl")      # defines HorizontalDiffusion
    include("implicit.jl")                  # defines Implicit
    include("models.jl")                    # defines ModelSetups

    include("prognostic_variables.jl")      # defines PrognosticVariables
    include("diagnostic_variables.jl")      # defines DiagnosticVariables

    include("run_speedy.jl")
    include("tendencies_parametrizations.jl")
    include("tendencies_dynamics.jl")
    include("tendencies.jl")
    include("implicit_correction.jl")
    include("feedback.jl")                  # defines Feedback
    include("output.jl")

    # PHYSICS
    include("humidity.jl")
    include("large_scale_condensation.jl")

    include("time_integration.jl")
    include("pretty_printing.jl")
end