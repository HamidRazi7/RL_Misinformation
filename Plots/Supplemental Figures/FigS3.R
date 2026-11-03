library(ggplot2)
library(cowplot)
library(dplyr)
library(tidyr)
library(grid)

rl_root <- "."
source(file.path(rl_root, "Plots", "model_renumbering.R"))
source(file.path(rl_root, "Plots", "save_publication_figure.R"))

input_path <- file.path(rl_root, "Data", "Processed", "Results",
                        "ten_model_random_effects_BMS.csv")
output_dir <- file.path(rl_root, "Plots", "Supplemental Figures")
submission_dir <- file.path(rl_root, "Plots", "Submission")

BASE_SIZE <- 17

bms <- read.csv(input_path, check.names = FALSE)

required_columns <- c(
  "Study", "Model", "EstimatedModelFrequency", "ModelFrequencySE",
  "ExceedanceProbability", "ProtectedExceedanceProbability"
)
stopifnot(all(required_columns %in% names(bms)))

model_order <- MODEL_ORDER_TEN
set_fills <- setNames(c(FIG_BAR_FILL_PRIMARY, FIG_BAR_FILL_SECONDARY),
                      MODEL_SET_LEVELS)

bms$Model <- renumber_factor(bms$Model, levels = model_order)
bms$Study <- factor(bms$Study, levels = c("Study 1", "Study 2"))
bms$Set <- model_set_group(bms$Model)
bms <- bms %>% arrange(Study, Model)

stopifnot(!any(is.na(bms$Model)), nrow(bms) == 20)

metric_labels <- c(
  ExceedanceProbability = "XP",
  EstimatedModelFrequency = "Model frequency"
)

number_models <- length(model_order)

plot_data <- bms %>%
  pivot_longer(
    cols = all_of(names(metric_labels)),
    names_to = "MetricCode",
    values_to = "Value"
  ) %>%
  mutate(
    Metric = factor(metric_labels[MetricCode], levels = unname(metric_labels))
  )

reference_lines <- expand.grid(
  Study = levels(bms$Study),
  Metric = levels(plot_data$Metric),
  stringsAsFactors = FALSE
) %>%
  mutate(
    Metric = factor(Metric, levels = levels(plot_data$Metric)),
    yintercept = ifelse(Metric == "Model frequency", 1 / number_models, .95),
    Reference = ifelse(Metric == "Model frequency",
                       "Chance frequency", ".95 reference")
  )

build_comparison_figure <- function(base_size) {
  ggplot(plot_data, aes(x = Model, y = Value, fill = Set)) +
    geom_col(width = .64, colour = "black", linewidth = base_size / 36) +
    geom_errorbar(
      data = filter(plot_data, MetricCode == "EstimatedModelFrequency"),
      aes(ymin = pmax(0, Value - ModelFrequencySE),
          ymax = pmin(1, Value + ModelFrequencySE)),
      width = .18, colour = "black", linewidth = base_size / 25
    ) +
    geom_hline(
      data = reference_lines,
      aes(yintercept = yintercept, linetype = Reference, colour = Reference),
      linewidth = base_size / 23, inherit.aes = FALSE
    ) +
    facet_grid(Metric ~ Study) +
    scale_fill_manual(values = set_fills, drop = FALSE, name = NULL) +
    scale_colour_manual(
      values = c("Chance frequency" = "firebrick", ".95 reference" = "red3"),
      guide = "none"
    ) +
    scale_linetype_manual(
      values = c("Chance frequency" = "dashed", ".95 reference" = "solid"),
      guide = "none"
    ) +
    scale_x_discrete(labels = model_axis_labels) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, .25),
                       expand = expansion(mult = c(0, .02))) +
    labs(x = "Model", y = NULL) +
    theme_cowplot(base_size) +
    theme(
      text = element_text(face = "plain"),
      strip.background = element_rect(fill = "grey90", colour = NA),
      strip.text = element_text(face = "plain"),
      panel.spacing = grid::unit(.8, "lines"),
      axis.text.x = element_text(face = "plain", angle = 45, hjust = 1,
                                 size = base_size * 0.7),
      legend.position = "top",
      legend.justification = "left",
      legend.key.size = grid::unit(base_size / 9, "lines")
    )
}

build_freq_figure <- function(base_size) {
  ggplot(bms, aes(x = Model, y = EstimatedModelFrequency, fill = Set)) +
    geom_col(width = .64, colour = "black", linewidth = base_size / 36) +
    geom_errorbar(
      aes(ymin = pmax(0, EstimatedModelFrequency - ModelFrequencySE),
          ymax = pmin(1, EstimatedModelFrequency + ModelFrequencySE)),
      width = .18, colour = "black", linewidth = base_size / 25
    ) +
    geom_hline(yintercept = 1 / number_models, linetype = "dashed",
               colour = "firebrick", linewidth = base_size / 23) +
    facet_wrap(~ Study, ncol = 2,
               labeller = as_labeller(c("Study 1" = "(a) Study 1", "Study 2" = "(b) Study 2"))) +
    scale_fill_manual(values = set_fills, drop = FALSE, name = NULL) +
    scale_x_discrete(labels = model_axis_labels) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, .25),
                       expand = expansion(mult = c(0, .02))) +
    labs(x = "Model", y = "Estimated model frequency") +
    theme_cowplot(base_size) +
    theme(
      text = element_text(face = "plain"),
      strip.background = element_rect(fill = "grey90", colour = NA),
      strip.text = element_text(face = "plain"),
      panel.spacing = grid::unit(1.2, "lines"),
      axis.text.x = element_text(face = "plain", angle = 45, hjust = 1,
                                 size = base_size * 0.7),
      legend.position = "top",
      legend.justification = "left",
      legend.key.size = grid::unit(base_size / 9, "lines")
    )
}

save_publication_figure(
  build_comparison_figure(BASE_SIZE), "SuppFig4_TenModel_Comparison",
  output_dir, submission_dir = submission_dir,
  width_cm = FIG_WIDTH_CM[["double"]], height_cm = 14
)

save_publication_figure(
  build_freq_figure(BASE_SIZE), "SuppFig4_TenModel_Frequencies",
  output_dir, submission_dir = submission_dir,
  width_cm = FIG_WIDTH_CM[["double"]], height_cm = 10
)

print(build_comparison_figure(BASE_SIZE))
