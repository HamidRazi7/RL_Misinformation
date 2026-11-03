# usage: julia M4Rho_FitReal.jl <study> [covariance: 0 diagonal, 1 full (default)]

study = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 2
full  = length(ARGS) >= 2 ? parse(Int, ARGS[2]) == 1 : true
study_file = "./Data/Processed/Study$(study).csv"
NS_ref = Dict(1 => 47, 2 => 57)

full    = full
emtol   = 1e-3
maxiter = 2000
println("full covariance = ", full)

using Pkg
const NEEDED_PKGS = ["CSV", "DataFrames", "Distributions", "GLM", "LinearAlgebra",
                     "NamedArrays", "Optim", "Random", "SpecialFunctions", "Statistics"]
missing_pkgs = [p for p in NEEDED_PKGS if !haskey(Pkg.project().dependencies, p)]
if !isempty(missing_pkgs)
    @info "Adding missing packages to the active environment: $(missing_pkgs)"
    Pkg.add(missing_pkgs)
end

const EM_CANDIDATES = [
    get(ENV, "EM_DIR", ""),
    "./em-master",
    joinpath(@__DIR__, "..", "..", "..", "..", "..", "em-master"),
    joinpath(@__DIR__, "..", "..", "em-master"),
    joinpath(@__DIR__, "..", "em-master"),
    joinpath(@__DIR__, "em-master"),
]
for d in EM_CANDIDATES
    if !isempty(d) && isdir(d) && !(d in LOAD_PATH)
        push!(LOAD_PATH, d)
    end
end

using EM, Distributions, LinearAlgebra, Optim, Statistics, Random
using GLM, DataFrames, NamedArrays, SpecialFunctions, CSV

@info "Loading real data: $(study_file)"
data = CSV.read(study_file, DataFrame)
rename!(data, :subn => :sub)

unique_subjects = unique(data.sub)
subject_map = Dict(unique_subjects[i] => i for i in 1:length(unique_subjects))
data.sub .= [subject_map[sub] for sub in data.sub]

NS = length(unique_subjects)
println("Subjects found: ", NS, " (expected ", NS_ref[study], ")")

subs = 1:NS
X = ones(Int, NS)
startbetas = [0 0 0 0 0 0]
startsigma = [1, 1, 1, 1, 1, 1]

function M4Rho(params, data)
    AS_T, AD_T, AS_F, AD_F = params[1], params[2], params[3], params[4]

    nd_conf_true     = 0.5 * (AS_T + AD_T)
    Conf_True        = 1 / (1 + exp(-nd_conf_true))
    nd_disconf_true  = 0.5 * (AS_T - AD_T)
    Disconf_True     = 1 / (1 + exp(-nd_disconf_true))
    nd_conf_false    = 0.5 * (AS_F + AD_F)
    Conf_False       = 1 / (1 + exp(-nd_conf_false))
    nd_disconf_false = 0.5 * (AS_F - AD_F)
    Disconf_False    = 1 / (1 + exp(-nd_disconf_false))

    Beta = 25 + 25 * erf(params[5] / sqrt(2))
    rho  = 7 * erf(params[6] / sqrt(2))
    tau  = 1.0

    R, C1, C2, TrialType, FeedbackType, Condition = (
        data.Reward, data.C1, data.C2, data.TrialType,
        data.FeedbackType, data.Condition
    )

    lik = 0.0
    Q = zeros(typeof(Beta), 2, 4)
    C = zeros(typeof(Beta), 2, 4)

    for t in eachindex(C1)
        QC = Condition[t]
        chosen   = C1[t] == 1 ? 1 : 2
        unchosen = 3 - chosen

        lik += -log1p(exp(-Beta * (Q[chosen, QC] - Q[unchosen, QC]) -
                          rho * (C[chosen, QC] - C[unchosen, QC])))

        ft = FeedbackType[t]
        tt = TrialType[t]
        pe = ft == 1 ? (R[t] - Q[chosen,   QC]) : (R[t] - Q[unchosen, QC])

        lr_factual   = tt == 1 ? (pe > 0 ? Conf_True : Disconf_True) :
                                 (pe > 0 ? Conf_False : Disconf_False)
        lr_C_factual = tt == 1 ? (pe > 0 ? Disconf_True : Conf_True) :
                                 (pe > 0 ? Disconf_False : Conf_False)
        lr = ft == 1 ? lr_factual : lr_C_factual

        option = ft == 1 ? chosen : unchosen
        Q[option, QC] = (1 - lr) * Q[option, QC] + lr * R[t]

        C[chosen,   QC] = C[chosen,   QC] + tau * (1 - C[chosen,   QC])
        C[unchosen, QC] = C[unchosen, QC] + tau * (0 - C[unchosen, QC])
    end

    return -lik
end

println("Julia threads available: ", Threads.nthreads())
@time (betas, sigma, x, l, h) = em(data, subs, X, startbetas, startsigma, M4Rho,
                                   maxiter=maxiter, emtol=emtol, full=full)

println("\nGroup-level parameters (free scale):")
println("betas = ", betas)
println("sigma = ", sigma)

standarderrors = emerrors(data, subs, x, X, h, betas, sigma, M4Rho)

function em_ttest(betas, standarderrors, m; d=nothing, nsubjects=nothing)
    betas = vec(betas)
    if d === nothing
        d = 1:length(betas)
    end
    if length(m) != length(d)
        error("Mismatch: m has $(length(m)) elements, but $(length(d)) parameters are being tested.")
    end
    se = standarderrors[1]
    a = betas[d]
    e = se[d]
    df = nsubjects - 1
    t = (a .- m) ./ e
    p = 2 * [ccdf(TDist(df), abs(ti)) for ti in t]
    return (tstat = t, pval = p, df = df)
end

stats = em_ttest(betas, standarderrors, zeros(2); d = [2, 4], nsubjects = NS)

println("\n=== Confirmation-bias tests (hierarchical t-test vs 0) ===")
println("AD_T (true trials):  t(", stats.df, ") = ", round(stats.tstat[1], digits=3),
        ",  p = ", round(stats.pval[1], digits=5))
println("AD_F (false trials): t(", stats.df, ") = ", round(stats.tstat[2], digits=3),
        ",  p = ", round(stats.pval[2], digits=5))

function transform_back(x::Matrix)
    AS_T = x[:, 1]
    AD_T = x[:, 2]
    AS_F = x[:, 3]
    AD_F = x[:, 4]
    p5   = x[:, 5]
    p6   = x[:, 6]

    Conf_True     = 1.0 ./ (1.0 .+ exp.(-0.5 .* (AS_T .+ AD_T)))
    Disconf_True  = 1.0 ./ (1.0 .+ exp.(-0.5 .* (AS_T .- AD_T)))
    Conf_False    = 1.0 ./ (1.0 .+ exp.(-0.5 .* (AS_F .+ AD_F)))
    Disconf_False = 1.0 ./ (1.0 .+ exp.(-0.5 .* (AS_F .- AD_F)))
    Beta = 25 .+ 25 .* erf.((1 / sqrt(2)) .* p5)
    rho  = 7 .* erf.(p6 ./ sqrt(2))

    return DataFrame(Conf_True = Conf_True, Disconf_True = Disconf_True,
                     Conf_False = Conf_False, Disconf_False = Disconf_False,
                     Beta = Beta, rho = rho)
end

est_df = transform_back(Matrix(x))
insertcols!(est_df, 1, :subn => 1:NS)
tag = full ? "_full" : ""
CSV.write(joinpath(@__DIR__, "M4RhoPointsS$(study)$(tag).csv"), est_df)

se = reshape(standarderrors[1], 1, length(betas))
xh_95ci = betas .+ 1.96 .* se
xl_95ci = betas .- 1.96 .* se
sem = (xh_95ci - xl_95ci) ./ (2 * 1.96)

df_point      = transform_back(Matrix(reshape(betas, 1, length(betas))))
df_ci_upper   = transform_back(Matrix(xh_95ci))
df_ci_lower   = transform_back(Matrix(xl_95ci))
df_sem_upper  = transform_back(Matrix(betas .+ sem))
df_sem_lower  = transform_back(Matrix(betas .- sem))

final_df = DataFrame()
for col in names(df_point)
    final_df[!, "$(col)_point"]     = df_point[!, col]
    final_df[!, "$(col)_ci_lower"]  = df_ci_lower[!, col]
    final_df[!, "$(col)_ci_upper"]  = df_ci_upper[!, col]
    final_df[!, "$(col)_sem_lower"] = df_sem_lower[!, col]
    final_df[!, "$(col)_sem_upper"] = df_sem_upper[!, col]
end
CSV.write(joinpath(@__DIR__, "M4RhoStatsS$(study)$(tag).csv"), final_df)
println("Saved: M4RhoPointsS$(study)$(tag).csv, M4RhoStatsS$(study)$(tag).csv")

conf_diff_true  = est_df.Conf_True  .- est_df.Disconf_True
conf_diff_false = est_df.Conf_False .- est_df.Disconf_False

println("\n=== Group means (original scale), Study $(study) ===")
println("True trials:   Conf_True    = ", round(mean(est_df.Conf_True),  digits=3),
        "   Disconf_True = ", round(mean(est_df.Disconf_True), digits=3),
        "   diff = ", round(mean(conf_diff_true),  digits=3))
println("False trials:  Conf_False   = ", round(mean(est_df.Conf_False), digits=3),
        "   Disconf_False = ", round(mean(est_df.Disconf_False), digits=3),
        "   diff = ", round(mean(conf_diff_false), digits=3))
println("Beta mean = ", round(mean(est_df.Beta), digits=2),
        "   rho mean = ", round(mean(est_df.rho), digits=3))
println("\nConfirmation bias TRUE trials:  ", stats.pval[1] < 0.05 ? "YES (significant)" : "no",
        "  [t=", round(stats.tstat[1], digits=2), ", p=", round(stats.pval[1], digits=4), "]")
println("Confirmation bias FALSE trials: ", stats.pval[2] < 0.05 ? "YES (significant)" : "no",
        "  [t=", round(stats.tstat[2], digits=2), ", p=", round(stats.pval[2], digits=4), "]")

if ndims(h) == 3
    fisher = sum(h, dims=3)[:, :, 1]
else
    fisher = h
end
cov_free = inv(fisher)
ad_t_val = betas[2]
ad_f_val = betas[4]
interaction = ad_f_val - ad_t_val
df_int = NS - 1

cov_betas = standarderrors[3]
c_int = zeros(length(betas)); c_int[2] = -1.0; c_int[4] = 1.0
se_int = sqrt(abs(dot(c_int, cov_betas * c_int)))
t_int = interaction / se_int
p_int = 2 * ccdf(TDist(df_int), abs(t_int))
println("\n=== Interaction test (full=$full) ===")
println("AD_T = ", round(ad_t_val, digits=4), ",  AD_F = ", round(ad_f_val, digits=4))
println("Interaction (AD_F - AD_T) = ", round(interaction, digits=4))
println("Cov(AD_T, AD_F) = ", round(cov_betas[2,4], digits=4))
println("SE(interaction) = ", round(se_int, digits=4), "   [emerrors]")
println("t(", df_int, ") = ", round(t_int, digits=3), ", p = ", round(p_int, digits=4))

se_ref = sqrt(abs(cov_free[4,4] + cov_free[2,2] - 2 * cov_free[2,4]))
t_ref  = interaction / se_ref
println("  [not reported] inv(sum h): SE = ", round(se_ref, digits=4),
        ", t = ", round(t_ref, digits=3),
        ", p = ", round(2 * ccdf(TDist(df_int), abs(t_ref)), digits=4))
