using Pkg
const EM_DIR = normpath(joinpath(@__DIR__, "..", "..", "em-master", "src"))
isdir(EM_DIR) && !(EM_DIR in LOAD_PATH) && push!(LOAD_PATH, EM_DIR)

using CSV, DataFrames, Distributions, SpecialFunctions, LinearAlgebra, Statistics
import EM

const HERE    = @__DIR__
const DATADIR = normpath(joinpath(HERE, "..", "..", "Data", "Processed"))
const EMTOL   = 1e-3
const MAXITER = 2000
const STARTBETAS = [0 0 0 0 0 0]
const STARTSIGMA = [1, 1, 1, 1, 1, 1]
const FULL = true

sigmoid(x) = 1 / (1 + exp(-x))

"returns (Conf_True, Disconf_True, Conf_False, Disconf_False) for each parameterisation"
lr_np(p) = (sigmoid(p[1]), sigmoid(p[2]), sigmoid(p[3]), sigmoid(p[4]))

function lr_pa(p)
    AS_T, AD_T, AS_F, AD_F = p[1], p[2], p[3], p[4]
    return (sigmoid(0.5 * (AS_T + AD_T)), sigmoid(0.5 * (AS_T - AD_T)),
            sigmoid(0.5 * (AS_F + AD_F)), sigmoid(0.5 * (AS_F - AD_F)))
end

function lr_it(p)
    AS_F, AS_T, AD_T, Dint = p[1], p[2], p[3], p[4]
    AD_F = AD_T + Dint
    return (sigmoid(0.5 * (AS_T + AD_T)), sigmoid(0.5 * (AS_T - AD_T)),
            sigmoid(0.5 * (AS_F + AD_F)), sigmoid(0.5 * (AS_F - AD_F)))
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

const MODELS = [("pa", lr_pa), ("it", lr_it), ("np", lr_np)]
const LABELS = ["Conf_True", "Disconf_True", "Conf_False", "Disconf_False", "Beta", "rho"]

"per-subject estimates on the reported (native) scale"
function tonative(x, lrfun)
    out = zeros(size(x, 1), 6)
    for i in 1:size(x, 1)
        ct, dt, cf, df_ = lrfun(x[i, :])
        out[i, :] = [ct, dt, cf, df_,
                     25 + 25 * erf(x[i, 5] / sqrt(2)), 7 * erf(x[i, 6] / sqrt(2))]
    end
    return out
end

const TESTS = ["AD_T (true bias)", "AD_F (false bias)", "interaction (AD_F-AD_T)"]
const CONTRASTS = Dict(
    "pa" => Dict("AD_T (true bias)"        => ([0.0, 1, 0, 0, 0, 0], true),
                 "AD_F (false bias)"       => ([0.0, 0, 0, 1, 0, 0], true),
                 "interaction (AD_F-AD_T)" => ([0.0, -1, 0, 1, 0, 0], false)),
    "it" => Dict("AD_T (true bias)"        => ([0.0, 0, 1, 0, 0, 0], true),
                 "AD_F (false bias)"       => ([0.0, 0, 1, 1, 0, 0], false),
                 "interaction (AD_F-AD_T)" => ([0.0, 0, 0, 1, 0, 0], true)),
    "np" => Dict("AD_T (true bias)"        => ([1.0, -1, 0, 0, 0, 0], false),
                 "AD_F (false bias)"       => ([0.0, 0, 1, -1, 0, 0], false),
                 "interaction (AD_F-AD_T)" => ([-1.0, 1, 1, -1, 0, 0], false)))

function loaddata(study)
    d = CSV.read(joinpath(DATADIR, "Study$(study).csv"), DataFrame)
    rename!(d, :subn => :sub)
    uq = unique(d.sub); mp = Dict(uq[i] => i for i in 1:length(uq))
    d.sub .= [mp[s] for s in d.sub]
    return d
end

corrs = DataFrame(study = Int[], pair = String[], parameter = String[], r = Float64[])
rows = DataFrame(study = Int[], model = String[], test = String[], free_parameter = Bool[],
                 se_source = String[], estimate = Float64[], se = Float64[],
                 t = Float64[], df = Int[], p = Float64[])

for study in [1, 2]
    data = loaddata(study)
    nsub = length(unique(data.sub))
    subs = 1:nsub
    X  = ones(Int, nsub)
    df = nsub - 1
    println("\n\n#################  STUDY $study  (n = $nsub)  #################"); flush(stdout)

    points = Dict{String, Matrix{Float64}}()
    for (mname, lrfun) in MODELS
        println("\n--- model = $mname, full = $FULL ---"); flush(stdout)
        @time (betas, sigma, x, l, h) = EM.em(data, subs, X, STARTBETAS, STARTSIGMA,
                                              makelik(lrfun); maxiter = MAXITER,
                                              emtol = EMTOL, full = FULL, quiet = 0)
        nat = tonative(x, lrfun)
        points[mname] = nat
        P = DataFrame(nat, Symbol.(LABELS)); insertcols!(P, 1, :subn => 1:nsub)
        CSV.write(joinpath(HERE, "PointsS$(study)_$(mname)_T.csv"), P)

        se_em, p_em, cov_em = EM.emerrors(data, subs, x, X, h, betas, sigma, makelik(lrfun))
        cov_fisher = inv(dropdims(sum(h, dims = 3), dims = 3))

        b = vec(betas)
        println("\n  betas = ", round.(b, digits = 4))
        for tname in TESTS
            (c, isfree) = CONTRASTS[mname][tname]
            est = dot(c, b)
            for (sname, C) in [("emerrors", cov_em), ("inv(sum h)", cov_fisher)]
                se = sqrt(abs(dot(c, C * c)))
                t  = est / se
                p  = 2 * ccdf(TDist(df), abs(t))
                push!(rows, (study, mname, tname, isfree, sname, est, se, t, df, p))
                println("  ", rpad(tname, 26), isfree ? "[free] " : "[contr]",
                        rpad(sname, 12),
                        "est=", rpad(round(est, digits = 4), 10),
                        "SE=", rpad(round(se, digits = 4), 10),
                        "t(", df, ")=", rpad(round(t, digits = 3), 9),
                        "p=", round(p, digits = 5))
            end
        end
        flush(stdout)
    end

    println("\n  ===== per-subject correlations between parameterisations (full=true) =====")
    println("  (this is the check: all three must be ~1.000)")
    print(rpad("  pair", 12)); for j in 1:6; print(rpad(LABELS[j], 14)); end; println("min")
    for (a, b) in [("np", "pa"), ("np", "it"), ("pa", "it")]
        r = [cor(points[a][:, j], points[b][:, j]) for j in 1:6]
        print(rpad("  $a ~ $b", 12))
        for j in 1:6
            print(rpad(round(r[j], digits = 4), 14))
            push!(corrs, (study, "$a ~ $b", LABELS[j], r[j]))
        end
        println(round(minimum(r), digits = 4))
    end
    flush(stdout)
end

CSV.write(joinpath(HERE, "tests.csv"), rows)
CSV.write(joinpath(HERE, "correlations_full.csv"), corrs)

println("\n\n=========== HEADLINE: the tests as the paper defines them ===========")
println("(each quantity taken from the model where it is a free parameter; emerrors SEs)")
println(rpad("test", 28), rpad("model", 8), rpad("Study 1", 30), "Study 2")
for tname in TESTS
    line = rpad(tname, 28)
    mdl = ""
    cells = String[]
    for study in [1, 2]
        r = rows[(rows.study .== study) .& (rows.test .== tname) .&
                 (rows.free_parameter) .& (rows.se_source .== "emerrors"), :]
        if isempty(r)
            push!(cells, "(none)")
        else
            mdl = r.model[1]
            push!(cells, "t($(r.df[1]))=$(round(r.t[1],digits=3)), p=$(round(r.p[1],digits=5))")
        end
    end
    println(line, rpad(mdl, 8), rpad(cells[1], 30), cells[2])
end

println("\n\n=========== EQUIVALENCE: same quantity, every parameterisation ===========")
println("(emerrors SEs; these must agree because full=true makes the models identical)")
for study in [1, 2]
    println("\nStudy $study")
    println(rpad("  test", 28), rpad("pa", 22), rpad("it", 22), "np")
    for tname in TESTS
        print(rpad("  $tname", 28))
        for mname in ["pa", "it", "np"]
            r = rows[(rows.study .== study) .& (rows.test .== tname) .&
                     (rows.model .== mname) .& (rows.se_source .== "emerrors"), :]
            print(rpad(isempty(r) ? "-" : "t=$(round(r.t[1],digits=3)) p=$(round(r.p[1],digits=4))", 22))
        end
        println()
    end
end

println("\nWrote tests.csv")
println("DONE")
