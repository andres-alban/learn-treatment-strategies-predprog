# On our setup, this file runs in about
# 2h 40min
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

## Random policy
random_policy = RandomPolicyLinear(n, m, theta0, Sigma0, sample_std, labeling0)

## Thompson sampling
TS_policy = TSPolicyLinear(n, m, theta0, Sigma0, sample_std, labeling0)

## Top-two Thompson sampling
beta = 0.5
maxiter = 100
TTTS_policy = TTTSPolicyLinear(n, m, theta0, Sigma0, sample_std, beta, maxiter, labeling0)

# fEVI-MC policy
etaon = 1
etaoff = 100
fevimc_policy = fEVI_MC_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, labeling0)

# fEVIMC_OnOff policy
P = 0
etaon = 1
etaoff = 100
T = 1000
fevimcon_policy = fEVI_MC_OnOff_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, T, delay, P, labeling0)

## fEVIDiscretize policy
Q1 = 0.3255102498039182 # Q1 of a Normal(1,1)
Q3 = 1.6744897501960818 # Q3 of a Normal(1,1)
breakpoints = [Float64[], [Q1, Q3], [Q1, Q3]]
FX_discretized = discretizeFX(FXtilde, breakpoints)[1]
fEVI = fEVIDiscrete(n, m, theta0, Sigma0, sample_std, FX_discretized, labeling0)
fEVI_policy = DiscretizePolicy(fEVI, FXtilde, breakpoints)

## Biased Coin
p1 = 0.5
pk = vcat([p1], ones(n - 1) * (1 - p1) / (n - 1))
Gweight = [0, 0.5, 0.5, 0]
biasedcoin_policy = BiasedCoinPolicyLinear(n, m, theta0, Sigma0, sample_std, FX, labeling0;
    p=pk, weights=Gweight)

## OCBA
ocba_policy = OCBAPolicyLinear(n, m, theta0, Sigma0, sample_std, FX, labeling0)

## RABC
Gweight = [0.25, 0.25, 0.25, 0.25]
RABC_policy = RABC_OCBA_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, labeling0; p=pk, weights=Gweight)

## Greedy
greedy_policy = GreedyPolicyLinear(n, m, theta0, Sigma0, sample_std, labeling0)

# policies
policies = Dict(
    "random" => random_policy, "TS" => TS_policy,
    "TTTS" => TTTS_policy, "fEVIMC" => fevimc_policy, "fEVIMCon" => fevimcon_policy,
    "fEVI" => fEVI_policy, "biasedcoin" => biasedcoin_policy, "RABC" => RABC_policy,
    "ocba" => ocba_policy, "greedy" => greedy_policy
)

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
save("data/contMARS_known.jld2", results)
