library(ggplot2)
library(cowplot)
library(dplyr)

rl_root <- "."
source(file.path(rl_root, "Plots", "model_renumbering.R"))
source(file.path(rl_root, "Plots", "save_publication_figure.R"))

output_dir <- file.path(rl_root, "Plots", "Figures")
submission_dir <- file.path(rl_root, "Plots", "Submission")

BASE_SIZE <- 17

bms <- read.csv(file.path(rl_root, "Data", "Processed", "Results",
                          "six_model_rho_random_effects_BMS.csv"),
                check.names = FALSE)

six <- bms %>%
  mutate(
    Study = factor(Study, levels = c("Study 1", "Study 2")),
    Model = renumber_factor(Model, levels = MODEL_ORDER_SIX)
  ) %>%
  arrange(Study, Model)

stopifnot(!any(is.na(six$Model)), nrow(six) == 12)

common_theme <- function(base_size) {
  theme_cowplot(base_size) +
    theme(
      text = element_text(face = "plain"),
      plot.title = element_text(face = "plain"),
      axis.title = element_text(face = "plain"),
      axis.text = element_text(face = "plain"),
      strip.background = element_rect(fill = "grey90", colour = NA),
      strip.text = element_text(face = "plain"),
      panel.spacing = grid::unit(0.8, "lines")
    )
}

build_freq_plot <- function(base_size) {
  ggplot(six, aes(x = Model, y = EstimatedModelFrequency)) +
    geom_bar(stat = "identity", width = 0.6, fill = FIG_BAR_FILL,
             colour = "black", linewidth = base_size / 45) +
    geom_errorbar(
      aes(ymin = pmax(0, EstimatedModelFrequency - ModelFrequencySE),
          ymax = pmin(1, EstimatedModelFrequency + ModelFrequencySE)),
      width = 0.2, colour = "black", linewidth = base_size / 30
    ) +
    geom_hline(yintercept = 1 / 6, colour = "firebrick", linetype = "dashed",
               linewidth = base_size / 36) +
    facet_grid(. ~ Study) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25),
                       expand = expansion(mult = c(0, 0.02))) +
    scale_x_discrete(labels = model_axis_labels) +
    labs(x = "Model", y = "Estimated model frequency") +
    common_theme(base_size)
}

build_xp_plot <- function(base_size) {
  ggplot(six, aes(x = Model, y = ExceedanceProbability)) +
    geom_col(width = 0.6, fill = FIG_BAR_FILL, colour = "black",
             linewidth = base_size / 45) +
    geom_hline(yintercept = 0.95, colour = "red", linewidth = base_size / 36) +
    facet_grid(. ~ Study) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25),
                       expand = expansion(mult = c(0, 0.02))) +
    scale_x_discrete(labels = model_axis_labels) +
    labs(x = "Model", y = "XP") +
    common_theme(base_size)
}

save_publication_figure(
  build_freq_plot(BASE_SIZE), "Fig3_ModelFrequencies", output_dir,
  submission_dir = submission_dir,
  width_cm = FIG_WIDTH_CM[["double"]], height_cm = 8
)

save_publication_figure(
  build_xp_plot(BASE_SIZE), "Fig3_ExceedanceProbabilities", output_dir,
  submission_dir = submission_dir,
  width_cm = FIG_WIDTH_CM[["double"]], height_cm = 8
)

ggsave(file.path(output_dir, "Fig3_ModelFrequencies_large.png"),
       build_freq_plot(40),
       width = 16, height = 8, units = "in", dpi = 300, bg = "white")
ggsave(file.path(output_dir, "Fig3_ExceedanceProbabilities_large.png"),
       build_xp_plot(40),
       width = 16, height = 8, units = "in", dpi = 300, bg = "white")

print(build_freq_plot(BASE_SIZE))
