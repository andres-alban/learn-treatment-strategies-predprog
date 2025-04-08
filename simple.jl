# On our setup, this file runs in about
# 3h 15min
using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using ContextualBandits
using Random
using Distributions
using Statistics
using JLD2
using LinearAlgebra

n = 2
FX = CovariatesIndependent([Categorical([0.5, 0.5]), Categorical([0.5, 0.5])])
m = length(FX)
sample_std = 1.0
labeling = BitVector(
    [1, 1, 1, # prognostic
    1, 1, 0,  # treatment 1
    0, 0, 0,  # treatment 2
])


mu = [
    1, -1, 1,  # prognostic
    -1, 2      # treatment 1
]

sum(labeling) == length(mu) # sanity check
outcome_model = OutcomeLinear(n, m, mu, sample_std, labeling)
delay = 0

# Setting up prior
labeling0 = labeling # known labeling
sigma0 = 2
psi = log(2)
D = [0 Inf; Inf 0]
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

## fEVI policy
fEVI_policy = fEVIDiscrete(n, m, theta0, Sigma0, sample_std, FX, labeling0)

## fEVIon policy
P = 0
T = 200
fEVIon_policy = fEVIDiscreteOnOff(n, m, theta0, Sigma0, sample_std, FX, P, T, labeling0)

## Biased Coin
p1 = 0.8
pk = vcat([p1], ones(n - 1) * (1 - p1) / (n - 1))
Gweight = [0, 1, 0]
biasedcoin_policy = BiasedCoinPolicyLinear(n, m, theta0, Sigma0, sample_std, FX, labeling0;
    p=pk, weights=Gweight)

## OCBA
ocba_policy = OCBAPolicyLinear(n, m, theta0, Sigma0, sample_std, FX, labeling0)

## RABC
Gweight = [1 / 3, 1 / 3, 1 / 3]
RABC_policy = RABC_OCBA_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, labeling0; p=pk, weights=Gweight)

## Greedy
greedy_policy = GreedyPolicyLinear(n, m, theta0, Sigma0, sample_std, labeling0)

# policies
policies = Dict(
    "random" => random_policy, "TS" => TS_policy,
    "TTTS" => TTTS_policy, "fEVI" => fEVI_policy, "fEVIon" => fEVIon_policy,
    "biasedcoin" => biasedcoin_policy, "RABC" => RABC_policy, "ocba" => ocba_policy,
    "greedy" => greedy_policy
)

# Settings for simulation runs
T = 200
# number of replications (500,000 for production and 10 for debugging)
reps = if length(ARGS) > 0 && ARGS[1] == "prod"
    500000
else
    10
end
post_reps = 50
Xinterest = Float64[
    1 1 1 1;
    0 0 1 1;
    0 1 0 1
]

# run simulation
rng = Xoshiro(121)
results = @time simulation_stochastic_parallel(reps, FX, n, T, policies, outcome_model;
    delay=delay, post_reps=post_reps, rng=rng, Xinterest=Xinterest)

## Save
folder = length(ARGS) > 1 ? ARGS[2] : "mydata"
save("$folder/simple.jld2", results)
