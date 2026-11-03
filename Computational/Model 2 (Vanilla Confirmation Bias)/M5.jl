# usage: julia M5.jl <study>

if isempty(ARGS)
    error("Usage: julia M5.jl <study: 1|2> [--skip-loocv]")
end

study = parse(Int, ARGS[1])
study in (1, 2) || error("Study must be 1 or 2")
run_loocv = !("--skip-loocv" in ARGS)

root = normpath(joinpath(@__DIR__, "..", ".."))
pushfirst!(LOAD_PATH, joinpath(root, "em-master", "src"))

using CSV
using DataFrames
using EM
using LinearAlgebra
using Optim
using SpecialFunctions
using Statistics

data_path = joinpath(root, "Data", "Processed", "Study$(study).csv")
output_dir = joinpath(root, "Data", "Processed", "Results")
mkpath(output_dir)

data = CSV.read(data_path, DataFrame)
rename!(data, :subn => :sub)

subject_ids = unique(data.sub)
subject_map = Dict(subject_ids[i] => i for i in eachindex(subject_ids))
data.sub = [subject_map[id] for id in data.sub]
sort!(data, [:sub, :Trial])

subjects = sort(unique(data.sub))
n_subjects = length(subjects)
X = ones(Int, n_subjects)
start_betas = zeros(1, 3)
start_sigma = ones(3)
em_tolerance = 1e-3

function M5(params, subject_data)
    confirmatory = 1 / (1 + exp(-params[1]))
    disconfirmatory = 1 / (1 + exp(-params[2]))
    inverse_temperature = 25 * (1 + erf(params[3] / sqrt(2)))

    reward = subject_data.Reward
    chose_o1 = subject_data.C1
    feedback_type = subject_data.FeedbackType
    condition = subject_data.Condition

    q_values = zeros(typeof(inverse_temperature), 2, 4)
    log_likelihood = 0.0

    for trial in eachindex(chose_o1)
        pair = condition[trial]
        chosen = chose_o1[trial] == 1 ? 1 : 2
        unchosen = 3 - chosen

        value_difference = q_values[chosen, pair] - q_values[unchosen, pair]
        log_likelihood += -log1p(exp(-inverse_temperature * value_difference))

        chosen_feedback = feedback_type[trial] == 1
        updated_option = chosen_feedback ? chosen : unchosen
        prediction_error = reward[trial] - q_values[updated_option, pair]

        is_confirmatory = chosen_feedback == (prediction_error > 0)
        learning_rate = is_confirmatory ? confirmatory : disconfirmatory

        q_values[updated_option, pair] =
            (1 - learning_rate) * q_values[updated_option, pair] +
            learning_rate * reward[trial]
    end

    return -log_likelihood
end

println("Fitting M5 to Study $study (N=$n_subjects)")
(betas, sigma, x, likelihoods, hessians) = em(
    data,
    subjects,
    X,
    start_betas,
    start_sigma,
    M5;
    maxiter = 2000,
    emtol = em_tolerance,
    full = false,
)

group_parameters = DataFrame(
    parameter = ["alpha_confirmatory", "alpha_disconfirmatory", "beta"],
    unconstrained_estimate = vec(betas),
    transformed_estimate = [
        1 / (1 + exp(-betas[1])),
        1 / (1 + exp(-betas[2])),
        25 * (1 + erf(betas[3] / sqrt(2))),
    ],
)

CSV.write(
    joinpath(output_dir, "M5_group_parameters_study$(study).csv"),
    group_parameters,
)

subject_parameters = DataFrame(
    sub = subject_ids,
    alpha_confirmatory = 1 ./ (1 .+ exp.(-x[:, 1])),
    alpha_disconfirmatory = 1 ./ (1 .+ exp.(-x[:, 2])),
    beta = 25 .* (1 .+ erf.(x[:, 3] ./ sqrt(2))),
)
CSV.write(
    joinpath(output_dir, "M5_subject_parameters_study$(study).csv"),
    subject_parameters,
)

if run_loocv
    println("Computing leave-one-subject-out cross-validation")
    loocv_values = loocv(
        data,
        subjects,
        x,
        X,
        betas,
        sigma,
        M5;
        maxiter = 2000,
        emtol = em_tolerance,
        full = false,
    )
    CSV.write(
        joinpath(output_dir, "M5_LOOCV_study$(study).csv"),
        DataFrame(M5 = loocv_values),
    )
end

println(group_parameters)
