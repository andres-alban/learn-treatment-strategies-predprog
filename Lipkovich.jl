# On our setup, this file runs in about
# 37h 45min
using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using ContextualBandits
using Random
using Distributions
using Statistics
using JLD2
using LinearAlgebra

# helper functions to define the interactions
## return a vector of interaction functions that interact every covariate with eachother
function twowayinteractions(n)
    out = Vector{Function}(undef, n * (n + 1) ÷ 2)
    index = 1
    for i in 1:n
        for j in i:n
            out[index] = (x) -> x[i] * x[j]
            index += 1
        end
    end
    return out
end

# Return the location of each interaction in the same order as the vector of interaction functions
function index_interaction(i, j, n)
    # force i to be the smaller value
    if i > j
        i, j = j, i
    end
    return sum((n-i+1):n) + j + 1
end

# CovariatesGenerator
n = 2
FX = CovariatesIndependent(repeat([Normal()], 11))
FX = CovariatesInteracted(FX, twowayinteractions(length(FX)))
m = length(FX)
sample_std = 0.5

# From Lipkovich Figure 9
m_base = 11 # Number of baseline covariates
indices = [
    index_interaction(0, 4, m_base),
    index_interaction(0, 1, m_base),
    index_interaction(0, 6, m_base),
    index_interaction(1, 3, m_base) + m, # we add m when the treatment is interacted
    index_interaction(0, 7, m_base),
    index_interaction(0, 10, m_base),
    index_interaction(2, 8, m_base) + m,
    index_interaction(0, 1, m_base) + m,
    index_interaction(1, 1, m_base),
    index_interaction(5, 5, m_base),
    index_interaction(1, 7, m_base) + m,
    index_interaction(11, 11, m_base),
    index_interaction(1, 10, m_base) + m,
    index_interaction(9, 9, m_base),
    index_interaction(7, 7, m_base) + m,
    index_interaction(5, 8, m_base),
    index_interaction(2, 2, m_base) + m,
    index_interaction(5, 11, m_base) + m,
    index_interaction(3, 3, m_base),
    index_interaction(5, 5, m_base) + m,
    index_interaction(2, 7, m_base),
    index_interaction(3, 3, m_base) + m,
]

labeling = zeros(Bool, m * (n + 1))
labeling[indices] .= true
mu = Vector{Float64}(undef, length(indices))
mu[sortperm(indices)] .= [-0.3041, -0.2057, -0.1578, -0.1476, -0.1469, -0.1031, -0.0771, 0.0637, -0.0600, 0.0425, 0.0329, -0.0313, -0.0252, -0.0177, 0.0151, 0.0151, -0.0136, -0.0095, 0.0069, -0.0054, 0.0049, 0.0035]

outcome_model = OutcomeLinear(n, m, mu, sample_std, labeling)

# fraction of patients for which treatment is beneficial
X = rand(FX, 10000)
expected_outcomes = [[ContextualBandits.mean_outcome(outcome_model, w, view(X, :, i)) for w in 1:n] for i in axes(X, 2)]
fadopt = argmax.(expected_outcomes)
sum(fadopt .== 2)

# Setting up labeling list
labeling0_list = Dict{String,Vector{Bool}}()
# All pred
labeling0_list["allpred"] = zeros(Bool, size(labeling))
labeling0_list["allpred"][1:(2*m)] .= true
# All prog
labeling0_list["allprog"] = zeros(Bool, size(labeling))
labeling0_list["allprog"][1:(m+1)] .= true
# known labeling
labeling0_list["known"] = labeling

# Setting up subgroup list for ocba policy
predictive_list = Dict{String,Vector{Int}}()
predictive_list["allpred"] = 1:m
predictive_list["allprog"] = [1]
# known labeling
predictive_list["known"] = [
    index_interaction(1, 3, m_base),
    index_interaction(2, 8, m_base),
    index_interaction(0, 1, m_base),
    index_interaction(1, 7, m_base),
    index_interaction(1, 10, m_base),
    index_interaction(7, 7, m_base),
    index_interaction(2, 2, m_base),
    index_interaction(5, 11, m_base),
    index_interaction(5, 5, m_base),
    index_interaction(3, 3, m_base),
]

# Setting up prognostic list for biasedcoin and Hu policies
prognostic_list = Dict{String,Vector{Vector{Int}}}()
prognostic_list["allpred"] = [[]]
prognostic_list["allprog"] = [[i] for i in 2:m]
# known labeling
prognostic_list["known"] = [
    [index_interaction(0, 4, m_base)],
    [index_interaction(0, 1, m_base)],
    [index_interaction(0, 6, m_base)],
    [index_interaction(0, 7, m_base)],
    [index_interaction(0, 10, m_base)],
    [index_interaction(1, 1, m_base)],
    [index_interaction(5, 5, m_base)],
    [index_interaction(11, 11, m_base)],
    [index_interaction(9, 9, m_base)],
    [index_interaction(5, 8, m_base)],
    [index_interaction(3, 3, m_base)],
    [index_interaction(2, 7, m_base)],
]

policies = Dict{String,Policy}()

for (name, labeling0) in labeling0_list
    theta0 = zeros(sum(labeling0))
    Sigma0 = diagm(1e6 * ones(sum(labeling0)))

    # random policy
    random_policy = RandomPolicyLinear(n, m, theta0, Sigma0, sample_std, labeling0)
    policies["random_"*name] = random_policy

    # fEVI-MC policy
    etaon = 1
    etaoff = 100
    fevimc_policy = fEVI_MC_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, labeling0)
    policies["fEVI_MC_"*name] = fevimc_policy

    # fEVI-MC^on policy
    T = 2400
    delay = 0
    P = 0
    fevimcon_policy = fEVI_MC_OnOff_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, T, delay, P, labeling0)
    policies["fEVI_MCon_"*name] = fevimcon_policy

    ## Thompson sampling
    TS_policy = TSPolicyLinear(n, m, theta0, Sigma0, sample_std, labeling0)
    policies["TS_"*name] = TS_policy

    ## RABC
    pk = [0.8, 0.2]
    prognostic = prognostic_list[name]
    Gweight = ones(length(prognostic) + 2) ./ (length(prognostic) + 2)
    predictive = predictive_list[name]
    RABC_policy = RABC_OCBA_PolicyLinear(n, m, theta0, Sigma0, sample_std, predictive, prognostic, labeling0; p=pk, weights=Gweight)
    policies["RABC_"*name] = RABC_policy
end

# dynamic policies
labeling0 = labeling0_list["allpred"]
labeling0[1] = false
theta0 = zeros(sum(labeling0))
Sigma0 = diagm(1e6 * ones(sum(labeling0)))
schedule = (4:24) .^ 2
sigma0 = 1e6
psi = log(2)
D = [0 Inf; Inf 0]
z_alpha = 0
c = 1

selectors = Dict{String,LassoCVLabelingSelector}(
    "LassoCV_min" => LassoCVLabelingSelector(n, m, 0, labeling0),
    "LassoCV_1se" => LassoCVLabelingSelector(n, m, 1, labeling0),
    "LassoCV_1se_rev" => LassoCVLabelingSelector(n, m, -1, labeling0)
)

etaon = 1
etaoff = 100
fevimc_policy = fEVI_MC_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, labeling0)
T = 2400
delay = 0
P = 0
fevimcon_policy = fEVI_MC_OnOff_PolicyLinear(n, m, theta0, Sigma0, sample_std, FX, etaon, etaoff, T, delay, P, labeling0)
TS_policy = TSPolicyLinear(n, m, theta0, Sigma0, sample_std, labeling0)
for (name, selector) in selectors
    dynamic_fEVI_MC = InferLabelingPolicy(fevimc_policy, selector, schedule, labeling0; sigma0, psi, D, z_alpha, c)
    policies["dynamic_fEVI_MC_"*name] = dynamic_fEVI_MC

    dynamic_fEVI_MCon = InferLabelingPolicy(fevimcon_policy, selector, schedule, labeling0; sigma0, psi, D, z_alpha, c)
    policies["dynamic_fEVI_MCon_"*name] = dynamic_fEVI_MCon

    dynamic_TS = InferLabelingPolicy(TS_policy, selector, schedule, labeling0; sigma0, psi, D, z_alpha, c)
    policies["dynamic_TS_"*name] = dynamic_TS
end

# run simulation
T = 2400
# number of replications (5000 for production and 10 for debugging)
reps = if length(ARGS) > 0 && ARGS[1] == "prod"
    5000
else
    10
end
post_reps = 50
delay = 0
pilot_samples_per_treatment = 80
rng = Xoshiro(121)
results = @time simulation_stochastic_parallel(reps, FX, n, T, policies, outcome_model;
    delay=delay, post_reps=post_reps, rng=rng)


## Save
folder = length(ARGS) > 1 ? ARGS[2] : "mydata"
save("$folder/Lipkovich.jld2", results)