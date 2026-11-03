using Random, Distributions, SpecialFunctions

const MODEL_NAMES = ["M1", "M2", "M3", "M4", "M5", "M6"]

model_nparams(m::String) =
    m == "M1" ? 3 : m == "M2" ? 4 : m == "M3" ? 4 :
    m == "M4" ? 5 : m == "M5" ? 3 : 6

startbetas_for(m::String) = zeros(1, model_nparams(m))
startsigma_for(m::String) = ones(Int, model_nparams(m))

model_param_names(m::String) =
    m == "M1" ? ["Conf_True", "Conf_False", "Beta"] :
    m == "M2" ? ["Conf_True", "Conf_False", "Disconf_False", "Beta"] :
    m == "M3" ? ["Conf_True", "Disconf_True", "Conf_False", "Beta"] :
    m == "M4" ? ["Conf_True", "Disconf_True", "Conf_False", "Disconf_False", "Beta"] :
    m == "M5" ? ["Confirmatory", "Disconfirmatory", "Beta"] :
                ["Conf_True", "Disconf_True", "Conf_False", "Disconf_False", "Beta", "rho"]

function M1(params, data)
    Conf_True = 1 / (1 + exp(-params[1]))
    Conf_False = 1 / (1 + exp(-params[2]))
    Disconf_True = Conf_True
    Disconf_False = Conf_False
    Beta = 25 * (1 + erf(params[3] / sqrt(2)))

    R, C1, C2, TrialType, FeedbackType, Condition = (
        data.Reward, data.C1, data.C2, data.TrialType,
        data.FeedbackType, data.Condition)

    lik = 0.0
    Q = zeros(typeof(Beta), 2, 4)
    for t in eachindex(C1)
        QC = Condition[t]
        chosen = C1[t] == 1 ? 1 : 2
        unchosen = 3 - chosen
        lik += -log1p(exp(-Beta * (Q[chosen, QC] - Q[unchosen, QC])))

        ft = FeedbackType[t]
        pe = ft == 1 ? (R[t] - Q[chosen, QC]) : (R[t] - Q[unchosen, QC])
        lr_factual = TrialType[t] == 1 ? (pe > 0 ? Conf_True : Disconf_True) :
                                        (pe > 0 ? Conf_False : Disconf_False)
        lr_C_factual = TrialType[t] == 1 ? (pe > 0 ? Disconf_True : Conf_True) :
                                           (pe > 0 ? Disconf_False : Conf_False)
        lr = ft == 1 ? lr_factual : lr_C_factual

        option = ft == 1 ? chosen : unchosen
        Q[option, QC] = (1 - lr) * Q[option, QC] + lr * R[t]
    end
    return -lik
end

function M2(params, data)
    Conf_True = 1 / (1 + exp(-params[1]))
    Conf_False = 1 / (1 + exp(-params[2]))
    Disconf_False = 1 / (1 + exp(-params[3]))
    Disconf_True = Conf_True
    Beta = 25 * (1 + erf(params[4] / sqrt(2)))

    R, C1, C2, TrialType, FeedbackType, Condition = (
        data.Reward, data.C1, data.C2, data.TrialType,
        data.FeedbackType, data.Condition)

    lik = 0.0
    Q = zeros(typeof(Beta), 2, 4)
    for t in eachindex(C1)
        QC = Condition[t]
        chosen = C1[t] == 1 ? 1 : 2
        unchosen = 3 - chosen
        lik += -log1p(exp(-Beta * (Q[chosen, QC] - Q[unchosen, QC])))

        ft = FeedbackType[t]
        pe = ft == 1 ? (R[t] - Q[chosen, QC]) : (R[t] - Q[unchosen, QC])
        lr_factual = TrialType[t] == 1 ? (pe > 0 ? Conf_True : Disconf_True) :
                                        (pe > 0 ? Conf_False : Disconf_False)
        lr_C_factual = TrialType[t] == 1 ? (pe > 0 ? Disconf_True : Conf_True) :
                                           (pe > 0 ? Disconf_False : Conf_False)
        lr = ft == 1 ? lr_factual : lr_C_factual

        option = ft == 1 ? chosen : unchosen
        Q[option, QC] = (1 - lr) * Q[option, QC] + lr * R[t]
    end
    return -lik
end

function M3(params, data)
    Conf_True = 1 / (1 + exp(-params[1]))
    Disconf_True = 1 / (1 + exp(-params[2]))
    Conf_False = 1 / (1 + exp(-params[3]))
    Disconf_False = Conf_False
    Beta = 25 * (1 + erf(params[4] / sqrt(2)))

    R, C1, C2, TrialType, FeedbackType, Condition = (
        data.Reward, data.C1, data.C2, data.TrialType,
        data.FeedbackType, data.Condition)

    lik = 0.0
    Q = zeros(typeof(Beta), 2, 4)
    for t in eachindex(C1)
        QC = Condition[t]
        chosen = C1[t] == 1 ? 1 : 2
        unchosen = 3 - chosen
        lik += -log1p(exp(-Beta * (Q[chosen, QC] - Q[unchosen, QC])))

        ft = FeedbackType[t]
        pe = ft == 1 ? (R[t] - Q[chosen, QC]) : (R[t] - Q[unchosen, QC])
        lr_factual = TrialType[t] == 1 ? (pe > 0 ? Conf_True : Disconf_True) :
                                        (pe > 0 ? Conf_False : Disconf_False)
        lr_C_factual = TrialType[t] == 1 ? (pe > 0 ? Disconf_True : Conf_True) :
                                           (pe > 0 ? Disconf_False : Conf_False)
        lr = ft == 1 ? lr_factual : lr_C_factual

        option = ft == 1 ? chosen : unchosen
        Q[option, QC] = (1 - lr) * Q[option, QC] + lr * R[t]
    end
    return -lik
end

function M4(params, data)
    Conf_True = 1 / (1 + exp(-params[1]))
    Disconf_True = 1 / (1 + exp(-params[2]))
    Conf_False = 1 / (1 + exp(-params[3]))
    Disconf_False = 1 / (1 + exp(-params[4]))
    Beta = 25 * (1 + erf(params[5] / sqrt(2)))

    R, C1, C2, TrialType, FeedbackType, Condition = (
        data.Reward, data.C1, data.C2, data.TrialType,
        data.FeedbackType, data.Condition)

    lik = 0.0
    Q = zeros(typeof(Beta), 2, 4)
    for t in eachindex(C1)
        QC = Condition[t]
        chosen = C1[t] == 1 ? 1 : 2
        unchosen = 3 - chosen
        lik += -log1p(exp(-Beta * (Q[chosen, QC] - Q[unchosen, QC])))

        ft = FeedbackType[t]
        pe = ft == 1 ? (R[t] - Q[chosen, QC]) : (R[t] - Q[unchosen, QC])
        lr_factual = TrialType[t] == 1 ? (pe > 0 ? Conf_True : Disconf_True) :
                                        (pe > 0 ? Conf_False : Disconf_False)
        lr_C_factual = TrialType[t] == 1 ? (pe > 0 ? Disconf_True : Conf_True) :
                                           (pe > 0 ? Disconf_False : Conf_False)
        lr = ft == 1 ? lr_factual : lr_C_factual

        option = ft == 1 ? chosen : unchosen
        Q[option, QC] = (1 - lr) * Q[option, QC] + lr * R[t]
    end
    return -lik
end

function M5(params, data)
    Confirmatory = 1 / (1 + exp(-params[1]))
    Disconfirmatory = 1 / (1 + exp(-params[2]))
    Beta = 25 * (1 + erf(params[3] / sqrt(2)))

    R, C1, C2, FeedbackType, Condition = (
        data.Reward, data.C1, data.C2, data.FeedbackType, data.Condition)

    lik = 0.0
    Q = zeros(typeof(Beta), 2, 4)
    for t in eachindex(C1)
        QC = Condition[t]
        chosen = C1[t] == 1 ? 1 : 2
        unchosen = 3 - chosen
        lik += -log1p(exp(-Beta * (Q[chosen, QC] - Q[unchosen, QC])))

        chosen_feedback = FeedbackType[t] == 1
        updated_option = chosen_feedback ? chosen : unchosen
        pe = R[t] - Q[updated_option, QC]

        is_confirmatory = chosen_feedback == (pe > 0)
        lr = is_confirmatory ? Confirmatory : Disconfirmatory
        Q[updated_option, QC] = (1 - lr) * Q[updated_option, QC] + lr * R[t]
    end
    return -lik
end

function M6(params, data)
    AS_T, AD_T, AS_F, AD_F = params[1], params[2], params[3], params[4]
    nd_conf_true = 0.5 * (AS_T + AD_T)
    Conf_True = 1 / (1 + exp(-nd_conf_true))
    nd_disconf_true = 0.5 * (AS_T - AD_T)
    Disconf_True = 1 / (1 + exp(-nd_disconf_true))
    nd_conf_false = 0.5 * (AS_F + AD_F)
    Conf_False = 1 / (1 + exp(-nd_conf_false))
    nd_disconf_false = 0.5 * (AS_F - AD_F)
    Disconf_False = 1 / (1 + exp(-nd_disconf_false))

    Beta = 25 + 25 * erf(params[5] / sqrt(2))
    rho = 7 * erf(params[6] / sqrt(2))
    tau = 1.0

    R, C1, C2, TrialType, FeedbackType, Condition = (
        data.Reward, data.C1, data.C2, data.TrialType,
        data.FeedbackType, data.Condition)

    lik = 0.0
    Q = zeros(typeof(Beta), 2, 4)
    C = zeros(typeof(Beta), 2, 4)
    for t in eachindex(C1)
        QC = Condition[t]
        chosen = C1[t] == 1 ? 1 : 2
        unchosen = 3 - chosen
        lik += -log1p(exp(-Beta * (Q[chosen, QC] - Q[unchosen, QC]) -
                          rho * (C[chosen, QC] - C[unchosen, QC])))

        ft = FeedbackType[t]
        pe = ft == 1 ? (R[t] - Q[chosen, QC]) : (R[t] - Q[unchosen, QC])
        lr_factual = TrialType[t] == 1 ? (pe > 0 ? Conf_True : Disconf_True) :
                                        (pe > 0 ? Conf_False : Disconf_False)
        lr_C_factual = TrialType[t] == 1 ? (pe > 0 ? Disconf_True : Conf_True) :
                                           (pe > 0 ? Disconf_False : Conf_False)
        lr = ft == 1 ? lr_factual : lr_C_factual

        option = ft == 1 ? chosen : unchosen
        Q[option, QC] = (1 - lr) * Q[option, QC] + lr * R[t]

        C[chosen, QC] = C[chosen, QC] + tau * (1 - C[chosen, QC])
        C[unchosen, QC] = C[unchosen, QC] + tau * (0 - C[unchosen, QC])
    end
    return -lik
end

model_function(m::String) =
    m == "M1" ? M1 : m == "M2" ? M2 : m == "M3" ? M3 :
    m == "M4" ? M4 : m == "M5" ? M5 : M6

"""
    simulate_subject_params(rng, model, ranges)

Draw one subject's parameters on the natural scale, uniformly within the
empirical [min, max] range per parameter (`ranges::Dict{String,Vector{Float64}}`).
"""
function simulate_subject_params(rng, model::String, ranges)
    vals = Float64[]
    for pname in model_param_names(model)
        lo, hi = ranges[pname]
        push!(vals, rand(rng, Uniform(lo, hi)))
    end
    return vals
end

function sim_lr_set(model::String, p::Vector{Float64})
    if model == "M1"
        return (ct=p[1], dt=p[1], cf=p[2], df=p[2], beta=p[3], rho=0.0)
    elseif model == "M2"
        return (ct=p[1], dt=p[1], cf=p[2], df=p[3], beta=p[4], rho=0.0)
    elseif model == "M3"
        return (ct=p[1], dt=p[2], cf=p[3], df=p[3], beta=p[4], rho=0.0)
    elseif model == "M4"
        return (ct=p[1], dt=p[2], cf=p[3], df=p[4], beta=p[5], rho=0.0)
    elseif model == "M5"
        return (conf=p[1], disconf=p[2], beta=p[3], rho=0.0)
    else
        return (ct=p[1], dt=p[2], cf=p[3], df=p[4], beta=p[5], rho=p[6])
    end
end

"""
    simulate_group!(df, rng, model, params_list, n_trials, n_condition)

Append one simulated subject to `df` (a Vector of Dicts), generating choices
from `model` with `params`. Experimental structure mirrors the real task:
4 conditions x 40 trials shuffled, half true/false trials shuffled,
feedback type (chosen/unchosen) random per trial, gain/loss reward structure.
"""
function simulate_subject!(df, rng, model::String, p, sub::Int,
                           n_trials::Int, n_condition::Int;
                           trials_per_condition::Int)
    conditions_vector = repeat(1:n_condition, inner = trials_per_condition)
    shuffled_conditions = shuffle(rng, conditions_vector)
    trialtype = shuffle(rng, vcat(fill(true, round(Int, n_trials / 2)),
                                  fill(false, n_trials - round(Int, n_trials / 2))))

    Q = zeros(Float64, 2, 4)
    C = zeros(Float64, 2, 4)
    has_persev = model == "M6"

    for t in 1:n_trials
        QC = shuffled_conditions[t]
        gain = QC in [1, 2]
        if QC == 1 || QC == 3
            p1t, p2t = 0.80, 0.20
            p1f, p2f = 0.50, 0.50
        else
            p1t, p2t = 0.50, 0.50
            p1f, p2f = 0.80, 0.20
        end
        p1, p2 = trialtype[t] ? (p1t, p2t) : (p1f, p2f)

        dv1 = p.beta * (Q[1, QC] - Q[2, QC])
        if has_persev
            dv1 += p.rho * (C[1, QC] - C[2, QC])
        end
        prob_choose_1 = 1 / (1 + exp(-dv1))
        c1 = rand(rng) <= prob_choose_1 ? 1 : 0
        c2 = 1 - c1

        r1 = rand(rng) <= p1 ? (gain ? 10.0 : -1.0) : (gain ? 1.0 : -10.0)
        r2 = rand(rng) <= p2 ? (gain ? 10.0 : -1.0) : (gain ? 1.0 : -10.0)

        ft = rand(rng) <= 0.5 ? 1 : 0
        chosen = c1 == 1 ? 1 : 2
        unchosen = 3 - chosen
        R = ft == 1 ? (c1 == 1 ? r1 : r2) : (c1 == 1 ? r2 : r1)

        pe = ft == 1 ? (R - Q[chosen, QC]) : (R - Q[unchosen, QC])

        if model == "M5"
            is_confirmatory = (ft == 1) == (pe > 0)
            lr = is_confirmatory ? p.conf : p.disconf
            option = ft == 1 ? chosen : unchosen
            Q[option, QC] = (1 - lr) * Q[option, QC] + lr * R
        else
            tt_true = trialtype[t]
            lr_factual = tt_true ? (pe > 0 ? p.ct : p.dt) : (pe > 0 ? p.cf : p.df)
            lr_C_factual = tt_true ? (pe > 0 ? p.dt : p.ct) : (pe > 0 ? p.df : p.cf)
            lr = ft == 1 ? lr_factual : lr_C_factual
            option = ft == 1 ? chosen : unchosen
            Q[option, QC] = (1 - lr) * Q[option, QC] + lr * R
        end

        if has_persev
            C[chosen, QC] = C[chosen, QC] + 1.0 * (1 - C[chosen, QC])
            C[unchosen, QC] = C[unchosen, QC] + 1.0 * (0 - C[unchosen, QC])
        end

        push!(df, Dict(
            :sub => sub,
            :Condition => QC,
            :C1 => Float64(c1),
            :C2 => Float64(c2),
            :Reward => R,
            :FeedbackType => ft,
            :TrialType => trialtype[t],
        ))
    end
    return nothing
end

"""
    make_synthetic_dataset(study, iter, true_model, n_subjects, ranges; seed_base)

Generate the synthetic group for one recovery unit. The RNG seed depends only
on (study, iter, true_model), so every fit job for the unit regenerates an
IDENTICAL dataset. Returns a DataFrame with the columns the likelihood
functions expect.
"""
function make_synthetic_dataset(study::Int, iter::Int, true_model::String,
                                n_subjects::Int, ranges; n_trials::Int = 160,
                                n_condition::Int = 4)
    seed = study * 1_000_000 + iter * 1_000 + model_index(true_model)
    rng = MersenneTwister(seed)
    rows = Vector{Dict{Symbol,Any}}()
    trials_per_condition = div(n_trials, n_condition)
    for s in 1:n_subjects
        p_nat = simulate_subject_params(rng, true_model, ranges)
        p = sim_lr_set(true_model, p_nat)
        simulate_subject!(rows, rng, true_model, p, s, n_trials, n_condition;
                          trials_per_condition = trials_per_condition)
    end
    return DataFrame(rows)
end

model_index(m::String) = findfirst(==(m), MODEL_NAMES)

const NS_PER_STUDY = Dict(1 => 47, 2 => 57)
