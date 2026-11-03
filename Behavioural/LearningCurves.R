suppressMessages({ library(dplyr); library(tidyr); library(lme4) })

out_dir <- file.path("Data", "Processed", "Results")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

fx_rows <- list(); chance_rows <- list(); bin_rows <- list()
for (st in 1:2) {
  d <- read.csv(file.path("Data", "Processed", sprintf("Study%d.csv", st))) |>
    arrange(subn, Trial) |> group_by(subn, Condition) |>
    mutate(pos = row_number() - 1) |> ungroup() |>
    mutate(split = ifelse(Condition %in% c(1, 3), "Solvable", "Unsolvable"),
           context = factor(ifelse(Condition.Type == "gain", "Gain", "Loss"), levels = c("Loss", "Gain")),
           O1 = as.integer(Choice == 1), trial10 = (pos - 19.5) / 10)
  for (sp in c("Solvable", "Unsolvable")) {
    ds <- filter(d, split == sp)
    m <- glmer(O1 ~ context * trial10 + (1 + trial10 | subn), data = ds, family = binomial,
               control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5)))
    cf <- summary(m)$coefficients
    fx_rows[[length(fx_rows) + 1]] <- data.frame(study = st, split = sp, term = rownames(cf),
      estimate = cf[, 1], se = cf[, 2], z = cf[, 3], p = cf[, 4],
      singular = isSingular(m), row.names = NULL)
    bt <- ds |> mutate(bin = pos %/% 5 + 1) |> group_by(subn, context, bin) |>
      summarise(p = mean(O1), .groups = "drop") |>
      pivot_wider(names_from = context, values_from = p) |>
      group_by(bin) |>
      summarise(gain = mean(Gain), loss = mean(Loss),
                t = t.test(Gain, Loss, paired = TRUE)$statistic,
                p = t.test(Gain, Loss, paired = TRUE)$p.value, .groups = "drop") |>
      mutate(p_fdr = p.adjust(p, "fdr"), study = st, split = sp)
    bin_rows[[length(bin_rows) + 1]] <- bt
    s <- ds |> group_by(subn, context) |> summarise(p = mean(O1), .groups = "drop")
    for (cx in c("Gain", "Loss")) {
      x <- s$p[s$context == cx]; tt <- t.test(x, mu = .5)
      chance_rows[[length(chance_rows) + 1]] <- data.frame(study = st, split = sp, context = cx,
        mean = mean(x), sem = sd(x) / sqrt(length(x)), t = unname(tt$statistic),
        df = unname(tt$parameter), p = tt$p.value)
    }
  }
}
fx <- bind_rows(fx_rows); chance <- bind_rows(chance_rows); bins <- bind_rows(bin_rows)
write.csv(fx, file.path(out_dir, "learning_curve_glmer.csv"), row.names = FALSE)
write.csv(chance, file.path(out_dir, "choice_vs_chance.csv"), row.names = FALSE)
write.csv(bins, file.path(out_dir, "binwise_gain_vs_loss.csv"), row.names = FALSE)

cat("Mixed model (context coded Gain vs Loss, trial in units of 10 trials, centred mid-block):\n")
for (i in seq_len(nrow(fx))) with(fx[i, ], cat(sprintf("  S%d %-10s %-22s b=%6.3f se=%.3f z=%6.2f p=%.4f%s\n",
  study, split, term, estimate, se, z, p, ifelse(singular, " [singular]", ""))))
cat("Choice of O1 vs 0.5:\n")
for (i in seq_len(nrow(chance))) with(chance[i, ], cat(sprintf("  S%d %-10s %-4s M=%.3f SEM=%.3f t(%d)=%5.2f p=%.4f\n",
  study, split, context, mean, sem, df, t, p)))
cat("Bin-wise gain vs loss, bins with p_fdr < .05:\n")
sig <- filter(bins, p_fdr < .05)
if (nrow(sig) == 0) cat("  none\n") else for (i in seq_len(nrow(sig))) with(sig[i, ],
  cat(sprintf("  S%d %-10s bin %d (trials %d-%d): gain %.3f loss %.3f t=%.2f p_fdr=%.4f\n",
              study, split, bin, 5 * bin - 4, 5 * bin, gain, loss, t, p_fdr)))
