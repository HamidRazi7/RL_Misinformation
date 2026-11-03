library(ggplot2)
library(cowplot)
library(dplyr)
library(tidyr)

data_dir <- "./Data/Processed/Results"
out_dir  <- "./Plots/Supplemental Figures"

LR_VARS <- c("Conf_True", "Disconf_True", "Conf_False", "Disconf_False")

cells <- list(
  list(key = "S1_gain", title = "Study 1 - Gain", note = "",
       p_true = 0.001585, p_false = 0.000865,
       stats = "M6SuppM2fix2StatsS1_gain_rs_fix2_M6b.csv",  points = "M6SuppM2fix2PointsS1_gain_rs_fix2_M6b.csv"),
  list(key = "S1_loss", title = "Study 1 - Loss", note = "",
       p_true = 0.004817, p_false = 0.004927,
       stats = "M6SuppM2fix2StatsS1_loss_rs_fix2_M6b.csv",  points = "M6SuppM2fix2PointsS1_loss_rs_fix2_M6b.csv"),
  list(key = "S2_gain", title = "Study 2 - Gain", note = "",
       p_true = 0.000032, p_false = 0.000309,
       stats = "M6SuppM2fix2StatsS2_gain_rs_fix2_M6b.csv",  points = "M6SuppM2fix2PointsS2_gain_rs_fix2_M6b.csv"),
  list(key = "S2_loss", title = "Study 2 - Loss", note = "",
       p_true = 0.026111, p_false = 0.000001,
       stats = "M6SuppM2fix2StatsS2_loss_rs_fix2_M6b.csv",  points = "M6SuppM2fix2PointsS2_loss_rs_fix2_M6b.csv")
)

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.001) return("***")
  if (p < 0.01)  return("**")
  if (p < 0.05)  return("*")
  "n.s."
}

read_cell <- function(cell) {
  fs <- file.path(data_dir, cell$stats)
  fp <- file.path(data_dir, cell$points)
  if (!file.exists(fs) || !file.exists(fp)) {
    warning(sprintf("missing files for %s - skipping", cell$key)); return(NULL)
  }
  list(Stats = read.csv(fs), Points = read.csv(fp), meta = cell)
}

suppm2_panel <- function(cell, ymax = 1.0) {
  Stats  <- cell$Stats
  Points <- cell$Points

  pick <- function(v, suffix) {
    nm <- paste0(v, suffix)
    if (nm %in% names(Stats)) Stats[[nm]][1] else NA_real_
  }

  bar_data <- data.frame(
    variable  = LR_VARS,
    mean      = sapply(LR_VARS, pick, "_submean"),
    sem_lower = sapply(LR_VARS, pick, "_subsem_lower"),
    sem_upper = sapply(LR_VARS, pick, "_subsem_upper"),
    stringsAsFactors = FALSE
  ) %>%
    mutate(
      Condition = factor(ifelse(grepl("True", variable), "True", "False"),
                         levels = c("True", "False")),
      Type = factor(ifelse(grepl("^Conf", variable), "Confirmatory", "Disconfirmatory"),
                    levels = c("Confirmatory", "Disconfirmatory"))
    )

  point_data <- Points %>%
    pivot_longer(cols = all_of(LR_VARS), names_to = "variable", values_to = "value") %>%
    mutate(
      Condition = factor(ifelse(grepl("True", variable), "True", "False"),
                         levels = c("True", "False")),
      Type = factor(ifelse(grepl("^Conf", variable), "Confirmatory", "Disconfirmatory"),
                    levels = c("Confirmatory", "Disconfirmatory"))
    )

  dodge <- position_dodge(0.9)

  pair_max <- point_data %>%
    group_by(Condition) %>% summarise(m = max(value), .groups = "drop")
  sig <- data.frame(
    Condition = factor(c("True", "False"), levels = c("True", "False")),
    p = c(cell$meta$p_true, cell$meta$p_false),
    stringsAsFactors = FALSE
  )
  sig <- merge(sig, pair_max, by = "Condition")
  sig$xc   <- as.numeric(sig$Condition)
  sig$xmin <- sig$xc - 0.225
  sig$xmax <- sig$xc + 0.225
  sig$y    <- pmin(sig$m + 0.05, ymax - 0.06)
  sig$lab  <- vapply(sig$p, stars, character(1))
  tick <- 0.018

  ggplot(bar_data, aes(x = Condition, y = mean, fill = Type)) +
    geom_bar(stat = "identity", position = dodge) +
    geom_point(data = point_data, aes(x = Condition, y = value, group = Type),
               position = position_jitterdodge(jitter.width = 0.25, dodge.width = 0.9),
               shape = 21, size = 2.6, fill = "grey50", colour = "black", stroke = 0.6, alpha = 0.5) +
    geom_errorbar(aes(ymin = sem_lower, ymax = sem_upper, group = Type),
                  width = .3, position = dodge, linewidth = 1.5) +
    geom_segment(data = sig, aes(x = xmin, xend = xmax, y = y, yend = y),
                 inherit.aes = FALSE, linewidth = 1.1, lineend = "square") +
    geom_segment(data = sig, aes(x = xmin, xend = xmin, y = y, yend = y - tick),
                 inherit.aes = FALSE, linewidth = 1.1) +
    geom_segment(data = sig, aes(x = xmax, xend = xmax, y = y, yend = y - tick),
                 inherit.aes = FALSE, linewidth = 1.1) +
    geom_text(data = sig, aes(x = xc, y = y + 0.008, label = lab),
              inherit.aes = FALSE, size = 9, vjust = 0, fontface = "bold") +
    scale_fill_manual(values = c("Confirmatory" = "blue", "Disconfirmatory" = "red")) +
    scale_x_discrete(labels = c(True = "Verified", False = "Debunked")) +
    scale_y_continuous(limits = c(0, ymax), breaks = seq(0, ymax, by = 0.1)) +
    cowplot::theme_cowplot(25) +
    theme(plot.background = element_rect(fill = "white", colour = NA),
          panel.background = element_rect(fill = "white", colour = NA),
          plot.title = element_text(hjust = 0.5, face = "bold", size = 24),
          plot.subtitle = element_text(hjust = 0.5, size = 13, colour = "grey30")) +
    labs(title = cell$meta$title, subtitle = cell$meta$note,
         x = "Verification Cue", y = "Learning Rate", fill = "")
}

loaded <- Filter(Negate(is.null), lapply(cells, read_cell))
if (length(loaded) == 0) stop("no cells could be loaded")

YMAX <- 1.0
panels <- lapply(loaded, suppm2_panel, ymax = YMAX)
names(panels) <- sapply(loaded, function(z) z$meta$key)

for (k in names(panels)) {
  ggplot2::ggsave(file.path(out_dir, sprintf("SuppM2_LearningRates_%s.png", k)),
         panels[[k]], width = 7.5, height = 7, dpi = 300, bg = "white")
  ggplot2::ggsave(file.path(out_dir, sprintf("SuppM2_LearningRates_%s.pdf", k)),
         panels[[k]], width = 7.5, height = 7, bg = "white")
}

grid <- cowplot::plot_grid(plotlist = panels, ncol = 2,
                           labels = c("(a)", "(b)", "(c)", "(d)"), label_size = 24) +
        theme(plot.background = element_rect(fill = "white", colour = NA))

cap <- paste(
  "Bars = mean of per-subject estimates +/- between-subject SEM. Dots = individual participants.",
  "Brackets show hierarchical tests of Confirmatory vs Disconfirmatory learning within each",
  "information-accuracy condition (*** p < .001, ** p < .01, * p < .05).",
  "All four panels use one specification: four learning rates as random effects, with Beta and rho",
  "fixed at the group values from the main-text M6 fit (Study 1 Beta = 4.26, rho = 0.573;",
  "Study 2 Beta = 2.44, rho = 0.469; Beta rescaled x10 because rewards are divided by 10).",
  sep = "\n")

grid_cap <- cowplot::plot_grid(grid,
                      cowplot::ggdraw() + cowplot::draw_label(cap, size = 12, hjust = 0.5, lineheight = 1.2) +
                        theme(plot.background = element_rect(fill = "white", colour = NA)),
                      ncol = 1, rel_heights = c(1, 0.20))

ggplot2::ggsave(file.path(out_dir, "SuppM2_LearningRates_grid.png"), grid,
       width = 15, height = 13.5, dpi = 300, bg = "white")

ggplot2::ggsave(file.path(out_dir, "SuppM2_LearningRates_all.png"), grid_cap,
       width = 15, height = 16.5, dpi = 300, bg = "white")
ggplot2::ggsave(file.path(out_dir, "SuppM2_LearningRates_all.pdf"), grid_cap,
       width = 15, height = 16.5, bg = "white")

cat("Saved:\n")
cat("  SuppM2_LearningRates_all.png/pdf   (2x2 grid, all four cells)\n")
for (k in names(panels)) cat(sprintf("  SuppM2_LearningRates_%s.png/pdf\n", k))
