"""
    true/false = isincreasing(v::Vector)

Check whether elements of a vector `v` are strictly increasing."""
function isincreasing(x::Vector)
    is_increasing = true
    for i in 2:length(x)
        is_increasing &= x[i-1] < x[i] ? true : false
    end
    return is_increasing
end

"""
    true/false = isdecreasing(v::Vector)

Check whether elements of a vector `v` are strictly decreasing."""
function isdecreasing(x::Vector)
    is_decreasing = true
    for i in 2:length(x)
        is_decreasing &= x[i-1] > x[i] ? true : false
    end
    return is_decreasing
end

"""
    clip_negatives!(A::AbstractArray)

Set all negative entries `a` in `A` to zero."""
function clip_negatives!(A::AbstractArray{T}) where T
    @inbounds for i in eachindex(A)
        A[i] = max(A[i],zero(T))
    end
end

"""
    underflow!(A::AbstractArray,ϵ::Real)

Underflows element `a` in `A` to zero if `abs(a) < ϵ`."""
function underflow!(A::AbstractArray{T},ϵ::Real) where T
    ϵT = convert(T,abs(ϵ))
    @inbounds for i in eachindex(A)
        A[i] = abs(A[i]) < ϵT ? zero(T) : A[i]
    end
end

"""
    flipgsign!(A::AbstractArray)

Like `-A` but in-place."""
function flipsign!(A::AbstractArray)
    @inbounds for i in eachindex(A)
        A[i] = -A[i]
    end
    A
end

"""
    readable_secs(secs::Real) -> Dates.CompoundPeriod

Returns `Dates.CompoundPeriod` rounding to either (days, hours), (hours, minutes), (minutes,
seconds), or seconds with 1 decimal place accuracy for >10s and two for less.
E.g.
```julia
julia> readable_secs(12345)
3 hours, 26 minutes
```
"""
function readable_secs(secs::Real)
    millisecs = Dates.Millisecond(round(secs * 10 ^ 3))
    if millisecs >= Dates.Day(1)
        return Dates.canonicalize(round(millisecs, Dates.Hour))
    elseif millisecs >= Dates.Hour(1)
        return Dates.canonicalize(round(millisecs, Dates.Minute))
    elseif millisecs >= Dates.Minute(1)
        return Dates.canonicalize(round(millisecs, Dates.Second))
    elseif millisecs >= Dates.Second(10)
        return Dates.canonicalize(round(millisecs, Dates.Millisecond(100)))
    end
    return Dates.canonicalize(round(millisecs, Dates.Millisecond(10)))
end

# define as will only become availale in Julia 1.9
pkgversion(m::Module) = VersionNumber(TOML.parsefile(joinpath(
    dirname(string(first(methods(m.eval)).file)), "..", "Project.toml"))["version"])

# NAN initialisation
"""
    A = nans(T,dims...)

Allocate array A with NaNs of type T. Similar to zeros(T,dims...)."""
function nans(::Type{T},dims...) where T
    return fill(convert(T,NaN),dims...)
end

"""
    A = nans(dims...)

Allocate A::Array{Float64} with NaNs."""
nans(dims...) = nans(Float64,dims...)