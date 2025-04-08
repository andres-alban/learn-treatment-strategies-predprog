# On our setup, this file runs in about
# 30h 30min
using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using ContextualBandits
using Random
using Distributions
using Statistics
using JLD2
using LinearAlgebra

# Setting up model
include("code_fragments/contMARS_model.jl")
@everywhere include("code_fragments/fEVI_MC_blind.jl")

# Setting up prior
labeling0 = labeling
sigma0 = 2
psi = log(2)
D = [
    0 2 2 3 2 3 3 Inf;
    2 0 3 2 3 2 Inf 3;
    2 3 0 2 3 Inf 2 3;
    3 2 2 0 Inf 3 3 2;
    2 3 3 Inf 0 2 2 3;
    3 2 Inf 3 2 0 3 2;
    3 Inf 2 3 2 3 0 2;
    Inf 3 3 2 3 2 2 0
]
theta0, Sigma0 = default_prior_linear(n, m, sigma0, psi, D, labeling0)
robustify_prior_linear!(theta0, Sigma0, n, m, labeling0)

# Settings for simulation runs
T = 1000
# number of replications (5000 for production and 10 for debugging)
reps = if length(ARGS) > 0 && ARGS[1] == "prod"
    5000
else
    10
end
post_reps = 50
Xinterest = [
    1 1 1 1;
    0 1 0 0;
    0 0 1 0;
    0 0 0 1;
    0 0 0 0;
    0 0 0 0
]

# we keep post_reps fixed at 10
etaon_list = [5, 10, 25]
etaoff_list = [5, 10]
delay_list = [20, 50]
P = 0

for (i, delay) in enumerate(delay_list)
    policies = Dict{String,Policy}()
    for etaon in etaon_list
        for etaoff in etaoff_list
            fevimc_policy = fEVI_MC_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, labeling0)
            fevimcon_policy = fEVI_MC_OnOff_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, T, delay, P, labeling0)
            policies["fEVI_MC_$(delay)_$(etaon)_$etaoff"] = fevimc_policy
            policies["fEVI_MCon_$(delay)_$(etaon)_$etaoff"] = fevimcon_policy
        end
    end
    etaon = 1
    etaoff = 100
    fevimc_blind_policy = fEVI_MC_blind_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, labeling0)
    fevimcon_blind_policy = fEVI_MC_OnOff_blind_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, T, delay, P, labeling0)
    policies["fEVI_MC_blind_$(delay)_$(etaon)_$etaoff"] = fevimc_blind_policy
    policies["fEVI_MCon_blind_$(delay)_$(etaon)_$etaoff"] = fevimcon_blind_policy
    ## Top-two Thompson sampling
    beta = 0.5
    maxiter = 100
    TTTS_policy = TTTSPolicyLinear(n, m, theta0, Sigma0, sample_std, beta, maxiter, labeling0)
    policies["TTTS"] = TTTS_policy
    keys(policies)

    # run simulation
    rng = Xoshiro(121)
    results = @time simulation_stochastic_parallel(reps, FX, n, T, policies, outcome_model;
        FXtilde=FXtilde, delay=delay, post_reps=post_reps, rng=rng, Xinterest=Xinterest)

    ## Save
    folder = length(ARGS) > 1 ? ARGS[2] : "mydata"
    save("$folder/contMARS_delay$(delay).jld2", results)
end
