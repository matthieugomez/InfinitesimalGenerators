
function generator(x::AbstractVector, μx::AbstractVector, σx::AbstractVector)
    𝔸 = BandedMatrix(Zeros(length(x), length(x)), (1, 1))
    Δ = make_Δ(x)
    generator!(𝔸, Δ, μx, σx)
end

function generator!(𝔸::AbstractMatrix, Δ, μx::AbstractVector, σx::AbstractVector)
    operator!(𝔸, Δ, zeros(length(μx)), μx, 0.5 * σx.^2)
end

#========================================================================================

Stationary Distribution with one state variable

========================================================================================#
#now there are still two issues
#1. Does not satisfy walras law. Or mathematically does not satisfy IPP ∑ μ.g = ∑ a.Ag. 
# 1.1. First part due to drift if not positive at left boundary or not negative ar right boundary In the case drift is positive, there is a remaning term μ_NdG(a_N) To satisfy it, do amax super super high (intuitively, x high enough so that cutting behavior at the top does not matter for aggregate as g(x)x -> 0)
#1.2 Second part is due to volatility. Note that it requires to put invΔx[i] for central derivative, which is different with the formula in Moll notes
#2. A g can be negative when updating forward. Use implicit scheme

function stationary_distribution(x::AbstractVector, μx::AbstractVector, σx::AbstractVector)
    𝔸 = generator(x, μx, σx)
    density, _, _ = principal_eigenvalue(𝔸; eigenvector = :left)
    return density
end


function stationary_distribution(x::AbstractVector, μx::AbstractVector, σx::AbstractVector, δ, ψ)
    𝔸 = generator(x, μx, σx)
    density = (δ * I - 𝔸') \ (δ * ψ)
    clean_density(density)
end

#========================================================================================

Compute u(x_t, t) = E[∫t^T e^{-∫ts V(x_τ, τ)dτ}f(x_s, s)ds + e^{-∫tT V(x_τ, τ)dτ}ψ(x_T)|x_t = x]
using
0 = (u_{t+1} - u_{t})/dt + 𝔸u_t + f
that is
(I - 𝔸dt)u_t =  u_{t+1} + f dt
========================================================================================#

function feynman_kac_backward(x, μx, σx; ψ::AbstractVector, t::AbstractVector = range(0, 100, step = 1/12), f::T = zeros(length(x)), V::T = zeros(length(x))) where {T <: Union{AbstractVector, AbstractMatrix}}
    u = zeros(length(x), length(t))
    u[:, length(t)] = ψ
    Δ = make_Δ(x)
    𝔸 = BandedMatrix(Zeros(length(x), length(x)), (1, 1))
    if (T <: AbstractVector)
        dt = t[2] - t[1]
        𝔹 = factorize(I - operator!(𝔸, Δ, V .* dt, μx .* dt, 0.5 .* σx.^2 .* dt))
        for i in (length(t)-1):(-1):1
            ψ = ldiv!(𝔹, u[:, i+1] .+ f .* dt)
            u[:, i] = ψ
        end
    elseif T <: AbstractVector
        for i in (length(t)-1):(-1):1
            dt = t[i+1] - t[i]
            𝔹 = I - operator!(𝔸, Δ, V .* dt, μx .* dt, 0.5 .* σx.^2 .* dt)
            ψ = 𝔹 \  (u[:, i+1] .+ f .* dt)
            u[:, i] = ψ
        end
    else
        for i in (length(t)-1):(-1):1
            dt = t[i+1] - t[i]
            𝔹 = (I - operator!(𝔸, Δ, V[:, i] .* dt, μx .* dt, 0.5 .* σx.^2 .* dt))
            ψ = 𝔹 \ (u[:, i+1] .+ f[:, i] .* dt)
            u[:, i] = ψ
        end
    end
    return u
end

#========================================================================================

Compute u(x_t, T)= E[∫t^T e^{-∫ts V(x_τ)dτ}f(x_s)ds + e^{-∫tTV(x_τ)dτ} ψ(x_T)|x_t = x]

========================================================================================#

function feynman_kac_forward(x, μx, σx; ψ::AbstractVector, t::AbstractVector = range(0, 100, step = 1/12), f::AbstractVector = zeros(length(x)), V::AbstractVector = zeros(length(x)))
    u = feynman_kac_backward(x, μx, σx; ψ = ψ, t = .- reverse(t), f = f, V = V)
    return u[:,end:-1:1]
end
