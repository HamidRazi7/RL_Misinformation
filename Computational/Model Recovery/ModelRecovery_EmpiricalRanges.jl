const HERE = @__DIR__
const PARAM_ENV = joinpath(HERE, "..", "Parameter Recovery")
const RL_ROOT = abspath(joinpath(HERE, "..", ".."))
const OUT_DIR = HERE

study_list = [1, 2]

full    = false
emtol   = 1e-3
maxiter = 2000

using Pkg
for d in [
    get(ENV, "EM_DIR", ""),
    joinpath(HERE, "em-master"),
    joinpath(HERE, "..", "em-master"),
    joinpath(HERE, "..", "..", "em-master"),
    joinpath(pwd(), "em-master"),
    "./em-master",
]
    if !isempty(d) && isdir(d) && !(d in LOAD_PATH)
        push!(LOAD_PATH, d)
    end
end

using EM, Distributions, LinearAlgebra, Optim, Statistics, Random
using GLM, DataFrames, NamedArrays, SpecialFunctions, CSV

include(joinpath(HERE, "six_models_common.jl"))

sigmoid(x) = 1 / (1 + exp(-x))

"""
    natural_scale_params(model::String, x::AbstractMatrix) -> Matrix

Map the EM free-scale posterior means (NS x k) to natural-scale parameters,
column order matching `model_param_names(model)`.
"""
function natural_scale_params(model::String, x)
    NS, k = size(x)
    out = Matrix{Float64}(undef, NS, k)
    if model in ["M1", "M2", "M3", "M4"]
        for j in 1:(k - 1)
            out[:, j] .= sigmoid.(x[:, j])
        end
        out[:, k] .= 25 .* (1 .+ erf.(x[:, k] ./ sqrt(2)))
    elseif model == "M5"
        out[:, 1] .= sigmoid.(x[:, 1])
        out[:, 2] .= sigmoid.(x[:, 2])
        out[:, 3] .= 25 .* (1 .+ erf.(x[:, 3] ./ sqrt(2)))
    else
        nd_ct = @. 0.5 * (x[:, 1] + x[:, 2])
        nd_dt = @. 0.5 * (x[:, 1] - x[:, 2])
        nd_cf = @. 0.5 * (x[:, 3] + x[:, 4])
        nd_df = @. 0.5 * (x[:, 3] - x[:, 4])
        out[:, 1] .= sigmoid.(nd_ct)
        out[:, 2] .= sigmoid.(nd_dt)
        out[:, 3] .= sigmoid.(nd_cf)
        out[:, 4] .= sigmoid.(nd_df)
        out[:, 5] .= 25 .+ 25 .* erf.(x[:, 5] ./ sqrt(2))
        out[:, 6] .= 7 .* erf.(x[:, 6] ./ sqrt(2))
    end
    return out
end

for study in study_list
    study_file = joinpath(RL_ROOT, "Data", "Processed", "Study$(study).csv")
    data_raw = CSV.read(study_file, DataFrame)
    rename!(data_raw, :subn => :sub)

    unique_subjects = unique(data_raw.sub)
    subject_map = Dict(unique_subjects[i] => i for i in 1:length(unique_subjects))
    data = copy(data_raw)
    data.sub .= [subject_map[s] for s in data_raw.sub]

    NS = length(unique_subjects)
    subs = 1:NS
    X = ones(Int, NS)

    params_long = DataFrame(sub = Int[], model = String[], parameter = String[], value = Float64[])
    ranges_df = DataFrame(model = String[], parameter = String[], min = Float64[], max = Float64[])

    for model in MODEL_NAMES
        k = model_nparams(model)
        fn = model_function(model)
        println("== Study $study: fitting $model ($k params) to real data ==")
        t0 = time()
        (betas, sigma, x, l, h) = em(data, subs, X, startbetas_for(model),
                                     startsigma_for(model), fn;
                                     maxiter = maxiter, emtol = emtol, full = full)
        println("   converged in ", round(time() - t0; digits = 1), " s")

        nat = natural_scale_params(model, x)
        pnames = model_param_names(model)
        for (j, pname) in enumerate(pnames)
            for s in subs
                push!(params_long, (s, model, pname, nat[s, j]))
            end
            lo, hi = extrema(nat[:, j])
            push!(ranges_df, (model, pname, lo, hi))
        end
    end

    CSV.write(joinpath(OUT_DIR, "empirical_params_study$(study).csv"), params_long)
    CSV.write(joinpath(OUT_DIR, "empirical_ranges_study$(study).csv"), ranges_df)
    println("Saved empirical ranges for study $study.")
    println(ranges_df)
end

println("Phase A complete.")
