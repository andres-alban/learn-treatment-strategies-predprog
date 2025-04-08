julia -p 10 MARS_known.jl prod data > logs/log01.txt 2>&1
julia -p 10 MARS_allprog.jl prod data > logs/log02.txt 2>&1
julia -p 10 MARS_allpred.jl prod data > logs/log03.txt 2>&1
julia -p 10 fiMARS_known.jl prod data > logs/log04.txt 2>&1
julia -p 10 fiMARS_allprog.jl prod data > logs/log05.txt 2>&1
julia -p 10 fiMARS_allpred.jl prod data > logs/log06.txt 2>&1
julia -p 10 contMARS_known.jl prod data > logs/log07.txt 2>&1
julia -p 10 MARS_MC.jl prod data > logs/log08.txt 2>&1
julia -p 10 MARS_RandEpsilon.jl prod data > logs/log09.txt 2>&1
julia -p 10 simple.jl prod data > logs/log10.txt 2>&1
julia -p 10 MARS_known_onoff.jl prod data > logs/log11.txt 2>&1
julia -p 10 MARS_mislabeling.jl prod data > logs/log12.txt 2>&1

julia -p 10 MARS_dynamic.jl prod data > logs/log21.txt 2>&1
julia -p 10 fiMARS_dynamic.jl prod data > logs/log22.txt 2>&1
julia -p 10 Lipkovich.jl prod data > logs/log23.txt 2>&1
julia -p 10 contMARS_delay.jl prod data > logs/log24.txt 2>&1
