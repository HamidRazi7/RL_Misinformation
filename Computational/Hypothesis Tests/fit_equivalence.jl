using Pkg
const EM_DIR = normpath(joinpath(@__DIR__, "..", "..", "em-master", "src"))
isdir(EM_DIR) && !(EM_DIR in LOAD_PATH) && push!(LOAD_PATH, EM_DIR)

using CSV, DataFrames, Distributions, SpecialFunctions, LinearAlgebra, Statistics
import EM

const HERE     = @__DIR__
const DATADIR  = normpath(joinpath(HERE, "..", "..", "Data", "Processed"))
const EMTOL    = 1e-3
const MAXITER  = 2000
const STARTBETAS = [0 0 0 0 0 0]
const STARTSIGMA = [1, 1, 1, 1, 1, 1]

sigmoid(x) = 1 / (1 + exp(-x))

"direct-logit (non-reparameterised): params = lCT, lDT, lCF, lDF, Beta*, rho*"
lr_np(p) = (sigmoid(p[1]), sigmoid(p[2]), sigmoid(p[3]), sigmoid(p[4]))

"AS/AD reparameterised: params = AS_T, AD_T, AS_F, AD_F, Beta*, rho*  (ordering as in M4Rho_FitReal.jl)"
function lr_pa(p)
    AS_T, AD_T, AS_F, AD_F = p[1], p[2], p[3], p[4]
    return (sigmoid(0.5 * (AS_T + AD_T)),
            sigmoid(0.5 * (AS_T - AD_T)),
            sigmoid(0.5 * (AS_F + AD_F)),
            sigmoid(0.5 * (AS_F - AD_F)))
end

function makelik(lrfun)
    return function (params, data)
        Conf_True, Disconf_True, Conf_False, Disconf_False = lrfun(params)
        Beta = 25 + 25 * erf(params[5] / sqrt(2))
        rho  = 7 * erf(params[6] / sqrt(2))
        tau  = 1.0
        R, C1, TrialType, FeedbackType, Condition = (
            data.Reward, data.C1, data.TrialType, data.FeedbackType, data.Condition)
        lik = 0.0
        Q = zeros(typeof(Beta), 2, 4)
        C = zeros(typeof(Beta), 2, 4)
        for t in eachindex(C1)
            QC = Condition[t]
            chosen   = C1[t] == 1 ? 1 : 2
            unchosen = 3 - chosen
            lik += -log1p(exp(-Beta * (Q[chosen, QC] - Q[unchosen, QC]) -
                              rho * (C[chosen, QC] - C[unchosen, QC])))
            ft = FeedbackType[t]; tt = TrialType[t]
            pe = ft == 1 ? (R[t] - Q[chosen, QC]) : (R[t] - Q[unchosen, QC])
            lr_factual   = tt == 1 ? (pe > 0 ? Conf_True : Disconf_True) :
                                     (pe > 0 ? Conf_False : Disconf_False)
            lr_C_factual = tt == 1 ? (pe > 0 ? Disconf_True : Conf_True) :
                                     (pe > 0 ? Disconf_False : Conf_False)
            lr = ft == 1 ? lr_factual : lr_C_factual
            option = ft == 1 ? chosen : unchosen
            Q[option, QC] = (1 - lr) * Q[option, QC] + lr * R[t]
            C[chosen, QC]   = C[chosen, QC] + tau * (1 - C[chosen, QC])
            C[unchosen, QC] = C[unchosen, QC] + tau * (0 - C[unchosen, QC])
        end
        return -lik
    end
end

"map fitted parameters to the reported (native) scale"
function tonative(x, lrfun)
    n = size(x, 1)
    out = zeros(n, 6)
    for i in 1:n
        ct, dt, cf, df_ = lrfun(x[i, :])
        out[i, :] = [ct, dt, cf, df_,
                     25 + 25 * erf(x[i, 5] / sqrt(2)),
                     7 * erf(x[i, 6] / sqrt(2))]
    end
    return out
end

const LABELS = ["Conf_True", "Disconf_True", "Conf_False", "Disconf_False", "Beta", "rho"]

function loaddata(study)
    d = CSV.read(joinpath(DATADIR, "Study$(study).csv"), DataFrame)
    rename!(d, :subn => :sub)
    uq = unique(d.sub); mp = Dict(uq[i] => i for i in 1:length(uq))
    d.sub .= [mp[s] for s in d.sub]
    return d
end

rows = DataFrame(study = Int[], comparison = String[], covariance = String[],
                 parameter = String[], r = Float64[])

for study in [1, 2]
    data = loaddata(study)
    nsub = length(unique(data.sub))
    subs = 1:nsub
    X = ones(Int, nsub)
    res = Dict{String, Matrix{Float64}}()

    println("\n\n#################  STUDY $study  (n = $nsub)  #################"); flush(stdout)

    for (pname, lrfun) in [("np", lr_np), ("pa", lr_pa)], full in [false, true]
        tag = "$(pname)_$(full ? "T" : "F")"
        println("\n--- $tag  (full = $full) ---"); flush(stdout)
        @time (betas, sigma, x, l, h) = EM.em(data, subs, X, STARTBETAS, STARTSIGMA,
                                              makelik(lrfun); maxiter = MAXITER,
                                              emtol = EMTOL, full = full, quiet = 0)
        nat = tonative(x, lrfun)
        res[tag] = nat
        P = DataFrame(nat, Symbol.(LABELS))
        insertcols!(P, 1, :subn => 1:nsub)
        CSV.write(joinpath(HERE, "PointsS$(study)_$(tag).csv"), P)
        println("  group means: ",
                join([string(LABELS[j], "=", round(mean(nat[:, j]), digits = 4)) for j in 1:6], "  "))
        flush(stdout)
    end

    println("\n===== np vs pa, Study $study =====")
    print(rpad("", 22)); for j in 1:6; print(rpad(LABELS[j], 15)); end; println("min")
    for (cov, lab) in [("F", "full=false (DIFFER)"), ("T", "full=true  (EQUAL)")]
        r = [cor(res["np_$cov"][:, j], res["pa_$cov"][:, j]) for j in 1:6]
        print(rpad("  $lab", 22))
        for j in 1:6
            print(rpad(round(r[j], digits = 4), 15))
            push!(rows, (study, "np ~ pa", cov == "T" ? "full" : "diagonal", LABELS[j], r[j]))
        end
        println(round(minimum(r), digits = 4))
    end

    for (cov, fn) in [("F", "M4RhoPointsS$(study).csv"), ("T", "M4RhoPointsS$(study)_full.csv")]
        p = normpath(joinpath(HERE, "..", "Model 5rho (Winning)", fn))
        isfile(p) || continue
        pub = CSV.read(p, DataFrame)
        r = [cor(Float64.(pub[!, Symbol(LABELS[j])]), res["pa_$cov"][:, j]) for j in 1:6]
        println(rpad("  published~refit pa$cov", 22),
                join([rpad(round(v, digits = 4), 15) for v in r]), round(minimum(r), digits = 4))
        for j in 1:6
            push!(rows, (study, "published pa ~ refit pa", cov == "T" ? "full" : "diagonal",
                         LABELS[j], r[j]))
        end
    end
    flush(stdout)
end

CSV.write(joinpath(HERE, "correlations.csv"), rows)

println("\n\n================ VERDICT ================")
for study in [1, 2]
    sub = rows[(rows.study .== study) .& (rows.comparison .== "np ~ pa"), :]
    for cov in ["diagonal", "full"]
        v = sub[sub.covariance .== cov, :r]
        isempty(v) && continue
        println("Study $study, $cov covariance: np~pa min r = ", round(minimum(v), digits = 4),
                minimum(v) > 0.95 ? "   EQUIVALENT" : "   NOT equivalent")
    end
end
println("\nWrote correlations.csv and PointsS{1,2}_{np,pa}_{F,T}.csv")
println("DONE")
