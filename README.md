# RL_Misinformation

```
Code for the bandit misinformation task and analysis.

This repository contains the pipeline from raw data collection to computational modeling.

Please refer to Repository_Guide.docx for a dictionary of the variables and the datasets.

Feel free to get in touch if you have any questions.


├── Behavioural/                               # R scripts for raw data processing and statistical analysis
│   ├── Analysis.R                             # Behavioral analysis
│   ├── LearningCurves.R                       # Learning-curve statistics (Figure S6)
│   ├── ProcessingRaw.R                        # Cleans RAW data into Processed data
│   └── TaskChecks.R                           # Task checks (feedback probabilities, displayed reward, catch trials, debriefing)
├── Computational/                             # Julia notebooks for Q-Learning models
│   ├── Hypothesis Tests/                      # Hierarchical t-tests of Model 5rho and the reparameterisation check
│   ├── Model 1/                               # One learning rate each for verified and debunked feedback
│   ├── Model 2 (Vanilla Confirmation Bias)/   # Asymmetric learning without the verification cue
│   ├── Model 3/                               # Asymmetric learning for verified feedback only
│   ├── Model 4/                               # Asymmetric learning for debunked feedback only
│   ├── Model 5/                               # Fully Asymmetric (four learning rates)
│   ├── Model 5rho (Winning)/                  # Model 5 with perseveration, the winning model
│   ├── Model Comparison/                      # Group-level model comparison and exceedance probabilities
│   ├── Model Recovery/                        # Model recovery and identifiability framework
│   ├── Models 1rho-4rho/                      # Models 1 to 4 with perseveration (supplementary)
│   ├── Parameter Recovery/                    # Parameter recovery for the winning and gradual perseveration models
│   ├── SuppModel1/                            # Disentangling Confirmation Bias from Positivity Bias Model
│   ├── SuppModel2/                            # Gain/Loss Model
│   └── SuppModel3/                            # Gradual Perseveration Model
├── Data/                                      # Experimental data storage
│   ├── model_free_sim_cache/                  # Model simulations for Figure 6 (written by Plots/Figures/Fig6_Simulations.R)
│   ├── Processed/                             # Processed Study and Stats files (Input for Models/Plots)
│   │   └── Results/                           # Tables written by the analysis scripts
│   └── Raw/                                   # RAWS1.csv, RAWS2.csv (Input for Behavioural/)
├── em-master/                                 # EM algorithm dependencies (see the original code by Nathaniel Daw)
├── Plots/                                     # R scripts for the main and supplemental figures
│   ├── Figures/                               # Main figures
│   └── Supplemental Figures/                  # Supplemental figures
├── Repository_Guide.docx                      # Detailed navigation guide, variables, and workflow
└── Task/                                      # Source code for the Bandit Misinformation Task
```

The model folders follow the paper's numbering. The files inside keep the numbering used while the
analyses were run (for example, `Model 2 (Vanilla Confirmation Bias)/` holds `M5.jl`);
`Plots/model_renumbering.R` maps the two. In the code, True/False are the feedback labelled
verified/debunked in the paper, and "accuracy" is the verification cue.

## Running the code

Set the working directory to the repository root (opening `RL_Misinformation.Rproj` in RStudio does
this).

- R 4.3 or later: tidyverse, data.table, cowplot, here, lme4
- Julia (tested with 1.12). Run `using Pkg; Pkg.activate("em-master"); Pkg.instantiate()` once to
  install the package versions used for the paper. EM's call to `optimize` fails under Optim 2.
- MATLAB with the VBA toolbox (https://mbb-team.github.io/VBA-toolbox/) for Bayesian model
  selection. Place it in a folder named `VBA-toolbox` at the root.

## Figures

| Figure | Script |
|---|---|
| 1 | `Plots/Figures/Fig1.R` |
| 2 | `Plots/Figures/Fig2.R` |
| 3 | `Plots/Figures/Fig3.R` |
| 4 | `Plots/Figures/Fig4.R` |
| 5 | `Plots/Figures/Fig5_Study1.R`, `Plots/Figures/Fig5_Study2.R` |
| 6 | `Plots/Figures/Fig6_ChoiceRepetition.R` (simulations: `Plots/Figures/Fig6_Simulations.R`) |
| S1 | `Plots/Supplemental Figures/FigS1.R` |
| S2 | `Plots/Supplemental Figures/FigS2.R` |
| S3 | `Plots/Supplemental Figures/FigS3.R` |
| S4 | `Plots/Supplemental Figures/FigS4ab_ModelRecovery.R`, `Computational/Parameter Recovery/M4Rho_heatmap.R` (c), `Plots/Supplemental Figures/FigS4de_ParameterCorrelations.R` |
| S5 | `Plots/Supplemental Figures/FigS5.R` |
| S6 | `Plots/Supplemental Figures/FigS6.R` |
