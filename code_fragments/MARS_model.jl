n = 8 # number of treatments
p = [59, 129, 184, 150] ./ 522 # 4 categories
p_prog = [0.25, 0.5, 0.25] # low, medium, high
FX = CovariatesIndependent([Categorical(p), OrdinalDiscrete(p_prog), OrdinalDiscrete(p_prog)])
FXtilde = CovariatesIndependent([Categorical(p), OrdinalDiscrete(p_prog), OrdinalDiscrete(p_prog)])
m = length(FX)
sample_std = 1.0
labeling = BitVector(
    [1, 1, 1, 1, 1, 0, # prognostic
    0, 0, 0, 0, 0, 0, # treatment 1
    0, 0, 0, 0, 0, 0, # treatment 2
    0, 0, 0, 0, 0, 0, # treatment 3
    1, 0, 0, 0, 0, 0, # treatment 4
    0, 1, 0, 0, 0, 0, # treatment 5
    0, 1, 0, 0, 0, 0, # treatment 6
    0, 1, 0, 0, 0, 0, # treatment 7
    0, 1, 0, 0, 0, 0, # treatment 8
])

# Setting up nature's distribution
theta_nat = zeros(sum(labeling))
Sigma_nat = 4 * diagm(ones(sum(labeling)))
# Positive correlation for the predictive coefficients
Sigma_nat[7:10, 7:10] = [4 1 1 0.5;
    1 4 0.5 1;
    1 0.5 4 1;
    0.5 1 1 4]

outcome_model = OutcomeLinearBayes(n, m, theta_nat, Sigma_nat, sample_std, labeling)
delay = 0