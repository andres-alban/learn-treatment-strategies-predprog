using ContextualBandits
using Random
using StatsBase
"""
    MislabelingPolicy{T<:PolicyLinear, S<:LabelingSelector} <: Policy
    MislabelingPolicy(subpolicy, selector, schedule, [labeling0; sigma0, psi, D, z_alpha, c])

Create a policy that modifies `subpolicy` by mislabeling some covariates.
"""
mutable struct MislabelingPolicy{T<:PolicyLinear} <: Policy
    subpolicy::T
    labeling0::Vector{Bool}
    n_pred::Int
    pred_candidates::Vector{Tuple{Int,Int}}
    sigma0::Float64
    psi::Float64
    D::Matrix{Float64}
    z_alpha::Float64
    c::Float64
    rng::Xoshiro
    function MislabelingPolicy(subpolicy::T, labeling0=vcat(falses(subpolicy.model.m), trues(subpolicy.model.n * subpolicy.model.m)), n_pred=1; sigma0=1e6, psi=1, D=fill(Inf, subpolicy.model.n, subpolicy.model.n), z_alpha=2, c=4, rng=Xoshiro(1111)) where {T<:PolicyLinear}
        subpolicy = deepcopy(subpolicy)
        subpolicy.model.labeling .= labeling0
        pred_candidates = find_candidates(labeling0, subpolicy.model.n, subpolicy.model.m, n_pred >= 0)
        abs(n_pred) <= length(pred_candidates) || throw(DomainError(n_pred, "n_pred wants to mislabel more covariates than are available"))
        new{T}(subpolicy, copy(labeling0), n_pred, pred_candidates, sigma0, psi, D, z_alpha, c, rng)
    end
end

function find_candidates(labeling, n, m, add)
    candidates = Vector{Tuple{Int,Int}}(undef, 0)
    for treatment in 1:n
        for covariate in 2:m
            index = treatment * m + covariate
            if labeling[index] != add
                push!(candidates, (treatment, covariate))
            end
        end
    end
    return candidates
end

function ContextualBandits.initialize!(policy::MislabelingPolicy, W, X, Y)
    labeling = copy(policy.labeling0)
    mis_pred = sample(policy.rng, policy.pred_candidates, abs(policy.n_pred); replace=false)
    m = policy.subpolicy.model.m
    for (treatment, covariate) in mis_pred
        labeling[treatment*m+covariate] = !labeling[treatment*m+covariate]
    end

    policy.subpolicy.model.labeling = labeling
    theta, Sigma = default_prior_linear(policy.subpolicy.model.n, policy.subpolicy.model.m,
        policy.sigma0, policy.psi, policy.D, policy.subpolicy.model.labeling)
    robustify_prior_linear!(theta, Sigma, policy.subpolicy.model.n, policy.subpolicy.model.m, policy.subpolicy.model.labeling, policy.z_alpha, policy.c)
    policy.subpolicy.model.theta0 = theta
    policy.subpolicy.model.Sigma0 = Sigma
    if length(Y) > 0
        policy.Wpilot = W
        policy.Xpilot = X
        policy.Ypilot = Y
    end
    ContextualBandits.initialize!(policy.subpolicy, W, X, Y)
    return
end

function ContextualBandits.state_update!(policy::MislabelingPolicy, W, X, Y, rng=Random.default_rng())
    ContextualBandits.state_update!(policy.subpolicy, W, X, Y, rng)
end

function ContextualBandits.implementation(policy::MislabelingPolicy, X_post, W, X, Y)
    return ContextualBandits.implementation(policy.subpolicy, X_post, W, X, Y)
end

function ContextualBandits.allocation(policy::MislabelingPolicy, Xcurrent, W, X, Y, rng=Random.default_rng())
    return ContextualBandits.allocation(policy.subpolicy, Xcurrent, W, X, Y, rng)
end

function ContextualBandits.policy_labeling(policy::MislabelingPolicy)
    return ContextualBandits.policy_labeling(policy.subpolicy)
end