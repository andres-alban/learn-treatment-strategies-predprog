# On our setup, this file runs in about
# 9h 0min
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
include("code_fragments/fiMARS_model.jl")

## Dynamic fEVI
# For the creation of fEVIDiscrete, theta0, Sigma0, and labeling are irrelevant because they will be overwritten by the InferLabelingPolicy
fEVI_policy = fEVIDiscrete(n, m, zeros((n + 1) * m), diagm(ones((n + 1) * m)), sample_std, FX, trues((n + 1) * m))
labeling0 = [falses(m); trues(n * m)] # all pred labeling until the first updated of the labeling
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
z_alpha = 2
c = 4

schedule = (4:24) .^ 2
selectors = Dict("LassoCV_min" => LassoCVLabelingSelector(n, m),
    "LassoCV_1se" => LassoCVLabelingSelector(n, m, 1),
    "LassoCV_1se_rev" => LassoCVLabelingSelector(n, m, -1))
policies = Dict{String,Policy}()
for (name, selector) in selectors
    dynamic_fEVI = InferLabelingPolicy(fEVI_policy, selector, schedule, labeling0; sigma0, psi, D, z_alpha, c)
    policies["dynamic_fEVI_"*name] = dynamic_fEVI
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
save("$folder/fiMARS_dynamic.jld2", results)
