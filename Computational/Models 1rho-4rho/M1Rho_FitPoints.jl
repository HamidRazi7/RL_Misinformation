# usage: julia M1Rho_FitPoints.jl <study>

study = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 2
study_file = "./Data/Processed/Study$(study).csv"
NS_ref = Dict(1 => 47, 2 => 57)

full    = false
emtol   = 1e-3
maxiter = 2000

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
startbetas = [0 0 0 0]
startsigma = [1, 1, 1, 1]

function M1Rho(params, data)
    Alpha_True  = 1 / (1 + exp(-params[1]))
    Alpha_False = 1 / (1 + exp(-params[2]))

    Beta = 25 + 25 * erf(params[3] / sqrt(2))
    rho  = 7 * erf(params[4] / sqrt(2))
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

        lr = tt == 1 ? Alpha_True : Alpha_False

        option = ft == 1 ? chosen : unchosen
        Q[option, QC] = (1 - lr) * Q[option, QC] + lr * R[t]

        C[chosen,   QC] = C[chosen,   QC] + tau * (1 - C[chosen,   QC])
        C[unchosen, QC] = C[unchosen, QC] + tau * (0 - C[unchosen, QC])
    end

    return -lik
end

println("Julia threads available: ", Threads.nthreads())
@time (betas, sigma, x, l, h) = em(data, subs, X, startbetas, startsigma, M1Rho,
                                   maxiter=maxiter, emtol=emtol, full=full)

println("Group-level betas (free scale): ", betas)

Alpha_True  = 1 ./ (1 .+ exp.(-x[:, 1]))
Alpha_False = 1 ./ (1 .+ exp.(-x[:, 2]))
Beta        = 25 .+ 25 .* erf.(x[:, 3] ./ sqrt(2))
tau         = ones(NS)
rho         = 7 .* erf.(x[:, 4] ./ sqrt(2))

points = DataFrame(subn = 1:NS,
                   Conf_True = Alpha_True,  Disconf_True  = Alpha_True,
                   Conf_False = Alpha_False, Disconf_False = Alpha_False,
                   Beta = Beta, tau = tau, rho = rho)
out_points = "./Computational/Models 1rho-4rho/M1RhoPointsS$(study).csv"
mkpath(dirname(out_points))
CSV.write(out_points, points)
println("Saved: ", out_points, "  (", NS, " subjects)")
println("median alpha_true=", round(median(Alpha_True), digits=3),
        " alpha_false=", round(median(Alpha_False), digits=3),
        " rho=", round(median(rho), digits=3))
