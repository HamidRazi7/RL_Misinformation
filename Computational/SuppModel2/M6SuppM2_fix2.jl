# usage: julia M6SuppM2_fix2.jl <study> <gain|loss> <rho> <beta> <rscale> <nstarts> <maxiter> <mode> [tag]
# mode 1..nstarts fits one start; mode 0 combines the starts and computes the standard errors
# Figure S1: rho and beta fixed at the M5rho group means (Study 1: 0.57257, 4.2618; Study 2: 0.46925, 2.4364), e.g.
#   for m in 1 2 3 4 5 6 0; do julia M6SuppM2_fix2.jl 1 gain 0.57257 4.2618 1 6 2500 $m _M6b; done

study   = parse(Int, ARGS[1])
variant = lowercase(ARGS[2])
RHO_FIX = parse(Float64, ARGS[3])
BETA_FIX= parse(Float64, ARGS[4])
rscale  = length(ARGS) >= 5 ? parse(Int, ARGS[5]) == 1 : true
NSTARTS = length(ARGS) >= 6 ? parse(Int, ARGS[6]) : 6
maxiter = length(ARGS) >= 7 ? parse(Int, ARGS[7]) : 2500
mode    = length(ARGS) >= 8 ? parse(Int, ARGS[8]) : 0
TAGSUF  = length(ARGS) >= 9 ? ARGS[9] : ""
emtol   = 1e-4
SEED    = 20260829
NP      = 4

script_dir = dirname(dirname(@__DIR__))
outbase = joinpath(".", "Data", "Processed", "Results")
mkpath(outbase)
push!(LOAD_PATH, joinpath(script_dir, "em-master"))
using EM, Distributions, LinearAlgebra, Optim, Statistics, Random
using DataFrames, SpecialFunctions, CSV, DelimitedFiles
LinearAlgebra.BLAS.set_num_threads(1)

data = CSV.read(joinpath(script_dir, "Data", "Processed", "Study$(study).csv"), DataFrame)
rename!(data, :subn => :sub)
if variant == "gain"
    data = filter(r -> r.Condition in [1, 2], data)
elseif variant == "loss"
    data = filter(r -> r.Condition in [3, 4], data)
end
rscale && (data.Reward = data.Reward ./ 10.0)
us = unique(data.sub); smap = Dict(us[i] => i for i in 1:length(us))
data.sub .= [smap[s] for s in data.sub]
NS = length(us); subs = 1:NS; X = ones(Int, NS)

const RHO  = RHO_FIX
const BETA = BETA_FIX

function M6fix2(p, data)
    CT = 0.5 + 0.5*erf(0.5*(p[1] + p[2])/sqrt(2))
    DT = 0.5 + 0.5*erf(0.5*(p[1] - p[2])/sqrt(2))
    CF = 0.5 + 0.5*erf(0.5*(p[3] + p[4])/sqrt(2))
    DF = 0.5 + 0.5*erf(0.5*(p[3] - p[4])/sqrt(2))
    Beta = BETA; rho = RHO; tau = 1.0
    R, C1, TT, FT, CD = data.Reward, data.C1, data.TrialType, data.FeedbackType, data.Condition
    lik = 0.0; Q = zeros(typeof(CT),2,4); C = zeros(typeof(CT),2,4)
    for t in eachindex(C1)
        QC = CD[t]; ch = C1[t]==1 ? 1 : 2; un = 3-ch
        lik += -log1p(exp(-Beta*(Q[ch,QC]-Q[un,QC]) - rho*(C[ch,QC]-C[un,QC])))
        icf = FT[t]==1
        pe = icf ? (R[t]-Q[ch,QC]) : (R[t]-Q[un,QC])
        lrf = TT[t]==1 ? (pe>0 ? CT : DT) : (pe>0 ? CF : DF)
        lrc = TT[t]==1 ? (pe>0 ? DT : CT) : (pe>0 ? DF : CF)
        lr = icf ? lrf : lrc; op = icf ? ch : un
        Q[op,QC] = (1-lr)*Q[op,QC] + lr*R[t]
        C[ch,QC] = C[ch,QC] + tau*(1-C[ch,QC]); C[un,QC] = C[un,QC] + tau*(0-C[un,QC])
    end
    return -lik
end

transform_back(x) = DataFrame(
    Conf_True     = 0.5 .+ 0.5 .* erf.(0.5 .* (x[:,1] .+ x[:,2]) ./ sqrt(2)),
    Disconf_True  = 0.5 .+ 0.5 .* erf.(0.5 .* (x[:,1] .- x[:,2]) ./ sqrt(2)),
    Conf_False    = 0.5 .+ 0.5 .* erf.(0.5 .* (x[:,3] .+ x[:,4]) ./ sqrt(2)),
    Disconf_False = 0.5 .+ 0.5 .* erf.(0.5 .* (x[:,3] .- x[:,4]) ./ sqrt(2)))

function em_tracked(betas0, sigma0; emtol=1e-4, maxiter=2500)
    betas = Matrix{Float64}(betas0); sigma = Matrix{Float64}(sigma0)
    x = X*betas; l = zeros(NS); h = zeros(NP,NP,NS)
    fes = Float64[]; newp = EM.packparams(betas,sigma); nviol=0; iters=0; prev=-1
    for iter in 1:maxiter
        iters = iter; old = newp
        EM.estep!(data,subs,x,x,l,h,X,betas,sigma,M6fix2)
        (betas,sigma) = EM.mstep(x,X,h,sigma)
        newp = EM.packparams(betas,sigma)
        nincl = sum(det(h[:,:,i]) > 0 for i in 1:NS); same = (nincl==prev); prev = nincl
        fe = EM.freeenergy(x,l,h,X,betas,sigma)
        same && !isempty(fes) && isfinite(fe) && isfinite(fes[end]) && (fes[end]-fe) > 1e-6 && (nviol += 1)
        push!(fes, fe)
        iter % 25 == 0 && GC.gc(false)
        chg = maximum(abs.((newp .- old)./old))
        flat = same && length(fes) > 20 && abs(fes[end]-fes[end-20]) < 1e-5
        (chg < emtol || flat) && break
    end
    return (betas,sigma,x,l,h,fes[end],nviol,iters,iters<maxiter)
end

rng = MersenneTwister(SEED)
starts = [("zeros",              reshape(zeros(NP),1,NP)),
          ("moderate LR",        reshape([-1.0, 0.3, -2.0, 0.3],1,NP)),
          ("high LR",            reshape([ 0.0, 0.5, -0.5, 0.5],1,NP)),
          ("low LR",             reshape([-3.0, 0.1, -4.0, 0.1],1,NP))]
while length(starts) < NSTARTS
    j = length(starts)-3
    push!(starts, ("random $j", reshape([randn(rng)*1.5-1.0, randn(rng)*0.5,
                                          randn(rng)*1.5-1.5, randn(rng)*0.5],1,NP)))
end

TAG = "S$(study)_$(variant)" * (rscale ? "_rs" : "_raw") * "_fix2" * (TAGSUF == "" ? "" : "_" * TAGSUF)
CK  = joinpath(outbase, "checkpoints"); mkpath(CK)
sigma0 = Matrix{Float64}(I, NP, NP)

if mode > 0
    (nm, s0) = starts[mode]
    t0 = time()
    (betas,sigma,x,l,h,fe,nviol,iters,conv) = em_tracked(s0, sigma0; emtol=emtol, maxiter=maxiter)
    grp = transform_back(betas)
    writedlm(joinpath(CK,"s$(mode)_betas_$(TAG).csv"), betas, ',')
    writedlm(joinpath(CK,"s$(mode)_sigma_$(TAG).csv"), sigma, ',')
    writedlm(joinpath(CK,"s$(mode)_x_$(TAG).csv"), x, ',')
    writedlm(joinpath(CK,"s$(mode)_h_$(TAG).csv"), reshape(h, NP*NP, NS), ',')
    open(joinpath(CK,"summary_$(TAG).csv"),"a") do io
        println(io, join([mode, nm, fe, conv, iters, nviol, grp.Conf_True[1]], ","))
    end
    println("start $(mode) [$(nm)]: FE = $(round(fe,digits=3))  ", conv ? "converged" : "MAXITER",
            "  $(iters) it  barConfT = $(round(grp.Conf_True[1],digits=4))  [$(round(time()-t0,digits=1))s]")
    exit(0)
end

rows = readdlm(joinpath(CK,"summary_$(TAG).csv"), ',')
println("="^78)
println("M6SuppM2 rho AND Beta fixed | $(TAG) | rho=$(RHO) Beta=$(BETA) | NS=$(NS)")
println("="^78)
println(rpad("idx",5), rpad("start",16), rpad("freeE",12), rpad("conv",7), rpad("iters",7), "barConfT")
for i in 1:size(rows,1)
    println(rpad(string(Int(rows[i,1])),5), rpad(string(rows[i,2]),16),
            rpad(string(round(Float64(rows[i,3]),digits=2)),12),
            rpad(string(rows[i,4]),7), rpad(string(Int(rows[i,5])),7),
            round(Float64(rows[i,7]),digits=4))
end
fes = Float64.(rows[:,3]); best = argmax(fes); bidx = Int(rows[best,1])
conv = [rows[i,4] == true || rows[i,4] == "true" for i in 1:size(rows,1)]
inb  = findall(i -> conv[i] && (fes[best]-fes[i]) < 1.0, 1:length(fes))
bars = Float64.(rows[inb,7])
println("\nBEST: start $(bidx) [$(rows[best,2])]  FE = $(round(fes[best],digits=2))")
println("converged $(count(conv))/$(length(fes)) | best basin $(length(inb))/$(length(fes))")
!isempty(bars) && println("  barConfT in basin: $(round(minimum(bars),digits=4)) .. $(round(maximum(bars),digits=4))")

betas = readdlm(joinpath(CK,"s$(bidx)_betas_$(TAG).csv"), ',')
sigma = readdlm(joinpath(CK,"s$(bidx)_sigma_$(TAG).csv"), ',')
x     = readdlm(joinpath(CK,"s$(bidx)_x_$(TAG).csv"), ',')
h     = reshape(readdlm(joinpath(CK,"s$(bidx)_h_$(TAG).csv"), ','), NP, NP, NS)
println("\ngroup covariance: cond = ", round(cond(sigma),digits=1),
        " | diag = ", round.(diag(sigma),digits=4))

println("\ncalling emerrors ..."); flush(stdout)
(ses, pvals, covmtx) = emerrors(data, subs, x, X, h, betas, sigma, M6fix2)
E = eigen(Symmetric((covmtx+covmtx')/2))
sevec = sqrt.(max.(diag(E.vectors*Diagonal(max.(E.values,0.0))*E.vectors'), 0.0))
println("emerrors OK | cond(covmtx) = ", round(cond(covmtx),digits=1),
        " | min eig = ", round(minimum(E.values),digits=10),
        minimum(E.values) < 0 ? "  <-- INDEFINITE" : "  (PD)")

est = transform_back(x); insertcols!(est,1,:subn => 1:NS)
est.Beta .= BETA; est.rho .= RHO
grp = transform_back(betas)
CSV.write(joinpath(outbase,"M6SuppM2fix2Points$(TAG).csv"), est)

println("\n=== learning rates ===")
println(rpad("param",16), rpad("group",11), rpad("subj mean",12), "subj median")
for c in ["Conf_True","Disconf_True","Conf_False","Disconf_False"]
    println(rpad(c,16), rpad(string(round(grp[1,c],digits=4)),11),
            rpad(string(round(mean(est[!,c]),digits=4)),12), round(median(est[!,c]),digits=4))
end
println(rpad("Beta",16), "FIXED at ", BETA, "    ", rpad("rho",6), "FIXED at ", RHO)

b = vec(betas); dfree = NS-1; td = TDist(dfree)
println("\n=== Hierarchical tests (df = $(dfree)) ===")
for (nm,i) in [("AD_T",2), ("AD_F",4)]
    t = b[i]/sevec[i]
    println(rpad(nm,14), " beta = ", rpad(string(round(b[i],digits=4)),9),
            " SE = ", rpad(string(round(sevec[i],digits=4)),9),
            " t = ", rpad(string(round(t,digits=2)),8),
            " p = ", round(2*ccdf(td,abs(t)),digits=6))
end
vd = covmtx[2,2]+covmtx[4,4]-2*covmtx[2,4]; sd = sqrt(max(vd,0.0))
ti = sd > 0 ? (b[2]-b[4])/sd : NaN
println(rpad("AD_T - AD_F",14), " diff = ", rpad(string(round(b[2]-b[4],digits=4)),9),
        " SE = ", rpad(string(round(sd,digits=4)),9),
        " t = ", rpad(string(round(ti,digits=2)),8),
        " p = ", isnan(ti) ? "NaN" : string(round(2*ccdf(td,abs(ti)),digits=6)))

println("\n=== subject-level contrasts ===")
for (nm,c,d) in [("True",est.Conf_True,est.Disconf_True),("False",est.Conf_False,est.Disconf_False)]
    v = c .- d; t = sqrt(NS)*mean(v)/std(v)
    println(rpad(nm,7), " mean = ", round(mean(v),digits=4), "  t = ", round(t,digits=2),
            "  p = ", round(2*ccdf(td,abs(t)),digits=6))
end

final = DataFrame()
for c in names(grp)
    v = est[!,c]
    final[!,"$(c)_point"]=grp[!,c]; final[!,"$(c)_submean"]=[mean(v)]
    final[!,"$(c)_submedian"]=[median(v)]
    final[!,"$(c)_subsem_lower"]=[mean(v)-std(v)/sqrt(NS)]
    final[!,"$(c)_subsem_upper"]=[mean(v)+std(v)/sqrt(NS)]
end
final.Beta_point=[BETA]; final.rho_point=[RHO]
CSV.write(joinpath(outbase,"M6SuppM2fix2Stats$(TAG).csv"), final)
println("\nSaved: M6SuppM2fix2{Points,Stats}$(TAG).csv")
