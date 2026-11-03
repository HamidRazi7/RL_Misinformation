library(dplyr)
library(tidyr)

data_out <- file.path("Data", "Processed", "Results")
dir.create(data_out, recursive = TRUE, showWarnings = FALSE)

paired_result <- function(wide, first, second, label) {
  test <- t.test(wide[[first]], wide[[second]], paired = TRUE)
  difference <- wide[[first]] - wide[[second]]
  data.frame(
    comparison = label,
    n = length(difference),
    mean_first = mean(wide[[first]]),
    mean_second = mean(wide[[second]]),
    mean_difference = mean(difference),
    t = unname(test$statistic),
    df = unname(test$parameter),
    p = test$p.value
  )
}

one_sample_result <- function(x, label, mu) {
  test <- t.test(x, mu = mu)
  data.frame(
    comparison = label,
    n = length(x),
    mean = mean(x),
    test_value = mu,
    t = unname(test$statistic),
    df = unname(test$parameter),
    p = test$p.value
  )
}

all_task <- list()
all_catch <- list()
all_debrief <- list()

for (study in 1:2) {
  raw <- read.csv(file.path("Data", "Raw", sprintf("RAWS%d.csv", study)))
  processed <- read.csv(file.path("Data", "Processed", sprintf("Study%d.csv", study)))
  included_ids <- unique(processed$subn)

  all_task[[study]] <- raw |>
    filter(subn %in% included_ids, Condition %in% 1:4) |>
    mutate(
      Study = paste("Study", study),
      Cue = if_else(TrialType, "Verified", "Debunked"),
      DisplayedOption = paste0("O", if_else(FeedbackType == 1, Choice, 3 - Choice)),
      Solvability = if_else(Condition %in% c(1, 3), "Solvable", "Unsolvable"),
      FavourableDisplayedOutcome = if_else(Condition.Type == "gain", Reward == 10, Reward == -1),
      ProgrammedProbability = case_when(
        Solvability == "Solvable" & Cue == "Verified" & DisplayedOption == "O1" ~ 0.80,
        Solvability == "Solvable" & Cue == "Verified" & DisplayedOption == "O2" ~ 0.20,
        Solvability == "Unsolvable" & Cue == "Debunked" & DisplayedOption == "O1" ~ 0.80,
        Solvability == "Unsolvable" & Cue == "Debunked" & DisplayedOption == "O2" ~ 0.20,
        TRUE ~ 0.50
      ),
      Condition = as.integer(Condition), Reward = as.numeric(Reward)
    ) |>
    select(Study, subn, Condition, Cue, DisplayedOption, Solvability, FavourableDisplayedOutcome,
           ProgrammedProbability, Reward)

  all_catch[[study]] <- raw |>
    filter(Catch.Trial != "", !is.na(TrialType)) |>
    transmute(Study = paste("Study", study), subn, analysed_sample = subn %in% included_ids,
              Correct = (TrialType & Catch.Trial == "Accurate") |
                        (!TrialType & Catch.Trial == "Inaccurate"))

  all_debrief[[study]] <- raw |>
    filter(!is.na(Q), trimws(Q) != "", subn %in% included_ids) |>
    transmute(Study = paste("Study", study), subn, response_code = tolower(trimws(Q))) |>
    distinct()
}

task_data <- bind_rows(all_task)

debrief_summary <- bind_rows(all_debrief) |>
  mutate(response = case_when(
    response_code == "a" ~ "Ignored",
    response_code == "ba" ~ "Avoided: believed the actual outcome was the opposite",
    startsWith(response_code, "bb") ~ "Avoided: did not want to be falsely told 10 points again",
    response_code == "c" ~ "Selected the option more",
    TRUE ~ "Other"
  )) |>
  count(Study, response, name = "n") |>
  group_by(Study) |>
  mutate(n_respondents = sum(n), percentage = 100 * n / n_respondents) |>
  ungroup()
write.csv(debrief_summary, file.path(data_out, "debriefing_summary.csv"), row.names = FALSE)

realised <- task_data |>
  group_by(Study, subn, Solvability, Cue, DisplayedOption) |>
  summarise(realised_probability = mean(FavourableDisplayedOutcome),
            programmed_probability = first(ProgrammedProbability), .groups = "drop")

realised_tests <- realised |>
  group_by(Study, Solvability, Cue, DisplayedOption) |>
  group_modify(~one_sample_result(.x$realised_probability, "Realised vs programmed probability",
                                  mu = first(.x$programmed_probability))) |>
  ungroup()

matched_tests <- list()
for (study in unique(realised$Study)) {
  for (option in c("O1", "O2")) {
    wide <- realised |>
      filter(Study == study, DisplayedOption == option) |>
      mutate(cell = paste(Solvability, Cue, sep = "_")) |>
      select(subn, cell, realised_probability) |>
      pivot_wider(names_from = cell, values_from = realised_probability)
    matched_tests[[paste(study, option)]] <- bind_rows(
      paired_result(wide, "Solvable_Verified", "Unsolvable_Debunked",
                    "Asymmetric cells: solvable-verified vs unsolvable-debunked"),
      paired_result(wide, "Solvable_Debunked", "Unsolvable_Verified",
                    "50/50 cells: solvable-debunked vs unsolvable-verified")
    ) |>
      mutate(Study = study, DisplayedOption = option, .before = 1)
  }
}
write.csv(realised_tests, file.path(data_out, "realised_probability_tests.csv"), row.names = FALSE)
write.csv(bind_rows(matched_tests), file.path(data_out, "realised_probability_matched_tests.csv"),
          row.names = FALSE)

reward <- task_data |>
  group_by(Study, subn, Condition, Cue) |>
  summarise(points = sum(Reward), .groups = "drop")
reward <- reward |>
  group_by(Study, subn, Condition) |>
  summarise(points = sum(points), .groups = "drop") |>
  mutate(Cue = "All") |>
  bind_rows(reward)

reward_tests <- list()
for (study in unique(reward$Study)) {
  for (cue in c("All", "Verified", "Debunked")) {
    wide <- reward |>
      filter(Study == study, Cue == cue) |>
      select(subn, Condition, points) |>
      pivot_wider(names_from = Condition, values_from = points, names_prefix = "condition_")
    reward_tests[[paste(study, cue)]] <- bind_rows(
      paired_result(wide, "condition_1", "condition_2", "Solvable vs unsolvable gain pair"),
      paired_result(wide, "condition_3", "condition_4", "Solvable vs unsolvable loss pair")
    ) |>
      mutate(Study = study, Cue = cue, .before = 1)
  }
}
reward_tests <- bind_rows(reward_tests) |>
  group_by(Study) |>
  mutate(p_fdr = p.adjust(p, method = "fdr"), .after = p) |>
  ungroup()
write.csv(reward_tests, file.path(data_out, "accumulated_reward_tests.csv"), row.names = FALSE)

catch <- bind_rows(all_catch)
catch_summary <- bind_rows(mutate(catch, sample = "All recruited"),
                           mutate(filter(catch, analysed_sample), sample = "Analysed")) |>
  group_by(Study, sample, subn) |>
  summarise(correct = sum(Correct), trials = n(), .groups = "drop_last") |>
  summarise(n_participants = n(), accuracy = sum(correct) / sum(trials),
            more_than_one_wrong = sum(trials - correct > 1), .groups = "drop")
write.csv(catch_summary, file.path(data_out, "catch_accuracy.csv"), row.names = FALSE)

print(debrief_summary, n = Inf)
print(catch_summary)
print(reward_tests |> select(Study, Cue, comparison, mean_first, mean_second, t, df, p, p_fdr),
      n = Inf, width = Inf)
cat("\nRealised vs programmed probability, smallest p:", signif(min(realised_tests$p), 3), "\n")
cat("Matched-cell comparisons, smallest p:", signif(min(bind_rows(matched_tests)$p), 3), "\n")
