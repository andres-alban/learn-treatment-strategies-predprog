using Weave

out_format = if length(ARGS) > 0 && ARGS[1] == "pdf"
    "md2pdf"
else
    "md2html"
end

folder = if length(ARGS) > 1
    ARGS[2]
else
    "data"
end

weave("all_plots.jl", args=Dict("folder" => folder), doctype=out_format)