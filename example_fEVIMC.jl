using ContextualBandits

n = 3
gn = 2
p = [1 / 2, 1 / 2]
theta = [0, 0, # treatment 1
      0.1, 0.1, # treatment 2
      0.1, 0.1] # treatment 3
Sigma = [1 0.5 0.0 0.0 0.0 0.0;
      0.5 1 0.0 0.0 0.0 0.0;
      0.0 0.0 1 0 0 0;
      0.0 0.0 0 1 0 0;
      0.0 0.0 0 0 0 -0.5;
      0.0 0.0 0 0 -0.5 1]
sample_std = ones(6)


gt = 1 # gt = 1 corresponds to X_{t+1} = [1,0]
# gt = 2 # gt = 2 corresponds to X_{t+1} = [0,1]

fEVI_index_partial = exp.(ContextualBandits.fEVIaux(n, gn, theta, Sigma, sample_std, gt))

fEVI_index = exp.(ContextualBandits.fEVI(n, gn, theta, Sigma, sample_std, gt, p))
