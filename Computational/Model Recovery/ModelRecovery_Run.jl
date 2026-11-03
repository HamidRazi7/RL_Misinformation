# usage: julia ModelRecovery_Run.jl <worker_id> <num_workers> [n_iter]

const HERE = @__DIR__
worker_id   = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 1
num_workers = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 1
n_iter      = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 50

full    = false
emtol   = 1e-3
maxiter = 2000
loocv_maxiter = 300
n_trials = 160
n_condition = 4
n_subjects_override = get(ENV, "RECOVERY_N_SUBJECTS", "")
results_prefix = get(ENV, "RECOVERY_RESULTS_PREFIX", "")
studies_filter = get(ENV, "RECOVERY_STUDIES", "")
studies = isempty(studies_filter) ? [1, 2] : [parse(Int, s) for s in split(studies_filter, ',')]

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

range_file = get(ENV, "RECOVERY_RANGES", "")
ranges_by_study = Dict{Int,Dict{String,Dict{String,Vector{Float64}}}}()
for study in [1, 2]
    src = isempty(range_file) ? "empirical_ranges_study$(study).csv" : range_file
    df = CSV.read(joinpath(HERE, src), DataFrame)
    d = Dict{String,Dict{String,Vector{Float64}}}()
    for r in eachrow(df)
        if !haskey(d, r.model)
            d[r.model] = Dict{String,Vector{Float64}}()
        end
        d[r.model][r.parameter] = [Float64(r.min), Float64(r.max)]
    end
    ranges_by_study[study] = d
end

function result_dir(study)
    isempty(results_prefix) ? joinpath(HERE, "Results_Study$(study)") :
        joinpath(HERE, "$(results_prefix)_Study$(study)")
end

function job_path(study, iter, true_m, fit_m)
    joinpath(result_dir(study),
             "scores_s$(study)_i$(iter)_$(true_m)_$(fit_m).csv")
end

jobs = Tuple{Int,Int,String,String}[]
for study in studies, iter in 1:n_iter, tm in MODEL_NAMES, fm in MODEL_NAMES
    push!(jobs, (study, iter, tm, fm))
end

my_jobs = [j for (gi, j) in enumerate(jobs) if gi % num_workers == worker_id - 1]
println("Worker $worker_id / $num_workers: ", length(my_jobs), " jobs (of ", length(jobs), ")")
flush(stdout)

function main(worker_id, num_workers, my_jobs)
    done = failed = 0
    t_start = time()
    for (ji, (study, iter, true_m, fit_m)) in enumerate(my_jobs)
        out_path = job_path(study, iter, true_m, fit_m)
        isfile(out_path) && (done += 1; continue)

    NS = isempty(n_subjects_override) ? NS_PER_STUDY[study] : parse(Int, n_subjects_override)

    local liks
    local ok = false
    for attempt in 1:2
        try
            data = make_synthetic_dataset(study, iter, true_m, NS,
                                          ranges_by_study[study][true_m];
                                          n_trials = n_trials,
                                          n_condition = n_condition)
            subs = 1:NS
            X = ones(Int, NS)
            fn = model_function(fit_m)

            (betas, sigma, x, l, h) = em(data, subs, X, startbetas_for(fit_m),
                                         startsigma_for(fit_m), fn;
                                         maxiter = maxiter, emtol = emtol, full = full)
            liks = loocv(data, subs, x, X, betas, sigma, fn;
                         maxiter = loocv_maxiter, emtol = emtol, full = full)
            ok = true
            break
        catch e
            println("Worker $worker_id: ERROR attempt $attempt s$study i$iter $true_m->$fit_m: ",
                    sprint(showerror, e))
            flush(stdout)
        end
    end

        if ok
            mkpath(dirname(out_path))
            CSV.write(out_path, DataFrame(Values = liks))
            done += 1
            el = round(time() - t_start; digits = 1)
            println("[$el s] Worker $worker_id completed s$study i$iter $true_m->$fit_m sum=",
                    round(sum(liks); digits = 1), "  (worker total: $done)")
        else
            failed += 1
            open(joinpath(result_dir(study),
                          "ERROR_s$(study)_i$(iter)_$(true_m)_$(fit_m).txt"), "w") do io
                println(io, "job failed twice")
            end
        end
        flush(stdout)
    end

    println("Worker $worker_id finished: $done done, $failed failed.")
end

main(worker_id, num_workers, my_jobs)
