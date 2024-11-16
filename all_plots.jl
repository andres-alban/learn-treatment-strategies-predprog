#' Learning Personalized Treatment Strategies with Predictive and Prognostic Covariates in Adaptive Clinical Trials
#' ================================
#' ##### Andres Alban, Stephen E. Chick, Spyros I. Zoumpoulis

#+ echo=false, results = "hidden"
using Printf
# plot utilities
include("code_fragments/generic_plot.jl")


# use pgfplots as the backend only if pdflatex is installed
try
    read(`pdflatex --version`)
    pgfplotsx()
    PGFPlotsX.latexengine!(PGFPlotsX.PDFLATEX)
catch
    println("Could not find pdflatex.")
end

#' ## Figures in Main Paper

#+ echo = false, results = "hidden"
## Application 1: MARS
results1 = load_results("MARS_known")
results_allprog = load_results("MARS_allprog")
results_allpred = load_results("MARS_allpred")
resultsdyn = load_results("MARS_dynamic")
results1["fEVIallprog"] = results_allprog["fEVI"]
results1["fEVIallpred"] = results_allpred["fEVI"]
results1["dynamic_fEVI_LassoCV_1se_rev"] = resultsdyn["dynamic_fEVI_LassoCV_1se_rev"]
results1["dynamic_fEVI_LassoCV_1se"] = resultsdyn["dynamic_fEVI_LassoCV_1se"]
results1["dynamic_fEVI_LassoCV_min"] = resultsdyn["dynamic_fEVI_LassoCV_min"]

policy_keys_1 = ["fEVI", "TTTS", "RABC", "TS", "random", "fEVIon"]
policy_labels_1 = [L"$f$EVI", "TTTS", "RABC", "TS", "Random", L"$f$EVI$^{\textup{on}}$"]
ylims_1 = (0.001, 2)
yticks_1 = [10.0^i for i in -3:0]

#' ### Figure 2a
#+ echo = false
generic_plot(results1, filename="MARS_known", result_key="regret_off", ylabel="EOC",
    file_extension="pdf", legend_location=:topright, policy_keys=policy_keys_1, policy_labels=policy_labels_1, ylims=ylims_1, yticks=yticks_1, T=600)

#' Reported numbers for MARS application
#+ echo = false
function mean_se_policy(results, policy, T=600, result_key="regret_off")
    off = endswith(result_key, "off")
    m = results[policy][result_key]["mean"][T+off]
    se = results[policy][result_key]["std"][T+off] / sqrt(results[policy][result_key]["n"][T+off])
    println(policy, ": ", @sprintf("%.2e", m), " ± ", @sprintf("%.2e", se))
    return m, se
end
fEVI = mean_se_policy(results1, "fEVI")
TTTS = mean_se_policy(results1, "TTTS")
RABC = mean_se_policy(results1, "RABC")
TS = mean_se_policy(results1, "TS")
random = mean_se_policy(results1, "random")
fEVIon = mean_se_policy(results1, "fEVIon")
function find_first_below(arr, target)
    for i in eachindex(arr)
        if arr[i] < target
            return i - 1
        end
    end
    return nothing
end
println("fEVI sample size to be below random: ", find_first_below(results1["fEVI"]["regret_off"]["mean"], random[1]))
println("TTTS sample size to be below random: ", find_first_below(results1["TTTS"]["regret_off"]["mean"], random[1]))
println("RABC sample size to be below random: ", find_first_below(results1["RABC"]["regret_off"]["mean"], random[1]))
println("TS sample size to be below random: ", find_first_below(results1["TS"]["regret_off"]["mean"], random[1]))

#+ echo=false, results = "hidden"
## Application 2: Lipkovich
results2 = load_results("Lipkovich")
# "void" entries are meant to keep the same line style as the Mars experiments
policy_keys_2 = ["fEVI_MC_known", "random_known", "void", "TS_known", "void", "fEVI_MCon_known"]
policy_labels_2 = [L"$f$EVI-MC", "TTTS/Random", "void", "TS", "void", L"$f$EVI-MC$^{\textup{on}}$"]
subset_2 = findall(policy_keys_2 .!= "void")
ylims = (0.002, 0.06)

#' ### Figure 2b
#+ echo = false
generic_plot(results2, filename="Lipkovich", result_key="regret_off", ylabel="EOC", file_extension="pdf", legend_location=:topright, policy_keys=policy_keys_2, policy_labels=policy_labels_2, ylims=ylims, xtick_step=300, thin_step=80, T=:auto, subset=subset_2)

#' Reported numbers for Lipkovich application
#+ echo = false
fEVI_MCon = mean_se_policy(results2, "fEVI_MCon_known", 2400)
println("fEVI-MC sample size to be below fEVI_MCon: ", find_first_below(results2["fEVI_MC_known"]["regret_off"]["mean"], fEVI_MCon[1]))
println("TTTS/Random sample size to be below fEVI_MCon: ", find_first_below(results2["random_known"]["regret_off"]["mean"], fEVI_MCon[1]))
println("TS sample size to be below fEVI_MCon: ", find_first_below(results2["TS_known"]["regret_off"]["mean"], fEVI_MCon[1]))


#' ### Figure 3a
#+ echo = false
results_MC = load_results("MARS_MC")
results_MC["fEVI"] = results1["fEVI"]
policy_keys_MC = ["fEVI", "fEVI_MC_50", "fEVI_MC_20", "fEVI_MC_5", "fEVI_MC_1"]
policy_labels_MC = [L"$f$EVI", L"$f$EVI-MC $\eta^{\textup{off}}=50$", L"$f$EVI-MC $\eta^{\textup{off}}=20$", L"$f$EVI-MC $\eta^{\textup{off}}=5$", L"$f$EVI-MC $\eta^{\textup{off}}=1$"]

generic_plot(results_MC, filename="MARS_MC", result_key="regret_off", ylabel="EOC", file_extension="pdf", legend_location=:topright, policy_keys=policy_keys_MC, policy_labels=policy_labels_MC, ylims=ylims_1, T=600, yticks=yticks_1)


#' ### Figure 3b
#+ echo = false
results_delay = load_results("contMARS_delay20")
results_delay50 = load_results("contMARS_delay50")
results_cont = load_results("contMARS_known")
merge!(results_delay, results_delay50)
results_delay["fEVI_MC_0_1_100"] = results_cont["fEVIMC"]
results_delay["fEVI_MCon_0_1_100"] = results_cont["fEVIMCon"]
policy_keys_delay = ["fEVI_MC_0_1_100", "fEVI_MC_20_25_10", "fEVI_MC_50_25_10", "fEVI_MC_blind_20_1_100", "fEVI_MC_blind_50_1_100"]
policy_labels_delay = [L"\Delta=0", L"\Delta=20", L"\Delta=50", L"$\Delta=20$ (blind)", L"$\Delta=50$ (blind)"]
generic_plot(results_delay, filename="MARS_delay", result_key="regret_off", ylabel="EOC", file_extension="pdf", legend_location=:topright, policy_keys=policy_keys_delay, policy_labels=policy_labels_delay, ylims=ylims_1, T=600, yticks=yticks_1)

#' ### Figure 4a
#+ echo = false
ylims_on1 = (0, 710)
generic_plot(results1, filename="MARS", result_key="cumulregret_on", ylabel="Cumulative regret", file_extension="pdf", legend_location=:topleft, policy_keys=policy_keys_1, policy_labels=policy_labels_1, ylims=ylims_on1, T=600)

#' ### Figure 4b
#+ echo = false
subset = [2, 4, 6]
ylims_on1 = (0, 55)
generic_plot(results1, filename="MARS_subset", result_key="cumulregret_on", ylabel="Cumulative regret", file_extension="pdf", legend_location=:bottomright, policy_keys=policy_keys_1, policy_labels=policy_labels_1, ylims=ylims_on1, T=600, subset=subset)

#' ### Figure 5a
#+ echo = false
policy_keys_1b = ["fEVI", "dynamic_fEVI_LassoCV_1se_rev", "dynamic_fEVI_LassoCV_min", "fEVIallpred", "fEVIallprog"]
policy_labels_1b = [L"$f$EVI$_{\textup{known}}$", L"$f$EVI$_{\textup{Lasso}(-1se)}$", L"$f$EVI$_{\textup{Lasso}(min)}$", L"$f$EVI$_{\textup{all-pred}}$", L"$f$EVI$_{\textup{all-prog}}$"]
generic_plot(results1, filename="MARS_dynamic", result_key="regret_off", ylabel="EOC", file_extension="pdf", legend_location=:topright, policy_keys=policy_keys_1b, policy_labels=policy_labels_1b, ylims=ylims_1, T=600, yticks=yticks_1)

#' ### Figure 5b
#+ echo = false
policy_keys_2dyn = ["fEVI_MC_known", "dynamic_fEVI_MC_LassoCV_1se_rev", "dynamic_fEVI_MC_LassoCV_min", "fEVI_MC_allpred", "fEVI_MC_allprog"]
policy_labels_2dyn = [L"$f$EVI-MC$_{\textup{known}}$", L"$f$EVI-MC$_{\textup{Lasso}(-1se)}$", L"$f$EVI-MC$_{\textup{Lasso}(min)}$", L"$f$EVI-MC$_{\textup{all-pred}}$", L"$f$EVI-MC$_{\textup{all-prog}}$"]
ylims = (0.002, 0.06)
generic_plot(results2, filename="Lipkovich_dynamic", result_key="regret_off", ylabel="EOC", file_extension="pdf", legend_location=(0.62, 0.63), policy_keys=policy_keys_2dyn, policy_labels=policy_labels_2dyn, ylims=ylims, xtick_step=300, thin_step=80, T=:auto)

#' ## Figures in Appendix

#' ### Figure EC.1a
#+ echo = false
ylims_pics1 = (0.01, 1.5)
generic_plot(results1, filename="MARS", result_key="PICS_off", ylabel="PICS", file_extension="pdf", legend_location=:topright, policy_keys=policy_keys_1, policy_labels=policy_labels_1, ylims=ylims_pics1, T=600, yticks=[10.0^i for i in -2:0.5:0])

#' ### Figure EC.1b
#+ echo = false
ylims = (0.09, 1.2)
generic_plot(results2, filename="Lipkovich", result_key="PICS_off", ylabel="PICS", file_extension="pdf", legend_location=:topright, policy_keys=policy_keys_2, policy_labels=policy_labels_2, ylims=ylims, xtick_step=300, thin_step=80, T=:auto, subset=subset_2, yticks=[10.0^i for i in -0.9:0.3:0])

#' ### Figure EC.2
#+ echo = false
policy_keys_2on = ["fEVI_MC_known", "random_known", "void", "TS_known", "void", "fEVI_MCon_known"]
policy_labels_2on = [L"$f$EVI-MC", "TTTS/Random", "void", "TS", "void", L"$f$EVI-MC$^{\textup{on}}$"]
subset_2 = findall(policy_keys_2on .!= "void")
ylims_on_2 = (0, 130)
generic_plot(results2, filename="Lipkovich", result_key="cumulregret_on", ylabel="Cumulative regret", file_extension="pdf", legend_location=:topleft, policy_keys=policy_keys_2on, policy_labels=policy_labels_2on, ylims=ylims_on_2, xtick_step=300, thin_step=80, T=:auto, subset=subset_2, yticks=0:20:120)

#' ### Figure EC.3a
#+ echo = false
results_eps = load_results("MARS_RandEpsilon")
results_eps["random"] = results1["random"]
policy_keys_eps = ["fEVI", "fEVI_eps0.05", "fEVI_eps0.1", "fEVI_eps0.2", "random", "fEVI_eps0.5"]
policy_labels_eps = [L"$f$EVI", L"$f$EVI-rand $\epsilon=0.05$", L"$f$EVI-rand $\epsilon=0.1$", L"$f$EVI-rand $\epsilon=0.2$", "Random", L"$f$EVI-rand $\epsilon=0.5$"]
subset_eps = [1, 2, 3, 4, 6, 5]
generic_plot(results_eps, filename="MARS_RandEpsilon", result_key="regret_off", ylabel="EOC", file_extension="pdf", legend_location=:topright, policy_keys=policy_keys_eps, policy_labels=policy_labels_eps, ylims=ylims_1, T=600, yticks=yticks_1, subset=subset_eps)

#' ### Figure EC.3b
#+ echo = false
policy_keys_eps = ["fEVI_MC", "fEVI_MC_eps0.05", "fEVI_MC_eps0.1", "fEVI_MC_eps0.2", "random", "fEVI_MC_eps0.5"]
policy_labels_eps = [L"$f$EVI-MC", L"$f$EVI-MC-rand $\epsilon=0.05$", L"$f$EVI-MC-rand $\epsilon=0.1$", L"$f$EVI-MC-rand $\epsilon=0.2$", "Random", L"$f$EVI-MC-rand $\epsilon=0.5$"]
generic_plot(results_eps, filename="MARS_RandEpsilonMC", result_key="regret_off", ylabel="EOC", file_extension="pdf", legend_location=:topright, policy_keys=policy_keys_eps, policy_labels=policy_labels_eps, ylims=ylims_1, T=600, yticks=yticks_1, subset=subset_eps)

#' ### Figure EC.4
#+ echo = false
results1F = load_results("fiMARS_known")
results_allprogF = load_results("fiMARS_allprog")
results_allpredF = load_results("fiMARS_allpred")
resultsdynF = load_results("fiMARS_dynamic")
results1F["fEVIallprog"] = results_allprogF["fEVI"]
results1F["fEVIallpred"] = results_allpredF["fEVI"]
results1F["dynamic_fEVI_LassoCV_1se_rev"] = resultsdynF["dynamic_fEVI_LassoCV_1se_rev"]
results1F["dynamic_fEVI_LassoCV_1se"] = resultsdynF["dynamic_fEVI_LassoCV_1se"]
results1F["dynamic_fEVI_LassoCV_min"] = resultsdynF["dynamic_fEVI_LassoCV_min"]

generic_plot(results1F, filename="fiMARS", result_key="regret_off", ylabel="EOC", file_extension="pdf", legend_location=:bottomleft, legend_columns=2, policy_keys=policy_keys_1, policy_labels=policy_labels_1, ylims=ylims_1, T=600, yticks=yticks_1)

#' ### Figure EC.5
#+ echo = false
results_onoff = load_results("MARS_known_onoff")
policy_keys_onoff = ["TTTS", "RABC", "TS", "random"]
policy_labels_onoff = ["TTTS", "RABC", "TS", "Random"]
for k in policy_keys_onoff
    results_onoff[k] = results1[k]
end
for T in [300, 600]
    eoc = [results_onoff["fEVIon"]["regret_off"]["mean"][T+1]]
    eoc_se = [1.96 * results_onoff["fEVIon"]["regret_off"]["std"][T+1] / sqrt(results_onoff["fEVIon"]["regret_off"]["n"][T+1])]
    cumulregret = [results_onoff["fEVIon"]["cumulregret_on"]["mean"][T]]
    cumulregret_se = [1.96 * results_onoff["fEVIon"]["cumulregret_on"]["std"][T] / sqrt(results_onoff["fEVIon"]["cumulregret_on"]["n"][T])]
    for P in [1e3, 1e4, 1e6, 1e7, 1e9, 1e12, 1e15]
        push!(eoc, results_onoff["fEVIonoff_P$(Int(P/1000))k"]["regret_off"]["mean"][T+1])
        push!(eoc_se, 1.96 * results_onoff["fEVIonoff_P$(Int(P/1000))k"]["regret_off"]["std"][T+1] / sqrt(results_onoff["fEVIonoff_P$(Int(P/1000))k"]["regret_off"]["n"][T+1]))
        push!(cumulregret, results_onoff["fEVIonoff_P$(Int(P/1000))k"]["cumulregret_on"]["mean"][T])
        push!(cumulregret_se, 1.96 * results_onoff["fEVIonoff_P$(Int(P/1000))k"]["cumulregret_on"]["std"][T] / sqrt(results_onoff["fEVIonoff_P$(Int(P/1000))k"]["cumulregret_on"]["n"][T]))
    end
    push!(eoc, results_onoff["fEVI"]["regret_off"]["mean"][T+1])
    push!(eoc_se, 1.96 * results_onoff["fEVI"]["regret_off"]["std"][T+1] / sqrt(results_onoff["fEVI"]["regret_off"]["n"][T+1]))
    push!(cumulregret, results_onoff["fEVI"]["cumulregret_on"]["mean"][T])
    push!(cumulregret_se, 1.96 * results_onoff["fEVI"]["cumulregret_on"]["std"][T] / sqrt(results_onoff["fEVI"]["cumulregret_on"]["n"][T]))

    pl = plot(size=(300, 240), xscale=:log10, yscale=:log10,
        ylims=(0.0015, 0.014), xlims=(21, 750),
        yticks=10.0 .^ [-2.6, -2.4, -2.2, -2.0], xticks=10.0 .^ [1.5, 1.75, 2.0, 2.25, 2.5, 2.75],
        ylabel="EOC", xlabel="Cumulative regret", legend=:top,
        fg_legend=:transparent, bg_legend=:transparent, guidefontsize=9, tick_direction=:out, tex_output_standalone=true, legend_font_halign=:left)
    fontsize = 9
    plot!(cumulregret, eoc, yerror=eoc_se, label=L"$f$EVI$^{\textup{on+off}}$", color=palette(:tab10)[1], markerstrokecolor=palette(:tab10)[1], markershape=:circle, markersize=2)
    if T == 600
        annotate!(cumulregret, eoc, [("0", :left, fontsize), ("1k", :left, fontsize), ("10k", :left, fontsize), ("1M", :left, fontsize), ("10M", :left, fontsize), ("1B", :right, fontsize), ("1T", :right, fontsize), ("1Q", :top, fontsize), (L"\infty", :left, fontsize)])
    else
        annotate!(cumulregret, eoc, [("0", :left, fontsize), ("1k", :left, fontsize), ("10k", :left, fontsize), ("1M", :right, fontsize), ("10M", :right, fontsize), ("1B", :top, fontsize), ("1T", :left, fontsize), ("1Q", :top, fontsize), (L"\infty", :left, fontsize)])
    end

    markershapes = [:diamond :cross :pentagon :xcross :utriangle :dtriangle :star5 :hline :star6]
    colors = palette(:tab10)[[4, 2, 3, 5, 6, 7, 8, 9, 10]]
    for (p, l, m, c) in zip(policy_keys_onoff, policy_labels_onoff, markershapes, colors)
        xx = [results_onoff[p]["regret_off"]["mean"][T+1]]
        yy = [results_onoff[p]["cumulregret_on"]["mean"][T]]
        yy_se = 1.96 * results_onoff[p]["regret_off"]["std"][T+1] / sqrt(results_onoff[p]["regret_off"]["n"][T+1])
        scatter!(yy, xx, yerror=yy_se, label=l, markershape=m, color=c, markerstrokecolor=c, markersize=3, markeralpha=0.5, markerstrokealpha=0.8)
    end
    display(pl)
    savefig(pl, "plots/MARS_onoff_pareto_$T.pdf")
end

#' ### Figure EC.5b statistical tests
#+ echo = false
function tstat(r1, r2, T=600, key="regret_off")
    Xbar = r1[key]["mean"][T] - r2[key]["mean"][T]
    v = r1[key]["std"][T]^2 / r1[key]["n"][T] + r2[key]["std"][T]^2 / r2[key]["n"][T]
    Xbar / sqrt(v)
end
TS1on = tstat(results1["TS"], results_onoff["fEVIonoff_P1000k"], 600, "cumulregret_on")
TS1off = tstat(results1["TS"], results_onoff["fEVIonoff_P1000k"], 601, "regret_off")
TS10on = tstat(results1["TS"], results_onoff["fEVIonoff_P10000k"], 600, "cumulregret_on")
TS10off = tstat(results1["TS"], results_onoff["fEVIonoff_P10000k"], 601, "regret_off")
TTTSon = tstat(results1["TTTS"], results_onoff["fEVIonoff_P1000000000k"], 600, "cumulregret_on")
TTTSoff = tstat(results1["TTTS"], results_onoff["fEVIonoff_P1000000000k"], 601, "regret_off")
nothing

#' t-statistics for comparison between $f$EVI$^{on+off}$ policy and TS as well as
#' between $f$EVI$^{on+off}$ and TTTS. t-statistics larger than 1.96 or smaller
#' than -1.96 are considered significant at the 5% confidence level
#' 
#' | $f$EVI$^{on+off}$ with $P$ | Policy for comparison | t-statistic EOC | t-statistic cumulative regret |
#' | -------------------------- | --------------------- | --------------- | ----------------------------- |
#' | 1M                         | TS                    | `j TS1off`      | `j TS1on`                     |
#' | 10M                        | TS                    | `j TS10off`     | `j TS10on`                    |
#' | 1T                         | TTTS                  | `j TTTSoff`     | `j TTTSon`                    |


#' ### Figure EC.6
#+ echo = false
results_mis = load_results("Mars_mislabeling")
merge!(results_mis, results1)

policy_keys_mis = ["fEVI", "dynamic_fEVI_LassoCV_1se_rev", "fEVI_1", "fEVIallpred", "fEVIallprog", "fEVI_2", "fEVI_3", "fEVI_-1", "fEVI_-2", "fEVI_-3"]
policy_labels_mis = [L"$f$EVI$_{\textup{known}}$", L"$f$EVI$_{\textup{Lasso}(-1se)}$", L"$f$EVI$_{\textup{known}+1\textup{pred}}$", L"$f$EVI$_{\textup{all-pred}}$", L"$f$EVI$_{\textup{all-prog}}$",
    L"$f$EVI$_{\textup{known}+2\textup{pred}}$", L"$f$EVI$_{\textup{known}+3\textup{pred}}$", L"$f$EVI$_{\textup{known}-1\textup{pred}}$", L"$f$EVI$_{\textup{known}-2\textup{pred}}$", L"$f$EVI$_{\textup{known}-3\textup{pred}}$"]
subset = [1, 3, 6, 7, 2, 4, 8, 9, 10, 5]
ylims_1 = (0.001, 2)
yticks_1 = [10.0^i for i in -3:0]
generic_plot(results_mis, filename="MARS_mislabeling", result_key="regret_off", ylabel="EOC",
    file_extension="pdf", legend_location=:best, policy_keys=policy_keys_mis, policy_labels=policy_labels_mis, ylims=ylims_1, yticks=yticks_1, T=600, subset=subset)

#' ### Table EC.2
#+ echo = false, results = "hidden"
include("example_fEVIMC.jl")

#' | Scenario for allocation index       | treatment 1                 | treatment 2                 | treatment 3                 |
#' | ----------------------------------- | --------------------------- | --------------------------- | --------------------------- |
#' | $f$EVI-index                        | `j fEVI_index[1]`           | `j fEVI_index[2]`           | `j fEVI_index[3]`           |
#' | $f$EVI-index when $\hat{X}_1=[1,0]$ | `j fEVI_index_partial[1,1]` | `j fEVI_index_partial[1,2]` | `j fEVI_index_partial[1,3]` |
#' | $f$EVI-index when $\hat{X}_1=[0,1]$ | `j fEVI_index_partial[2,1]` | `j fEVI_index_partial[2,2]` | `j fEVI_index_partial[2,3]` |

#' ### Data not shown relating to Figure 5
#+ echo = false
results1["TSallprog"] = results_allprog["TS"]
results1["TSallpred"] = results_allpred["TS"]
policy_keys_1b = ["TS", "void", "void", "TSallpred", "TSallprog"]
policy_labels_1b = [L"TS$_{\textup{known}}$", "void", "void", L"TS$_{\textup{all-pred}}$", L"TS$_{\textup{all-prog}}$"]
subset = findall(policy_keys_1b .!= "void")
display(generic_plot(results1, filename="MARS_dynamic_TS", result_key="regret_off", ylabel="EOC", file_extension="pdf", legend_location=:topright, policy_keys=policy_keys_1b, policy_labels=policy_labels_1b, ylims=ylims_1, T=600, yticks=yticks_1, subset=subset, fig_title="MARS"))

results1["randomallprog"] = results_allprog["random"]
results1["randomallpred"] = results_allpred["random"]
policy_keys_1b = ["random", "void", "void", "randomallpred", "randomallprog"]
policy_labels_1b = [L"Random$_{\textup{known}}$", "void", "void", L"Random$_{\textup{all-pred}}$", L"Random$_{\textup{all-prog}}$"]
subset = findall(policy_keys_1b .!= "void")
display(generic_plot(results1, filename="MARS_dynamic_random", result_key="regret_off", ylabel="EOC", file_extension="pdf", legend_location=:topright, policy_keys=policy_keys_1b, policy_labels=policy_labels_1b, ylims=ylims_1, T=600, yticks=yticks_1, subset=subset, fig_title="MARS"))


policy_keys_2dyn = ["TS_known", "dynamic_TS_LassoCV_1se_rev", "dynamic_TS_LassoCV_min", "TS_allpred", "TS_allprog"]
policy_labels_2dyn = [L"TS$_{\textup{known}}$", L"TS$_{\textup{Lasso}(-1se)}$", L"TS$_{\textup{Lasso}(min)}$", L"TS$_{\textup{all-pred}}$", L"TS$_{\textup{all-prog}}$"]
ylims = (0.002, 0.06)
subset = findall(.!startswith.(policy_keys_2dyn, "dynamic"))
display(generic_plot(results2, filename="Lipkovich_dynamic_TS", result_key="regret_off", ylabel="EOC", file_extension="pdf", legend_location=(0.62, 0.63), policy_keys=policy_keys_2dyn, policy_labels=policy_labels_2dyn, ylims=ylims, xtick_step=300, thin_step=80, T=:auto, subset=subset, fig_title="Lipkovich"))

policy_keys_2dyn = ["random_known", "dynamic_random_LassoCV_1se_rev", "dynamic_random_LassoCV_min", "random_allpred", "random_allprog"]
policy_labels_2dyn = [L"Random$_{\textup{known}}$", L"Random$_{\textup{Lasso}(-1se)}$", L"Random$_{\textup{Lasso}(min)}$", L"Random$_{\textup{all-pred}}$", L"Random$_{\textup{all-prog}}$"]
ylims = (0.002, 0.06)
subset = findall(.!startswith.(policy_keys_2dyn, "dynamic"))
generic_plot(results2, filename="Lipkovich_dynamic_random", result_key="regret_off", ylabel="EOC", file_extension="pdf", legend_location=(0.62, 0.63), policy_keys=policy_keys_2dyn, policy_labels=policy_labels_2dyn, ylims=ylims, xtick_step=300, thin_step=80, T=:auto, subset=subset, fig_title="Lipkovich")
