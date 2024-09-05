using ContextualBandits
using Distributions

# this code was copied and modified from the ContexualBandits package
"""
    fEVI_MC_blind_PolicyLinear <: PolicyLinear
    fEVI_MC_blind_PolicyLinear(n, m, theta0, Sigma0, sample_std, FXtilde, etaon, etaoff, labeling=vcat(falses(m),trues(n*m)))

Allocate treatment using the fEVI-MC allocation policy and update based on the
linear model with labeling to make an implementation.
"""
mutable struct fEVI_MC_blind_PolicyLinear <: PolicyLinear
    model::BayesLinearRegression
    FXtilde::Sampleable
    etaon::Int
    etaoff::Int
end

function fEVI_MC_blind_PolicyLinear(n, m, theta0, Sigma0, sample_std, FXtilde, etaon, etaoff, labeling=vcat(falses(m), trues(n * m)))
    length(FXtilde) == m || throw(DomainError(FXtilde, "`FXtilde` must have length `m`."))
    etaon > 0 || throw(DomainError(etaon, "`etaon` must be positive."))
    etaoff > 0 || throw(DomainError(etaoff, "`etaoff` must be positive."))
    fEVI_MC_blind_PolicyLinear(BayesLinearRegression(n, m, theta0, Sigma0, sample_std, labeling), FXtilde, etaon, etaoff)
end

function ContextualBandits.allocation(policy::fEVI_MC_blind_PolicyLinear, Xcurrent, W, X, Y, rng=Random.default_rng())
    pipeend = 0
    pipestart = 1 # This choice passes an empty pipeline to the fEVI_MC function
    fEVI_MC_indices = fEVI_MC(policy.model.n, policy.model.m, policy.model.theta_t, policy.model.Sigma_t, policy.model.sample_std, Xcurrent,
        policy.FXtilde, view(W, pipestart:pipeend), view(X, :, pipestart:pipeend), policy.etaon, policy.etaoff, policy.model.labeling, rng)
    return argmax_ties(fEVI_MC_indices, rng)
end



"""
    fEVI_MC_OnOff_blind_PolicyLinear <: PolicyLinear
    fEVI_MC_OnOff_blind_PolicyLinear(n, m, theta0, Sigma0, sample_std, FXtilde, etaon, etaoff, T, delay, P[, labeling])

Allocate treatment using the fEVI-MC with online rewards allocation policy and
update based on the linear model with labeling to make an implementation.
"""
mutable struct fEVI_MC_OnOff_blind_PolicyLinear <: PolicyLinear
    model::BayesLinearRegression
    FXtilde::Sampleable
    etaon::Int
    etaoff::Int
    T::Int
    delay::Int
    P::Float64
end

function fEVI_MC_OnOff_blind_PolicyLinear(n, m, theta0, Sigma0, sample_std, FXtilde, etaon, etaoff, T, delay, P, labeling=vcat(falses(m), trues(n * m)))
    length(FXtilde) == m || throw(DomainError(FXtilde, "`FXtilde` must have length `m`."))
    etaon > 0 || throw(DomainError(etaon, "`etaon` must be positive."))
    etaoff > 0 || throw(DomainError(etaoff, "`etaoff` must be positive."))
    T >= 0 || throw(DomainError(T, "`T` must be positive"))
    delay >= 0 || throw(DomainError(delay, "`delay` must be positive"))
    P >= 0 || throw(DomainError(P, "`P` must be positive"))
    fEVI_MC_OnOff_blind_PolicyLinear(BayesLinearRegression(n, m, theta0, Sigma0, sample_std, labeling), FXtilde, etaon, etaoff, T, delay, P)
end

function ContextualBandits.allocation(policy::fEVI_MC_OnOff_blind_PolicyLinear, Xcurrent, W, X, Y, rng=Random.default_rng())
    t = length(W)
    weight_on = max(policy.T - t - policy.delay - 1, 0)
    expected_outcomes = [interact(iw, policy.model.n, Xcurrent, policy.model.labeling)' * policy.model.theta_t for iw in 1:policy.model.n]
    expected_outcomes .-= minimum(expected_outcomes) - 1 # shift expected outcomes so that the worst is 1
    log_expected_outcomes = log.(expected_outcomes)
    lognu = fEVI_MC(policy.model.n, policy.model.m, policy.model.theta_t, policy.model.Sigma_t, policy.model.sample_std, Xcurrent,
        policy.FXtilde, view(W, 1:0), view(X, :, 1:0), policy.etaon, policy.etaoff, policy.model.labeling, rng)
    lognu_on = ContextualBandits.logSumExp.(log_expected_outcomes, log(weight_on) .+ lognu)
    lognu_combined = ContextualBandits.logSumExp.(lognu_on, log(policy.P) .+ lognu)
    return argmax_ties(lognu_combined, rng)
end