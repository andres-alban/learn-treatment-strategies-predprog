# Learning Personalized Treatment Strategies with Predictive and Prognostic Covariates in Adaptive Clinical Trials

This repository provides all the necessary resources to replicate the results of
[Alban A, Chick SE, Zoumpoulis SI (2024) Learning Personalized Treatment Strategies with Predictive and Prognostic Covariates in Adaptive Clinical Trials](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4160045). The [ContextualBandits](https://github.com/andres-alban/ContextualBandits.jl) package was developed to obtain the results. We refer the user to its [documentation](http://www.andresalban.com/ContextualBandits.jl/) for further explanation on the structure of the code.

## Requirements
- Julia 1.10 was used to run the experiments (Julia versions 1.7 or later probably replicate the same results, but it has not been tested). To install Julia follow the instructions at [https://julialang.org/downloads](https://julialang.org/downloads).
- (optional) pdflatex is used to create the figures as presented in the paper. If you do not have pdflatex installed, the code still outputs figures but in a different format.

## Installation
Create a local copy of this repository. Open the terminal at the location of the root the repository and run `julia`. The julia REPL will start. Type `]` to enter the Pkg REPL mode and run

```
pkg> activate .
pkg> instantiate
```
All packages required to run the code will be automatically installed.

> Note: We provide a `Manifest.toml` file to ensure that the same package versions used to run the experiments are installed. If you are running a different version of julia that errors when you instantiate the packages, you may try deleting the `Manifest.toml` file and running `pkg> add https://github.com/andres-alban/ContextualBandits.jl.git#v0.1.0` before running `pkg> instantiate`.


## Replication

The replication of the results is obtained in two steps: 1. simulation and 2. plotting. The simulation step will generate data that is saved to the `data/` folder. Because the simulation requires a lot of computational resources, we provide the data files for those users that are only interested in exploring the data and doing the plots. Those users can skip the simulation section.

### 1. Simulation
All julia files in the root directory, except `all_plots.jl` simulate data that is saved to the `data/` folder. We do not provide a julia file that runs all simulations, but we provide a `run.bat` file that provides all the command lines required to run each of them. On windows, you can simply run `.\run.bat`, but we recommend that you understand how long each simulation is going to take before running each command. The duration of each simulation may range from an hour to several days.

> We run the commands on a DELL computer with a 12th Gen Intel Core i7 CPU on ten cores. The `-p` flag on the commands determines how many parallel processes you want to use. At the top of each simulation file, we report how long it took to run on our setup for guidance on the time required for each simulation. We recommend that you run the simulation with a small number of replications (set `reps=10` in the file of the simulation) to estimate how long it will take to run the full simulation (usually `reps=5,000`). The simulation files always print the duration.

The first part of each simulation file describes the setting of the experiment:
1. MARS: MARS Application
2. Lipkovich: application based on the Lipkovich et al. (2017) paper
3. contMARS: MARS application modified to let some covariates be continuous.
4. fiMARS: fixed instance modification of MARS application to test a difficult configuration.

The rest of the name refers to additional details of the experiment. For example, `MARS_allpred.jl` refers to the experiment with the MARS application setting and policies that use the all-pred labeling.

### 2. Plotting
You can recreate all the plots running the `all_plots.jl` file.
```
julia --project all_plots.jl
```
All plots will be saved in the `plots/` folder as pdf files.

You can also create a single document with all the figures using [Weave.jl](https://weavejl.mpastell.com/stable/) by running the following commands in the terminal:

- for html output (the created `all_plots.html` file can be opened in your browser)
```
julia --project -e "using Weave; weave(ARGS[1])" all_plots.jl
```

- for pdf output (requires a latex installation)
```
julia --project -e "using Weave; weave(ARGS[1], doctype=ARGS[2])" all_plots.jl md2pdf
```