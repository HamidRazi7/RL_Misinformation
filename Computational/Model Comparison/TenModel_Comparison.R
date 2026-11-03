options(stringsAsFactors = FALSE)

rl_root <- "."
map_root <- "./Data/Processed"
pr_root <- "./Computational/Models 1rho-4rho"
output_dir <- file.path(rl_root, "Data", "Processed", "Results")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

model_order <- c("M1", "M2", "M3", "M4", "M5", "M6", "M1Rho", "M2Rho", "M3Rho", "M5Rho")
winner <- "M6"

paired_result <- function(study, scores, model_a, model_b) {
  difference <- scores[[model_a]] - scores[[model_b]]
  test <- t.test(difference, mu = 0)
  wilcoxon <- suppressWarnings(wilcox.test(difference, mu = 0, exact = FALSE))

  data.frame(
    Study = study,
    Comparison = paste(model_a, "vs", model_b),
    N = length(difference),
    Mean_A = mean(scores[[model_a]]),
    Mean_B = mean(scores[[model_b]]),
    Mean_Difference_A_Minus_B = mean(difference),
    CI_Low = unname(test$conf.int[1]),
    CI_High = unname(test$conf.int[2]),
    T = unname(test$statistic),
    DF = unname(test$parameter),
    P = test$p.value,
    Cohen_dz = mean(difference) / sd(difference),
    Median_Difference = median(difference),
    A_Lower_N = sum(scores[[model_a]] < scores[[model_b]]),
    B_Lower_N = sum(scores[[model_b]] < scores[[model_a]]),
    Tied_N = sum(scores[[model_a]] == scores[[model_b]]),
    Wilcoxon_P = wilcoxon$p.value,
    check.names = FALSE
  )
}

all_scores <- list()
all_summaries <- list()
all_winner_tests <- list()
all_pairwise_tests <- list()

for (study in c(1, 2)) {
  five <- read.csv(file.path(map_root, sprintf("S%dModels_Vanilla.csv", study)), check.names = FALSE)
  stopifnot(identical(names(five), paste0("M", 1:5)))

  read_rho <- function(model) {
    scores <- read.csv(file.path(if (model == "M4Rho") "./Computational/Model 5rho (Winning)" else pr_root,
                                 sprintf("%sLOOCVS%d.csv", model, study)))
    stopifnot(ncol(scores) == 1L)
    stopifnot(nrow(five) == nrow(scores))
    scores[[1]]
  }

  extended <- five
  extended$M6 <- read_rho("M4Rho")
  extended$M1Rho <- read_rho("M1Rho")
  extended$M2Rho <- read_rho("M2Rho")
  extended$M3Rho <- read_rho("M3Rho")
  extended$M5Rho <- read_rho("M5Rho")
  extended <- extended[, model_order]
  all_scores[[study]] <- extended

  summary_rows <- lapply(names(extended), function(model) {
    values <- extended[[model]]
    data.frame(
      Study = study,
      Model = model,
      N = length(values),
      Mean_LOOCV = mean(values),
      SD_LOOCV = sd(values),
      SE_LOOCV = sd(values) / sqrt(length(values)),
      Total_LOOCV = sum(values),
      check.names = FALSE
    )
  })
  all_summaries[[study]] <- do.call(rbind, summary_rows)

  others <- setdiff(model_order, winner)
  all_winner_tests[[study]] <- do.call(rbind, lapply(others, function(m) {
    paired_result(study, extended, winner, m)
  }))

  pairs <- combn(model_order, 2, simplify = FALSE)
  all_pairwise_tests[[study]] <- do.call(rbind, lapply(pairs, function(p) {
    paired_result(study, extended, p[1], p[2])
  }))

  write.csv(
    extended,
    file.path(output_dir, sprintf("ten_model_LOOCV_study%d.csv", study)),
    row.names = FALSE
  )
}

model_summary <- do.call(rbind, all_summaries)
winner_tests <- do.call(rbind, all_winner_tests)
pairwise_tests <- do.call(rbind, all_pairwise_tests)
winner_tests$P_FDR <- p.adjust(winner_tests$P, method = "fdr")
pairwise_tests$P_FDR <- p.adjust(pairwise_tests$P, method = "fdr")

write.csv(model_summary, file.path(output_dir, "ten_model_LOOCV_summary.csv"), row.names = FALSE)
write.csv(winner_tests, file.path(output_dir, "ten_model_paired_LOOCV_tests.csv"), row.names = FALSE)
write.csv(pairwise_tests, file.path(output_dir, "ten_model_all_pairwise_LOOCV_tests.csv"), row.names = FALSE)

cat("Ten-model LOOCV summary (lower is better):\n")
print(model_summary)
cat("\nWinner-vs-rest paired t-tests (negative difference favors M6):\n")
print(winner_tests[, c("Study", "Comparison", "Mean_Difference_A_Minus_B", "T", "P", "P_FDR", "Cohen_dz")])
cat("\nAll pairwise (top 15 by |Cohen_dz|):\n")
print(pairwise_tests[order(-abs(pairwise_tests$Cohen_dz)), ][1:15, c("Study", "Comparison", "Mean_Difference_A_Minus_B", "T", "P", "P_FDR", "Cohen_dz")])
