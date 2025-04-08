julia -p auto MARS_known.jl debug > logs/log01.txt 2>&1
julia -p auto MARS_allprog.jl debug > logs/log02.txt 2>&1
julia -p auto MARS_allpred.jl debug > logs/log03.txt 2>&1
julia -p auto fiMARS_known.jl debug > logs/log04.txt 2>&1
julia -p auto fiMARS_allprog.jl debug > logs/log05.txt 2>&1
julia -p auto fiMARS_allpred.jl debug > logs/log06.txt 2>&1
julia -p auto contMARS_known.jl debug > logs/log07.txt 2>&1
julia -p auto MARS_MC.jl debug > logs/log08.txt 2>&1
julia -p auto MARS_RandEpsilon.jl debug > logs/log09.txt 2>&1
julia -p auto simple.jl debug > logs/log10.txt 2>&1
julia -p auto MARS_known_onoff.jl debug > logs/log11.txt 2>&1
julia -p auto MARS_mislabeling.jl debug > logs/log12.txt 2>&1

julia -p auto MARS_dynamic.jl debug > logs/log21.txt 2>&1
julia -p auto fiMARS_dynamic.jl debug > logs/log22.txt 2>&1
julia -p auto Lipkovich.jl debug > logs/log23.txt 2>&1
julia -p auto contMARS_delay.jl debug > logs/log24.txt 2>&1
