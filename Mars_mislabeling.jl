# On our setup, this file runs in about
# 3h 20min
using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using ContextualBandits
@everywhere include("code_fragments/MislabelingPolicy.jl")
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

policies = Dict{String,Policy}()
for n_pred in [-3, -2, -1, 1, 2, 3]
    ## Random policy
    random_policy = RandomPolicyLinear(n, m, theta0, Sigma0, sample_std, labeling0)
    random_policy = MislabelingPolicy(random_policy, labeling0, n_pred; sigma0, psi, D, rng=Xoshiro(1111))

    # fEVI policy
    fEVI_policy = fEVIDiscrete(n, m, theta0, Sigma0, sample_std, FX, labeling0)
    fEVI_policy = MislabelingPolicy(fEVI_policy, labeling0, n_pred; sigma0, psi, D, rng=Xoshiro(1111))

    # policies
    policies["random_$n_pred"] = random_policy
    policies["fEVI_$n_pred"] = fEVI_policy
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
save("$folder/MARS_mislabeling.jld2", results)
