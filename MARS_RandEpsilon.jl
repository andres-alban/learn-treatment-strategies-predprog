# On our setup, this file runs in about
# 6h 25min
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

policies = Dict{String,Policy}()

# fEVI policy
fEVI_policy = fEVIDiscrete(n, m, theta0, Sigma0, sample_std, FX, labeling0)
policies["fEVI"] = fEVI_policy
# fEVIon policy
P = 0
T = 1000
fEVIon_policy = fEVIDiscreteOnOff(n, m, theta0, Sigma0, sample_std, FX, P, T, labeling0)
policies["fEVIon"] = fEVIon_policy
# fEVI-MC
etaon = 1
etaoff = 10
fevimc_policy = fEVI_MC_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, labeling0)
policies["fEVI_MC"] = fevimc_policy
# fEVI-MCon
fevimcon_policy = fEVI_MC_OnOff_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, T, delay, P, labeling0)
policies["fEVI_MCon"] = fevimcon_policy

# RandEpsilon
epsilon_list = [0.05, 0.1, 0.2, 0.5]
for epsilon in epsilon_list
    randevi_policy = RandEpsilon(fEVI_policy, n, epsilon)
    policies["fEVI_eps$epsilon"] = randevi_policy
    randevion_policy = RandEpsilon(fEVIon_policy, n, epsilon)
    policies["fEVIon_eps$epsilon"] = randevion_policy
    randevi_policy = RandEpsilon(fevimc_policy, n, epsilon)
    policies["fEVI_MC_eps$epsilon"] = randevi_policy
    randevion_policy = RandEpsilon(fevimcon_policy, n, epsilon)
    policies["fEVI_MCon_eps$epsilon"] = randevion_policy
end

# Settings for simulation runs
T = 1000
reps = 5000 # number of replications
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
save("data/MARS_RandEpsilon.jld2", results)
