library(ggplot2)
library(cowplot)
library(dplyr)
library(tidyverse)

rl_root <- "."
fig_dir <- file.path(rl_root, "Plots", "Figures")
source(file.path(rl_root, "Plots", "save_publication_figure.R"))

Points_S1 <- read.csv(file.path(fig_dir, "M6NoreparamPointsS1.csv"))
Points_S2 <- read.csv(file.path(fig_dir, "M6NoreparamPointsS2.csv"))

build_long <- function(study) {
  Stats <- read.csv(file.path(fig_dir, sprintf("M6NoreparamStatsS%d.csv", study)))
  v <- c("Conf_True", "Conf_False", "Disconf_True", "Disconf_False")
  tibble(variable = v,
         mean = unlist(Stats[paste0(v, "_point")]),
         lo   = unlist(Stats[paste0(v, "_sem_lower")]),
         hi   = unlist(Stats[paste0(v, "_sem_upper")])) %>%
    mutate(Condition = factor(ifelse(grepl("True", variable), "True", "False"),
                              levels = c("True", "False")),
           Type = factor(ifelse(grepl("Conf", variable), "Confirmatory", "Disconfirmatory"),
                         levels = c("Confirmatory", "Disconfirmatory")))
}

build_points <- function(Points) {
  Points %>%
    pivot_longer(cols = c(Conf_True, Conf_False, Disconf_True, Disconf_False),
                 names_to = "variable", values_to = "value") %>%
    mutate(Condition = ifelse(grepl("True", variable), "True", "False"),
           Type      = ifelse(grepl("Conf", variable), "Confirmatory", "Disconfirmatory"))
}

make_lr_plot <- function(long_data, points_df, study_label, base_size, stars) {
  k <- base_size / 20
  top <- points_df %>% group_by(Condition) %>% summarise(y = max(value) + 0.03)
  br  <- tibble(Condition = c("True", "False"), x = c(1, 2),
                label = unname(stars[c("True", "False")])) %>%
    left_join(top, by = "Condition")
  ggplot(long_data, aes(x = Condition, y = mean, fill = Type)) +
    geom_bar(stat = "identity", position = position_dodge(), linewidth = 0.8 * k) +
    geom_point(data = points_df, aes(x = Condition, y = value, group = Type),
               position = position_jitterdodge(jitter.width = 0.25),
               shape = 21, size = 2.6 * k, fill = "grey50", colour = "black",
               stroke = 0.5 * k, alpha = 0.5) +
    geom_errorbar(aes(ymin = lo, ymax = hi, group = Type),
                  width = .3, position = position_dodge(.9), linewidth = 1 * k) +
    geom_segment(data = br, aes(x = x - .225, xend = x + .225, y = y, yend = y),
                 inherit.aes = FALSE, linewidth = 0.6 * k) +
    geom_text(data = br, aes(x = x, y = y, label = label), inherit.aes = FALSE,
              vjust = .2, size = base_size * .45) +
    scale_fill_manual(values = c("Confirmatory" = "blue", "Disconfirmatory" = "red")) +
    scale_x_discrete(labels = c(True = "Verified", False = "Debunked")) +
    scale_y_continuous(breaks = seq(0, 0.8, by = 0.1), expand = expansion(mult = 0)) +
    coord_cartesian(ylim = c(0, 0.9), clip = "off") +
    guides(y = guide_axis(cap = "upper")) +
    theme_cowplot(base_size) +
    labs(title = study_label, x = "Verification Cue", y = "Learning Rate",
         fill = "Feedback Type")
}

FONT  <- 11
STARS <- list(S1 = c(True = "**", False = "**"),
              S2 = c(True = "***", False = "***"))
set.seed(4)
fig_print <- plot_grid(
  make_lr_plot(build_long(1), build_points(Points_S1), "Study 1", FONT, STARS$S1),
  make_lr_plot(build_long(2), build_points(Points_S2), "Study 2", FONT, STARS$S2),
  ncol = 2, labels = c("(a)", "(b)"), label_size = FONT * 1.2)
save_publication_figure(fig_print, "Fig4_LearningRates_nonreparam", fig_dir,
                        width_cm = FIG_WIDTH_CM[["double"]], height_cm = 8.5,
                        submission_dir = file.path(rl_root, "Plots", "Submission"))
