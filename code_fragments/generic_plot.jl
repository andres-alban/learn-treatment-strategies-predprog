using Plots
using LaTeXStrings
using JLD2

mkpath("plots/")

function generic_plot(results;
    filename="a", file_extension="png",
    fig_size=(300, 240), fig_title="",
    result_key="regret_off", ylabel=result_key,
    ylims=:auto, T=:auto,
    yticks=:auto, xtick_step=100, thin_step=20,
    legend_location=:best, legend_columns=1,
    policy_keys=[], policy_labels=[],
    error_area=false,
    subset=1:length(policy_keys))

    # Get parameters
    policy_keys = policy_keys[subset]
    policy_labels = policy_labels[subset]
    if isempty(policy_keys)
        policy_keys = collect(keys(results))
        subset = 1:length(policy_keys)
    end
    if length(policy_keys) != length(policy_labels)
        policy_labels = policy_keys
    end
    if T == :auto
        T = length(results[policy_keys[1]]["regret_on"]["mean"])
    end

    # Setup styling for the plots
    colors = permutedims(reverse(palette(:tab10)[[1, 4, 2, 3, 5, 6, 7, 8, 9, 10]][subset]))
    linestyles = reverse([:solid :solid :solid :solid :solid :solid :solid :solid :solid :solid][:, subset])
    markershapes = reverse([:circle :diamond :vline :pentagon :xcross :utriangle :dtriangle :star5 :hline :star6][:, subset])
    markersizes = reverse([3 4 4 3 4 4 4 4 4 4][:, subset])
    markerwidths = reverse([1 1 1 1 1 1 1 1 1 1][:, subset])
    markeralphas = reverse([0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5][:, subset])


    off = occursin("off", result_key)
    cumul = occursin("cumul", result_key)
    SampleSize = (off ? 0 : 1):T
    thin = 1:thin_step:(T+off)

    # create data set for plotting
    x = SampleSize[thin]
    y = Matrix{Float64}(undef, length(thin), length(policy_keys))
    yup = Matrix{Float64}(undef, length(thin), length(policy_keys))
    ydown = Matrix{Float64}(undef, length(thin), length(policy_keys))
    for i in eachindex(policy_keys)
        index = length(policy_keys) - i + 1
        y[:, index] = results[policy_keys[i]][result_key]["mean"][thin]
        yup[:, index] = results[policy_keys[i]][result_key]["mean"][thin] + results[policy_keys[i]][result_key]["std"][thin] ./ sqrt.(results[policy_keys[i]][result_key]["n"][thin])
        ydown[:, index] = results[policy_keys[i]][result_key]["mean"][thin] - results[policy_keys[i]][result_key]["std"][thin] ./ sqrt.(results[policy_keys[i]][result_key]["n"][thin])
    end
    # exclude bad data for logarithmic scale
    if !cumul
        y[y.==0] .= minimum(y[y.>0])
        yup[yup.==0] .= minimum(yup[yup.>0])
        ydown[ydown.<=0] .= minimum(ydown[ydown.>0])
    end

    # plot the data
    pl = plot(x, y,
        label=permutedims(reverse(policy_labels)), color=colors, linestyle=linestyles,
        markershape=markershapes, markerstrokecolor=colors, markersize=markersizes, markerstrokewidth=markerwidths,
        markeralpha=markeralphas, markerstrokealpha=markeralphas,
        size=fig_size,
        legend=legend_location, legend_columns=legend_columns, fg_legend=:transparent, bg_legend=:transparent, grid=true, guidefontsize=9, xlabel=L"Sample size ($T$)", ylabel=ylabel,
        xlims=(0, T * 1.02), ylims=ylims, tick_direction=:out, yticks=yticks, xticks=collect(0:xtick_step:T), yscale=cumul ? :identity : :log10, tex_output_standalone=true,
        legend_font_halign=:left, title=fig_title)
    if error_area
        plot!(x, yup, fillrange=ydown, label="", fillcolor=colors, fillalpha=0.3, linecolor=nothing)
    end

    savefig(pl, "plots/$(filename)_$(result_key).$(file_extension)")
    return pl
end

function load_results(filename)
    return load("data/$(filename).jld2", "output")
end