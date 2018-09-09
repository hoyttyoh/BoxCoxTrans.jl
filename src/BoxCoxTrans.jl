module BoxCoxTrans

using Optim: optimize, minimizer
using Statistics: mean, var
using StatsBase: geomean

"""
    transform(𝐱)

Transform an array using Box-Cox method.  The power parameter λ is derived
from maximizing a log-likelihood estimator. 

If the array contains any non-positive values then a DomainError is thrown.
The optional shift argument α may be specified to add a constant to all
values in 𝐱 before applying the transformation.
"""
function transform(𝐱; kwargs...)
    λ, details = lambda(𝐱; kwargs...)
    transform(𝐱, λ; kwargs...)
end

"""
    transform(𝐱, λ; α = 0)

Transform an array using Box-Cox method with the provided power parameter λ. 

If the array contains any non-positive values then a DomainError is thrown.
The optional shift argument α may be specified to add a constant to all
values in 𝐱 before applying the transformation.
"""
function transform(𝐱, λ; α = 0, scaled = false) 
    if α != 0
        𝐱 .+= α
    end
    any(𝐱 .<= 0) && throw(DomainError("Data must be positive and ideally greater than 1.  You may specify α argument(shift). "))
    if scaled
        gm = geomean(𝐱)
        @. λ ≈ 0 ? gm * log(𝐱) : (𝐱 ^ λ - 1) / (λ * gm ^ (λ - 1))
    else
        @. λ ≈ 0 ? log(𝐱) : (𝐱 ^ λ - 1) / λ
    end
end

"""
    lambda(𝐱; interval = (-2.0, 2.0), method = :geomean)

Calculate lambda from an array using a log-likelihood estimator.

See also: [`log_likelihood`](@ref)
"""
function lambda(𝐱; interval = (-2.0, 2.0), kwargs...)
    i1, i2 = interval
    res = optimize(λ -> -log_likelihood(𝐱, λ; kwargs...), i1, i2)
    (value=minimizer(res), details=res)
end

"""
    log_likelihood(𝐱, λ; method = :geomean)

Return log-likelihood for the given array and lambda.

Method :geomean =>
    -N / 2.0 * log(2 * π * σ² / gm ^ (2 * (λ - 1)) + 1)

Method :normal =>
    -N / 2.0 * log(σ²) + (λ - 1) * sum(log.(𝐱))
"""
function log_likelihood(𝐱, λ; method = :geomean, kwargs...)
    N = length(𝐱)
    𝐲 = transform(float.(𝐱), λ)
    σ² = var(𝐲, corrected = false)
    gm = geomean(𝐱)
    if method == :geomean
        -N / 2.0 * log(2 * π * σ² / gm ^ (2 * (λ - 1)) + 1)
    elseif method == :normal
        -N / 2.0 * log(σ²) + (λ - 1) * sum(log.(𝐱)) 
    else
        throw(ArgumentError("Incorrect method. Please specify :geomean or :normal."))
    end
end

end # module
