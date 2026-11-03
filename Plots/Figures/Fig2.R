rl_dir  <- "."
fig_dir <- file.path(rl_dir, "Plots", "Figures")
source(file.path(fig_dir, "choice_rate_panel.R"))
source(file.path(rl_dir, "Plots", "save_publication_figure.R"))

per_subject <- function(study)
  read.csv(file.path(rl_dir, "Data", "Processed", sprintf("Study%d.csv", study))) |>
    mutate(split = ifelse(Condition %in% c(1, 3), "Solvable", "Unsolvable")) |>
    group_by(subn, split) |>
    summarise(p = mean(C1, na.rm = TRUE), .groups = "drop")

obs <- lapply(1:2, per_subject)

for (s in 1:2) {
  cat(sprintf("\nStudy %d\n", s))
  print(as.data.frame(choice_rate_stats(obs[[s]])), digits = 3)
}

build_fig2 <- function(base_font)
  plot_grid(plotlist = lapply(obs, choice_rate_panel, base_font = base_font),
            ncol = 2, labels = c("(a)", "(b)"), label_size = base_font * 1.2)

FONT <- 11

save_publication_figure(
  build_fig2(FONT), "Fig2_ChoiceRates", fig_dir,
  width_cm = FIG_WIDTH_CM[["onehalf"]], height_cm = 7.5,
  submission_dir = file.path(rl_dir, "Plots", "Submission"))

ggsave(file.path(fig_dir, "Fig2_ChoiceRates_large.png"), build_fig2(25),
       width = 13, height = 7.5, dpi = 300, bg = "white")
message("wrote Fig2_ChoiceRates")

both_studies <- bind_rows(obs[[1]] |> mutate(group = "Study 1"),
                          obs[[2]] |> mutate(group = "Study 2")) |>
  mutate(group = factor(group, levels = c("Study 1", "Study 2")))
save_publication_figure(choice_rate_grouped(both_studies, base_font = FONT),
                        "Fig2_ChoiceRates_merged", fig_dir,
                        width_cm = FIG_WIDTH_CM[["onehalf"]], height_cm = 8,
                        formats = c("pdf", "png"))
