# On our setup, this file runs in about
# 1h 25min
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
include("code_fragments/MARS_model.jl")

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

# Policies
# we keep etaoff fixed at 1
etaoff = 1
etaon_list = [1, 5, 10, 20, 50]

policies = Dict{String,Policy}()

for etaon in etaon_list
    fevimc_simple_policy = ContextualBandits.fEVI_MC_simple_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, labeling0)
    policies["fEVI_MC_simple_$etaon"] = fevimc_simple_policy

    fevimc_policy = fEVI_MC_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, labeling0)
    policies["fEVI_MC_$etaon"] = fevimc_policy
end

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

# run simulation
rng = Xoshiro(121)
results = @time simulation_stochastic_parallel(reps, FX, n, T, policies, outcome_model;
    FXtilde=FXtilde, delay=delay, post_reps=post_reps, rng=rng, Xinterest=Xinterest)

## Save
folder = length(ARGS) > 1 ? ARGS[2] : "mydata"
save("$folder/MARS_MC.jld2", results)
