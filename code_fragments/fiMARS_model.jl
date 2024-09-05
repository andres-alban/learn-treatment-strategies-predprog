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

mu = [1, 1, -1, -1, -1.5,  # prognostic
      0.5,                 # treatment 4
      1,                   # treatment 5
      0.5,                 # treatment 6
      0.5,                 # treatment 7
      0.5                  # treatment 8
]

outcome_model = OutcomeLinear(n, m, mu, sample_std, labeling)
delay = 0