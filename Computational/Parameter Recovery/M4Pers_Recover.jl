# usage: julia M4Pers_Recover.jl [n_simulations] [n_trials_per_condition] [seed]

n_simulations = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 100
n_trials      = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 1000
seed          = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 1234
n_condition   = 4

full    = false
emtol   = 1e-3
maxiter = 2000

using Random
Random.seed!(seed)

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

"""
    session_simulate(n_simulations, n_trials, n_condition; rng)

Simulate data from M4Pers. True parameters are drawn wide and stored per trial:
- `Conf_True, Disconf_True, Conf_False, Disconf_False` ~ Uniform(0.01, 0.99)
- `Beta` ~ Uniform(0.5, 15.0)     (0-50 scale)
- `tau`  ~ Uniform(0.05, 0.9)     (0-1 scale; real fits span ~0.06-0.86)
- `rho`  ~ Uniform(-0.5, 4.0)     (-7 to 7 scale; real fits span ~-0.3 to 3.7)

Returns a DataFrame with columns
`sub, Condition, Trial, C1, C2, FeedbackType, Reward, TrialType,
 Conf_True, Disconf_True, Conf_False, Disconf_False, Beta, tau, rho`.
"""
function session_simulate(n_simulations, n_trials, n_condition; rng=Random.default_rng())
    n_rows = n_simulations * n_condition * n_trials

    sub          = Vector{Int}(undef, n_rows)
    condition    = Vector{Int}(undef, n_rows)
    trial        = Vector{Int}(undef, n_rows)
    c1           = Vector{Int}(undef, n_rows)
    c2           = Vector{Int}(undef, n_rows)
    feedback     = Vector{Int}(undef, n_rows)
    reward       = Vector{Float64}(undef, n_rows)
    trialtype    = Vector{Bool}(undef, n_rows)
    true_ct      = Vector{Float64}(undef, n_rows)
    true_dt      = Vector{Float64}(undef, n_rows)
    true_cf      = Vector{Float64}(undef, n_rows)
    true_df      = Vector{Float64}(undef, n_rows)
    true_beta    = Vector{Float64}(undef, n_rows)
    true_tau     = Vector{Float64}(undef, n_rows)
    true_rho     = Vector{Float64}(undef, n_rows)

    row = 0
    for s in 1:n_simulations
        Conf_True     = rand(rng, Uniform(0.01, 0.99))
        Disconf_True  = rand(rng, Uniform(0.01, 0.99))
        Conf_False    = rand(rng, Uniform(0.01, 0.99))
        Disconf_False = rand(rng, Uniform(0.01, 0.99))
        Beta = rand(rng, Uniform(0.5, 15.0))
        tau  = rand(rng, Uniform(0.05, 0.9))
        rho  = rand(rng, Uniform(-0.5, 4.0))

        FeedbackType = rand(rng, Bernoulli(0.5), n_trials)
        shuffled_conditions = sample(rng, 1:n_condition, n_condition; replace=false)
        Q = zeros(2, n_condition)
        C = zeros(2, n_condition)

        for QC in shuffled_conditions
            p1t, p2t, p1f, p2f = if QC == 1
                (0.80, 0.20, 0.50, 0.50)
            elseif QC == 2
                (0.50, 0.50, 0.80, 0.20)
            elseif QC == 3
                (0.80, 0.20, 0.50, 0.50)
            else
                (0.50, 0.50, 0.80, 0.20)
            end

            TrialType = rand(rng, Bool, n_trials)
            gain = QC in (1, 2)

            for t in 1:n_trials
                p1, p2 = TrialType[t] ? (p1t, p2t) : (p1f, p2f)

                prob_choose_1 = 1 / (1 + exp(-(Beta * (Q[1, QC] - Q[2, QC]) +
                                                rho * (C[1, QC] - C[2, QC]))))
                c1_t = rand(rng, Bernoulli(prob_choose_1))
                c2_t = 1 - c1_t

                r1 = rand(rng) <= p1 ? (gain ? 10.0 : -1.0) : (gain ? 1.0 : -10.0)
                r2 = rand(rng) <= p2 ? (gain ? 10.0 : -1.0) : (gain ? 1.0 : -10.0)

                chosen   = c1_t == 1 ? 1 : 2
                unchosen = 3 - chosen
                ft = FeedbackType[t] ? 1 : 0

                R = ft == 1 ? (chosen == 1 ? r1 : r2) : (chosen == 1 ? r2 : r1)

                pe = ft == 1 ? (R - Q[chosen, QC]) : (R - Q[unchosen, QC])
                tt = TrialType[t]

                lr_factual   = tt == 1 ? (pe > 0 ? Conf_True : Disconf_True) :
                                         (pe > 0 ? Conf_False : Disconf_False)
                lr_C_factual = tt == 1 ? (pe > 0 ? Disconf_True : Conf_True) :
                                         (pe > 0 ? Disconf_False : Conf_False)
                lr = ft == 1 ? lr_factual : lr_C_factual

                option_to_update = ft == 1 ? chosen : unchosen
                Q[option_to_update, QC] = (1 - lr) * Q[option_to_update, QC] + lr * R

                C[chosen,   QC] = C[chosen,   QC] + tau * (1 - C[chosen,   QC])
                C[unchosen, QC] = C[unchosen, QC] + tau * (0 - C[unchosen, QC])

                row += 1
                sub[row]          = s
                condition[row]    = QC
                trial[row]        = t
                c1[row]           = c1_t
                c2[row]           = c2_t
                feedback[row]     = ft
                reward[row]       = R
                trialtype[row]    = tt
                true_ct[row]      = Conf_True
                true_dt[row]      = Disconf_True
                true_cf[row]      = Conf_False
                true_df[row]      = Disconf_False
                true_beta[row]    = Beta
                true_tau[row]     = tau
                true_rho[row]     = rho
            end
        end
    end

    return DataFrame(
        sub = sub, Condition = condition, Trial = trial, C1 = c1, C2 = c2,
        FeedbackType = feedback, Reward = reward, TrialType = trialtype,
        Conf_True = true_ct, Disconf_True = true_dt,
        Conf_False = true_cf, Disconf_False = true_df,
        Beta = true_beta, tau = true_tau, rho = true_rho,
    )
end

@info "Simulating $(n_simulations) subjects x $(n_condition) conditions x $(n_trials) trials ..."
data = session_simulate(n_simulations, n_trials, n_condition)

NS = n_simulations
subs = 1:NS
X = ones(Int, NS)
startbetas = [0 0 0 0 0 0 0]
startsigma = [1, 1, 1, 1, 1, 1, 1]

function M4Pers(params, data)
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
    tau  = 1 / (1 + exp(-params[6]))
    rho  = 7 * erf(params[7] / sqrt(2))

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
@time (betas, sigma, x, l, h) = em(data, subs, X, startbetas, startsigma, M4Pers,
                                   maxiter=maxiter, emtol=emtol, full=full)

println("\nRecovered group-level parameters (free scale):")
println("betas = ", betas)
println("sigma = ", sigma)

true_params = combine(groupby(data, :sub),
                      :Conf_True => first => :Conf_True,
                      :Disconf_True => first => :Disconf_True,
                      :Conf_False => first => :Conf_False,
                      :Disconf_False => first => :Disconf_False,
                      :Beta => first => :Beta,
                      :tau => first => :tau,
                      :rho => first => :rho)
rename!(true_params, :sub => :subn)

function transform_back(x::Matrix)
    AS_T = x[:, 1]
    AD_T = x[:, 2]
    AS_F = x[:, 3]
    AD_F = x[:, 4]
    p5   = x[:, 5]
    p6   = x[:, 6]
    p7   = x[:, 7]

    Conf_True     = 1.0 ./ (1.0 .+ exp.(-0.5 .* (AS_T .+ AD_T)))
    Disconf_True  = 1.0 ./ (1.0 .+ exp.(-0.5 .* (AS_T .- AD_T)))
    Conf_False    = 1.0 ./ (1.0 .+ exp.(-0.5 .* (AS_F .+ AD_F)))
    Disconf_False = 1.0 ./ (1.0 .+ exp.(-0.5 .* (AS_F .- AD_F)))
    Beta = 25 .+ 25 .* erf.((1 / sqrt(2)) .* p5)
    tau  = 1.0 ./ (1.0 .+ exp.(-p6))
    rho  = 7 .* erf.(p7 ./ sqrt(2))

    return DataFrame(Conf_True = Conf_True, Disconf_True = Disconf_True,
                     Conf_False = Conf_False, Disconf_False = Disconf_False,
                     Beta = Beta, tau = tau, rho = rho)
end

est_df = transform_back(Matrix(x))
insertcols!(est_df, 1, :subn => 1:NS)

est_names = ["Conf_True", "Disconf_True", "Conf_False", "Disconf_False", "Beta", "tau", "rho"]
for p in est_names
    rename!(true_params, Symbol(p) => Symbol("True_", p))
    rename!(est_df, Symbol(p) => Symbol("Estimated_", p))
end
recovery_df = innerjoin(true_params, est_df, on = :subn)

println("\n=== Parameter recovery summary (M4Pers) ===")
for p in est_names
    t = Symbol("True_", p)
    e = Symbol("Estimated_", p)
    r    = cor(recovery_df[!, t], recovery_df[!, e])
    bias = mean(recovery_df[!, e] .- recovery_df[!, t])
    println(rpad(string(t), 18), " cor = ", round(r, digits = 3),
            "   mean bias = ", round(bias, digits = 4))
end

CSV.write(joinpath(@__DIR__, "M4Pers_RecoveryData.csv"), recovery_df)
CSV.write(joinpath(@__DIR__, "M4Pers_TrueParams.csv"), true_params)
CSV.write(joinpath(@__DIR__, "M4Pers_EstimatedParams.csv"), est_df)
println("\nSaved: M4Pers_RecoveryData.csv, M4Pers_TrueParams.csv, M4Pers_EstimatedParams.csv")
