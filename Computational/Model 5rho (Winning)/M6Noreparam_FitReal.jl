# usage: julia M6Noreparam_FitReal.jl <study> [full covariance: 0 (default) or 1] [emtol]

em_dir = "./em-master"
push!(LOAD_PATH, em_dir)
using CSV, DataFrames, Distributions, SpecialFunctions, LinearAlgebra, Statistics
import EM

sigmoid(x) = 1 / (1 + exp(-x))

function M6_noreparam(params, data)
    ct = sigmoid(params[1]); dt = sigmoid(params[2])
    cf = sigmoid(params[3]); df_ = sigmoid(params[4])
    Beta = 25 + 25 * erf(params[5] / sqrt(2))
    rho  = 7 * erf(params[6] / sqrt(2))
    tau  = 1.0
    R, C1, C2, TrialType, FeedbackType, Condition = (
        data.Reward, data.C1, data.C2, data.TrialType,
        data.FeedbackType, data.Condition)
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
        lr_factual   = tt == 1 ? (pe > 0 ? ct : dt) : (pe > 0 ? cf : df_)
        lr_C_factual = tt == 1 ? (pe > 0 ? dt : ct) : (pe > 0 ? df_ : cf)
        lr = ft == 1 ? lr_factual : lr_C_factual
        option = ft == 1 ? chosen : unchosen
        Q[option, QC] = (1 - lr) * Q[option, QC] + lr * R[t]
        C[chosen, QC]   = C[chosen, QC] + tau * (1 - C[chosen, QC])
        C[unchosen, QC] = C[unchosen, QC] + tau * (0 - C[unchosen, QC])
    end
    return -lik
end

labels = ["Conf_True", "Disconf_True", "Conf_False", "Disconf_False", "Beta", "rho"]
study = parse(Int, ARGS[1])
full = length(ARGS) >= 2 && ARGS[2] == "1"
emtol = length(ARGS) >= 3 ? parse(Float64, ARGS[3]) : 1e-10
tag = full ? "_full" : ""
root = "."
out_dir = joinpath(root, "Plots", "Figures")
data = CSV.read(joinpath(root, "Data", "Processed", "Study$(study).csv"), DataFrame)
rename!(data, :subn => :sub)
uniq = unique(data.sub)
mp = Dict(uniq[i] => i for i in 1:length(uniq))
data.sub .= [mp[s] for s in data.sub]
NS = length(uniq)
subs = 1:NS
X = ones(Int, NS)
(betas, sigma, x, l, h) = EM.em(data, subs, X, zeros(1, 6), ones(6), M6_noreparam,
                                maxiter=2000, emtol=emtol, quiet=10, full=full)
est = hcat(sigmoid.(x[:, 1:4]), 25 .+ 25 .* erf.(x[:, 5] ./ sqrt(2)), 7 .* erf.(x[:, 6] ./ sqrt(2)))
Points = DataFrame(est, Symbol.(labels))
insertcols!(Points, 1, :subn => 1:NS)
CSV.write(joinpath(out_dir, "M6NoreparamPointsS$(study)$(tag).csv"), Points)

(ses, pvals, covmtx) = EM.emerrors(data, subs, x, X, h, betas, sigma, M6_noreparam)
b = vec(betas)
stats = DataFrame()
for k in 1:4
    se = sqrt(covmtx[k, k])
    stats[!, "$(labels[k])_point"] = [sigmoid(b[k])]
    stats[!, "$(labels[k])_sem_lower"] = [sigmoid(b[k] - se)]
    stats[!, "$(labels[k])_sem_upper"] = [sigmoid(b[k] + se)]
end
CSV.write(joinpath(out_dir, "M6NoreparamStatsS$(study)$(tag).csv"), stats)
show(stdout, MIME("text/plain"), stats; allcols=true); println()

for (i, j, nm) in [(1, 2, "verified"), (3, 4, "debunked")]
    w = zeros(6); w[i] = 1; w[j] = -1
    t = dot(w, b) / sqrt(w' * covmtx * w)
    println("conf - disconf, $nm: t($(NS - 1)) = $(round(t, digits=3)), p = $(round(2 * ccdf(TDist(NS - 1), abs(t)), sigdigits=2))")
end
