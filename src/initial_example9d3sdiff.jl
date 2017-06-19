include("GreenNMFk.jl")
import GreenNMFk

#Start stopwatch timer
tic()

# Initialize simulation variables
max_number_of_sources = 9	# Number of sources
Nsim = 100 					# Number of simulations
numT = 80					# Number of time points
time = linspace(0, 20, numT)

# Initialize equation parameters
u = 0.05 # (km/yr) - flow speed
D = [0.005 0.00125] # (km²/yr) - diffusion coefficient
t0 = -10 # Initial time of sources
noise = 0E-3 # Noise strength
As = [0.5; 0.5; 0.5; 0.5] # Amplitudes of real sources
ns = length(As) # 'Real' number of sources

aa = 1 # Multiple for initial random conditions
Xn = zeros(2,length(As)) # Initialize Xn -> source coordinates
Xn = [[-0.3; -0.4] [0.4; -0.3] [ -0.1; 0.25] [ -0.3; 0.65]];
Xs = ones(length(As), 3)

# Ordering matrix of the sources: [A X Y]
for k = 1:size(Xs,1)
	Xs[k,:] = [As[k] Xn[1,k] Xn[2,k]]
end

xd = zeros(9, 2)
xd[1,:] = [0.0   0.0]
xd[2,:] = [-0.5 -0.5]
xd[3,:] = [-0.5  0.5]
xd[4,:] = [0.5   0.5]
xd[5,:] = [0.5  -0.5]
xd[6,:] = [0.0   0.5]
xd[7,:] = [0.0  -0.5]
xd[8,:] = [-0.5  0.0]
xd[9,:] = [0.5   0.0]

xD = xd # For consistency between Matlab<->Julia

nd = maximum(size(xD)) # Replicates Matlab's length()

S, XF = GreenNMFk.initial_conditions(As,Xs,xD,D,t0,u,numT,noise,time)

number_of_sources = 1
GreenNMFk.log("\nNumber of sources : $(number_of_sources)")
#sol, normF, lb, ub, AA, sol_real, normF_real, normF1, sol_all = GreenNMFk.calculations_nmf_v02(number_of_sources, nd, Nsim, aa, xD, t0, time, S, numT)

##########################################################################################
prefix = "Results_9det_1sources"
matlab_file = MAT.matopen(joinpath(GreenNMFk.matlab_dir, prefix * ".mat"))
sol = MAT.read(matlab_file, "sol")
normF = MAT.read(matlab_file, "normF")[:]
lb = MAT.read(matlab_file, "lb")
ub = MAT.read(matlab_file, "ub")
AA = MAT.read(matlab_file, "AA")
sol_real = MAT.read(matlab_file, "sol_real")
normF_real = MAT.read(matlab_file, "normF_real")
#normF1 = MAT.read(matlab_file, "normF1")
#sol_all = MAT.read(matlab_file, "sol_all")
##########################################################################################

GreenNMFk.log("Size of sol : $(size(sol))")

yy = Base.quantile(normF,0.25)
reconstr1 = mean(normF[normF .< yy])

ind = find(normF[normF .< yy])
sol1 = sol[ind,:]

avg_sol = mean(sol1)
solution = avg_sol
mean_savg = 1
number_of_clust_sim = 0

# Save a JLD file with simulation results
if GreenNMFk.save_output
	outfile = "Solution_$(nd)det_$(number_of_sources)sources.jld"
		
	GreenNMFk.log("-> Saving results to $(GreenNMFk.working_dir)/$(outfile)")
	JLD.save(joinpath(GreenNMFk.working_dir, outfile), "solution", solution, "reconstr1", reconstr1, "mean_savg", mean_savg, "number_of_clust_sum", number_of_clust_sim)
end

# Generate empty RECON and SILL_AVG vectors
RECON = zeros(max_number_of_sources,1)
SILL_AVG = zeros(max_number_of_sources,1)

RECON[1] = reconstr1
SILL_AVG[1] = 1

number_of_sources = 2

##########################################################################################
prefix = "Results_9det_2sources"
matlab_file = MAT.matopen(joinpath(GreenNMFk.matlab_dir, prefix * ".mat"))
sol = MAT.read(matlab_file, "sol")
normF = MAT.read(matlab_file, "normF")[:]
lb = MAT.read(matlab_file, "lb")
ub = MAT.read(matlab_file, "ub")
AA = MAT.read(matlab_file, "AA")
sol_real = MAT.read(matlab_file, "sol_real")
normF_real = MAT.read(matlab_file, "normF_real")[:]
Qyes = MAT.read(matlab_file, "Qyes")

solution, vect_index, cent, reconstr, mean_savg, number_of_clust_sim = GreenNMFk.clustering_the_solutions(number_of_sources, nd, sol_real, normF_real, Qyes)
##########################################################################################

for jj = 2:max_number_of_sources
	
	sol, normF, lb, ub, AA, sol_real, normF_real, normF1, sol_all, normF_abs, Qyes = GreenNMFk.calculations_nmf_v02(number_of_sources, nd, Nsim, aa, xD, t0, time, S, numT)
	solution, vect_index, cent, reconstr, mean_savg, number_of_clust_sim = GreenNMFk.clustering_the_solutions(number_of_sources, nd, sol_real, normF_real, Qyes)
	
	RECON[number_of_sources] = reconstr
	SILL_AVG[number_of_sources] = mean_savg
	
	number_of_sources = number_of_sources + 1
end

#close all

RECON = RECON/Nsim

# Save a JLD file with simulation results
if save_output
	outfile = "All_$(nd)det_$(length(As))sources.jld"
		
	GreenNMFk.log("Saving results to $(working_dir)/$(outfile)")
	JLD.save(joinpath(working_dir, outfile), "RECON", RECON, "SILL_AVG", SILL_AVG)
end

x = 1:1:max_number_of_sources
y1 = RECON
y2 = SILL_AVG

createfigureBSA(x, y1, y2)

Sf, Comp, Dr, Det, Wf = GreenNMFk.CompRes(Cent, xD, solution, t0, numT, noise, time, S)

# End stopwatch timer

toc()