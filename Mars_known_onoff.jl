# On our setup, this file runs in about
# 6h 45min
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


# policies
policies = Dict{String,Policy}()

## fEVIonoff
T = 1000
for P in [1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12, 1e15]
    fEVIonoff_policy = fEVIDiscreteOnOff(n, m, theta0, Sigma0, sample_std, FX, P, T, labeling0)
    policies["fEVIonoff_P$(Int(P/1000))k"] = fEVIonoff_policy
end

## fEVI policy
fEVI_policy = fEVIDiscrete(n, m, theta0, Sigma0, sample_std, FX, labeling0)
policies["fEVI"] = fEVI_policy

## fEVIon policy
P = 0
fEVIon_policy = fEVIDiscreteOnOff(n, m, theta0, Sigma0, sample_std, FX, P, T, labeling0)
policies["fEVIon"] = fEVIon_policy

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
## we use a different seed for this experiment because we aim to show that there
## is no statistical difference between some of our fEVI-based policies and TS/TTTS.
## Having independent samples is a better approach when we do not reject the null hypothesis
rng = Xoshiro(94121)
results = @time simulation_stochastic_parallel(reps, FX, n, T, policies, outcome_model;
    FXtilde=FXtilde, delay=delay, post_reps=post_reps, rng=rng, Xinterest=Xinterest)

## Save
folder = length(ARGS) > 1 ? ARGS[2] : "mydata"
save("$folder/MARS_known_onoff.jld2", results)