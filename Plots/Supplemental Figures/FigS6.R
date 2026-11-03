suppressMessages({ library(dplyr); library(ggplot2); library(cowplot) })

rl_dir  <- "."
fig_dir <- file.path(rl_dir, "Plots", "Figures")
source(file.path(rl_dir, "Plots", "save_publication_figure.R"))

FONT <- 11
BIN  <- 5

CTX_COLS   <- c(Gain = "#3A75AE", Loss = "#F26241")
CTX_SHAPES <- c(Gain = 21, Loss = 24)
CTX_LABELS <- c(Gain = "Gain pairs", Loss = "Loss pairs")

sem <- function(x) sd(x) / sqrt(length(x))

curves <- function(study)
  read.csv(file.path(rl_dir, "Data", "Processed", sprintf("Study%d.csv", study))) |>
    arrange(subn, Trial) |>
    group_by(subn, Condition) |> mutate(pos = row_number() - 1) |> ungroup() |>
    mutate(split   = ifelse(Condition %in% c(1, 3), "Solvable", "Unsolvable"),
           context = factor(ifelse(Condition.Type == "gain", "Gain", "Loss"),
                            levels = names(CTX_COLS)),
           trial   = (pos %/% BIN) * BIN + (BIN + 1) / 2) |>
    group_by(subn, split, context, trial) |>
    summarise(p = mean(Choice == 1), .groups = "drop") |>
    group_by(split, context, trial) |>
    summarise(m = mean(p), lo = m - sem(p), hi = m + sem(p), .groups = "drop")

lc_panel <- function(df, title, base_font) {
  k <- base_font / 13
  dodge <- position_dodge(width = 1.4)
  ggplot(df, aes(trial, m, colour = context, fill = context, shape = context)) +
    geom_hline(yintercept = .5, linetype = "dashed", colour = "grey45", linewidth = .6 * k) +
    geom_line(linewidth = .8 * k, position = dodge) +
    geom_errorbar(aes(ymin = lo, ymax = hi), width = 1.2, linewidth = .6 * k, position = dodge) +
    geom_point(size = 2.2 * k, colour = "black", stroke = .4 * k, position = dodge) +
    scale_colour_manual(values = CTX_COLS, labels = CTX_LABELS) +
    scale_fill_manual(values = CTX_COLS, labels = CTX_LABELS) +
    scale_shape_manual(values = CTX_SHAPES, labels = CTX_LABELS) +
    scale_x_continuous(breaks = seq(10, 40, 10), limits = c(0, 41)) +
    scale_y_continuous(breaks = seq(.25, 1, .25), labels = function(x) x * 100,
                       limits = c(.25, 1), expand = c(0, 0)) +
    labs(x = "Trial", y = "Choice Rate Option 1 (%)", title = title,
         colour = NULL, fill = NULL, shape = NULL) +
    theme_cowplot(base_font) +
    theme(axis.text  = element_text(size = base_font * .92, colour = "black"),
          axis.title = element_text(size = base_font),
          axis.line  = element_line(linewidth = .5 * k, colour = "black"),
          axis.ticks = element_line(linewidth = .5 * k, colour = "black"),
          plot.title = element_text(size = base_font, face = "bold", hjust = .5),
          legend.position = "none",
          plot.margin = margin(4 * k, 8 * k, 4 * k, 4 * k))
}

study_row <- function(df, base_font)
  plot_grid(NULL, lc_panel(filter(df, split == "Solvable"), "Solvable", base_font),
            lc_panel(filter(df, split == "Unsolvable"), "Unsolvable", base_font),
            ncol = 3, rel_widths = c(.06, 1, 1))

build_s7 <- function(base_font) {
  lcs <- lapply(1:2, curves)
  legend <- get_plot_component(
    lc_panel(lcs[[1]], NULL, base_font) +
      theme(legend.position = "top", legend.justification = "center",
            legend.text = element_text(size = base_font * .92),
            legend.key.width = unit(2 * base_font / 13, "lines")),
    "guide-box-top", return_all = TRUE)
  plot_grid(legend,
            plot_grid(study_row(lcs[[1]], base_font), study_row(lcs[[2]], base_font),
                      ncol = 1, labels = c("(a)", "(b)"), label_size = base_font * 1.2),
            ncol = 1, rel_heights = c(.06, 1))
}

save_publication_figure(build_s7(FONT), "FigS6_LearningCurves", fig_dir,
                        width_cm = FIG_WIDTH_CM[["onehalf"]], height_cm = 14)
ggsave(file.path(fig_dir, "FigS6_LearningCurves_large.png"), build_s7(25),
       width = 13, height = 15, dpi = 300, bg = "white")
message("wrote FigS6_LearningCurves")
