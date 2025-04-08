julia -p auto MARS_known.jl prod > logs/log01.txt 2>&1
julia -p auto MARS_allprog.jl prod > logs/log02.txt 2>&1
julia -p auto MARS_allpred.jl prod > logs/log03.txt 2>&1
julia -p auto fiMARS_known.jl prod > logs/log04.txt 2>&1
julia -p auto fiMARS_allprog.jl prod > logs/log05.txt 2>&1
julia -p auto fiMARS_allpred.jl prod > logs/log06.txt 2>&1
julia -p auto contMARS_known.jl prod > logs/log07.txt 2>&1
julia -p auto MARS_MC.jl prod > logs/log08.txt 2>&1
julia -p auto MARS_RandEpsilon.jl prod > logs/log09.txt 2>&1
julia -p auto simple.jl prod > logs/log10.txt 2>&1
julia -p auto MARS_known_onoff.jl prod > logs/log11.txt 2>&1
julia -p auto MARS_mislabeling.jl prod > logs/log12.txt 2>&1

julia -p auto MARS_dynamic.jl prod > logs/log21.txt 2>&1
julia -p auto fiMARS_dynamic.jl prod > logs/log22.txt 2>&1
julia -p auto Lipkovich.jl prod > logs/log23.txt 2>&1
julia -p auto contMARS_delay.jl prod > logs/log24.txt 2>&1
