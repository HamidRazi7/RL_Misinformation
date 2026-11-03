options(stringsAsFactors = FALSE)

rl_root <- "."
map_root <- "./Data/Processed"
pr_root <- "./Computational/Model 5rho (Winning)"
output_dir <- file.path(rl_root, "Data", "Processed", "Results")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

paired_result <- function(study, scores, comparison_model) {
  difference <- scores$M4 - scores[[comparison_model]]
  test <- t.test(difference, mu = 0)
  wilcoxon <- suppressWarnings(wilcox.test(difference, mu = 0, exact = FALSE))

  data.frame(
    Study = study,
    Comparison = paste("M4 vs", comparison_model),
    N = length(difference),
    Mean_M4 = mean(scores$M4),
    Mean_Comparison = mean(scores[[comparison_model]]),
    Mean_Difference_M4_Minus_Comparison = mean(difference),
    CI_Low = unname(test$conf.int[1]),
    CI_High = unname(test$conf.int[2]),
    T = unname(test$statistic),
    DF = unname(test$parameter),
    P = test$p.value,
    Cohen_dz = mean(difference) / sd(difference),
    Median_Difference = median(difference),
    M4_Lower_N = sum(scores$M4 < scores[[comparison_model]]),
    Comparison_Lower_N = sum(scores[[comparison_model]] < scores$M4),
    Tied_N = sum(scores[[comparison_model]] == scores$M4),
    Wilcoxon_P = wilcoxon$p.value,
    check.names = FALSE
  )
}

all_scores <- list()
all_summaries <- list()
all_tests <- list()

for (study in c(1, 2)) {
  five <- read.csv(file.path(map_root, sprintf("S%dModels_Vanilla.csv", study)), check.names = FALSE)
  stopifnot(identical(names(five), paste0("M", 1:5)))

  rho_path <- file.path(pr_root, sprintf("M4RhoLOOCVS%d.csv", study))
  rho_scores <- read.csv(rho_path)
  stopifnot(ncol(rho_scores) == 1L)
  stopifnot(nrow(five) == nrow(rho_scores))

  extended <- five
  extended$M6 <- rho_scores[[1]]
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

  tests_this_study <- do.call(rbind, c(
    list(paired_result(study, extended, "M6")),
    lapply(setdiff(names(extended), "M6"), function(m) {
      d <- extended$M6 - extended[[m]]
      tt <- t.test(d, mu = 0)
      w <- suppressWarnings(wilcox.test(d, mu = 0, exact = FALSE))
      data.frame(
        Study = study,
        Comparison = paste("M4Rho vs", m),
        N = length(d),
        Mean_M4 = mean(extended$M6),
        Mean_Comparison = mean(extended[[m]]),
        Mean_Difference_M4_Minus_Comparison = mean(d),
        CI_Low = unname(tt$conf.int[1]),
        CI_High = unname(tt$conf.int[2]),
        T = unname(tt$statistic),
        DF = unname(tt$parameter),
        P = tt$p.value,
        Cohen_dz = mean(d) / sd(d),
        Median_Difference = median(d),
        M4_Lower_N = sum(extended$M6 < extended[[m]]),
        Comparison_Lower_N = sum(extended[[m]] < extended$M6),
        Tied_N = sum(extended[[m]] == extended$M6),
        Wilcoxon_P = w$p.value,
        check.names = FALSE
      )
    })
  ))
  all_tests[[study]] <- tests_this_study

  write.csv(
    extended,
    file.path(output_dir, sprintf("six_model_rho_LOOCV_study%d.csv", study)),
    row.names = FALSE
  )
}

model_summary <- do.call(rbind, all_summaries)
paired_tests <- do.call(rbind, all_tests)
paired_tests$P_FDR <- p.adjust(paired_tests$P, method = "fdr")

write.csv(model_summary, file.path(output_dir, "six_model_rho_LOOCV_summary.csv"), row.names = FALSE)
write.csv(paired_tests, file.path(output_dir, "rho_model_paired_LOOCV_tests.csv"), row.names = FALSE)

cat("Participant-level LOOCV summary (lower is better):\n")
print(model_summary)
cat("\nPaired comparisons (M4Rho wins when the difference is negative):\n")
print(paired_tests[, c("Study", "Comparison", "T", "P", "P_FDR", "Cohen_dz")])
