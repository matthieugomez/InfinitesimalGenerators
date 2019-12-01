using InfinitesimalGenerators, Test, Statistics, LinearAlgebra,  Expokit


##  Ornstein–Uhlenbeck
κx = 0.1
σ = 0.02
x = range(- 10 * sqrt(σ^2 /(2 * κx)), stop = 10 * sqrt(σ^2 /(2 * κx)), length = 1000)
μx = -κx .* x
σx = σ .* ones(length(x))


## stationnary distribution
g = stationary_distribution(x, μx, σx)

## Feynman-Kac
ψ = x.^2
t = range(0, stop = 100, step = 1/10)
𝔸 = generator(x, μx, σx)
u = feynman_kac_forward(x, μx, σx; t = t, ψ = ψ)
# Check results using exponential integrator. I could also use KrylovKit.exponentiate
@test maximum(abs, u[:, 50] .- expmv(t[50], 𝔸, ψ)) <= 1e-3
@test maximum(abs, u[:, 200] .- expmv(t[200], 𝔸, ψ)) <= 1e-3
@test maximum(abs, u[:, end] .- expmv(t[end], 𝔸, ψ)) <= 1e-5
@test maximum(abs, feynman_kac_forward(x, μx, σx; t = t, ψ = ψ) .- feynman_kac_forward(x, μx, σx; t = collect(t), ψ = ψ)) <= 1e-5


## Multiplicative Functional dM/M = x dt
μM = x
σM = zeros(length(x))
g, η, f = hansen_scheinkman(x, μx, σx, μM, σM)
@test η ≈ 0.5 * σ^2 / κx^2 atol = 1e-2
@test maximum(abs, f ./ exp.(x ./ κx) .- mean(f ./ exp.(x ./ κx))) <= 1e-2

t = range(0, stop = 100, step = 1/10)
u = feynman_kac_forward(x, μx, σx, μM, σM; t = t)
@test log.(stationary_distribution(x, μx, σx)' * u[:, end]) ./ t[end] ≈ η atol = 1e-2


## test left and right eigenvector
μM = x
σM = 0.01 * ones(length(x))
g, η, f = hansen_scheinkman(x, μx, σx, μM, σM; ρ = 1, eigenvector = :both)
ψ = stationary_distribution(x, μx .+ σM .* σx, σx)
@test (f .* ψ) ./sum(f .* ψ) ≈ g rtol = 1e-3



## test left and right eigenvector
κx = 0.1
σ = 0.02
x = range(- 6 * sqrt(σ^2 /(2 * κx)), stop = 6 * sqrt(σ^2 /(2 * κx)), length = 400)
μx = -κx .* x
σx = σ .* ones(length(x))
μM = -0.01 .+ x
σM = 0.1 .* ones(length(x))
ζ = tail_index(x, μx, σx, μM, σM)
ζ_analytic = 2 * (0.01 + 0.1^2/2) / (0.1^2 + (σ / κx)^2)
@test ζ ≈ ζ_analytic atol = 1e-2
g, η, f = cgf_longrun(MultiplicativeFunctional(x, μx, σx, μM, σM), ζ; eigenvector = :both)
@test η ≈ 0.0 atol = 1e-5
ψ = stationary_distribution(x, μx, σx)
@test (f .* ψ) ./ sum(f .* ψ) ≈ g rtol = 1e-3



ρ = 1.0
ζ = tail_index(x, μx, σx, μM, σM, ρ = ρ)
g, η, f = cgf_longrun(MultiplicativeFunctional(x, μx, σx, μM, σM; ρ = ρ), ζ; eigenvector = :both)
@test η ≈ 0.0 atol = 1e-5
ψ = stationary_distribution(x, μx .+ ρ .* ζ .* σM .* σx, σx)
@test (f .* ψ) ./ sum(f .* ψ) ≈ g rtol = 1e-3




