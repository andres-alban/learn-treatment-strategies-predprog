julia -p 10 MARS_known.jl > logs/log01.txt 2>&1
julia -p 10 MARS_allprog.jl > logs/log02.txt 2>&1
julia -p 10 MARS_allpred.jl > logs/log03.txt 2>&1
julia -p 10 fiMARS_known.jl > logs/log04.txt 2>&1
julia -p 10 fiMARS_allprog.jl > logs/log05.txt 2>&1
julia -p 10 fiMARS_allpred.jl > logs/log06.txt 2>&1
julia -p 10 contMARS_known.jl > logs/log07.txt 2>&1
julia -p 10 MARS_MC.jl > logs/log08.txt 2>&1
julia -p 10 MARS_RandEpsilon.jl > logs/log09.txt 2>&1
julia -p 10 simple.jl > logs/log10.txt 2>&1
julia -p 10 MARS_known_onoff.jl > logs/log11.txt 2>&1
julia -p 10 MARS_mislabeling.jl > logs/log12.txt 2>&1

julia -p 10 MARS_dynamic.jl > logs/log21.txt 2>&1
julia -p 10 fiMARS_dynamic.jl > logs/log22.txt 2>&1
julia -p 10 Lipkovich.jl > logs/log23.txt 2>&1
julia -p 10 contMARS_delay.jl > logs/log24.txt 2>&1
