initialize_implicit!(Δt::Real,M::BarotropicModel) = nothing

function initialize_implicit!(  dt::Real,                   # time step to update implicit terms with
                                M::ShallowWaterModel{NF}    # update Implicit struct in M
                                ) where NF

    @unpack implicit_α = M.parameters                       # = [0,0.5,1], time step fraction for implicit
    @unpack eigen_values = M.geospectral.spectral_transform # =-l*(l+1), degree l of harmonics
    @unpack ξH₀,ξRH₀,ξg∇²,ξgR∇²,div_impl = M.implicit       # pull precomputed arrays to be updated
    @unpack layer_thickness = M.constants                   # shallow water layer thickness [m]
    @unpack radius_earth, gravity = M.constants             # gravitational acceleration [m/s²]                  

    α = convert(NF,implicit_α)                              # to avoid promotions
    ξ = α*convert(NF,dt)                                    # new implicit timestep ξ = α*dt = 2αΔt from input dt
    ξH₀[1] = ξ*layer_thickness                              # update ξ*H₀ with new ξ
    ξRH₀[1] = ξ*layer_thickness*radius_earth                # update ξ*H₀*R with new ξ

    @inbounds for i in eachindex(ξg∇²,ξgR∇²,div_impl,eigen_values)
        ξg∇²[i] = ξ*gravity*eigen_values[i]                 # update precomputed ξ∇² with new ξ
        ξgR∇²[i] = ξ*gravity*radius_earth*eigen_values[i]   # update precomputed ξR∇² with new ξ
        div_impl[i] = inv(1 - ξH₀[1]*ξg∇²[i])               # update precomputed 1/(1-ξ²gH₀∇²) with new ξ
    end
end

function implicit_correction!(  diagn::DiagnosticVariables{NF},
                                progn::PrognosticVariables{NF},
                                M::ShallowWaterModel{NF}
                                ) where NF
    
    @unpack div,pres = progn
    @unpack div_tend, pres_tend = diagn.tendencies
    @unpack ξH₀,ξg∇²,ξRH₀,ξgR∇²,div_impl = M.implicit
    @unpack lmax,mmax = M.geospectral.spectral_transform
    @unpack implicit_α, layer_thickness = M.parameters

    @boundscheck (lmax+1,mmax+1,2,1) == size(div) || throw(BoundsError)
    @boundscheck (lmax+1,mmax+1,1) == size(div_tend) || throw(BoundsError)
    @boundscheck (lmax+1,mmax+1,2) == size(pres) || throw(BoundsError)
    @boundscheck (lmax+1,mmax+1) == size(pres_tend) || throw(BoundsError)

    k = 1       # only one vertical level for shallow water model
    for m in 1:mmax+1
        for l in m:lmax+1
            G_div = div_tend[l,m,k] - ξgR∇²[l]*(pres[l,m,1] - pres[l,m,2])
            G_η   = pres_tend[l,m,k] - ξRH₀[1]*(div[l,m,1,k] - div[l,m,2,k])
            δdiv = (G_div - ξg∇²[l]*G_η)*div_impl[l]
            div_tend[l,m,k] = δdiv
            pres_tend[l,m,k] = G_η - ξH₀[1]*δdiv
        end
    end
end