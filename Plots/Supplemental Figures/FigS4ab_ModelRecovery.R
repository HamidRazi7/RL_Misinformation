library(ggplot2)
library(cowplot)
library(dplyr)
library(tidyr)

rl_root <- "."
source(file.path(rl_root, "Plots", "model_renumbering.R"))
source(file.path(rl_root, "Plots", "save_publication_figure.R"))

output_dir <- file.path(rl_root, "Plots", "Supplemental Figures")
submission_dir <- file.path(rl_root, "Plots", "Submission")

BASE_SIZE <- 17

tag      <- "N100_50iter"
win_file <- file.path(rl_root, "Computational",
                      "Model Recovery",
                      sprintf("recovery_winners_%s_study1.csv", tag))

dat <- read.csv(win_file, stringsAsFactors = FALSE)

lv <- MODEL_ORDER_SIX
dat$TrueModel <- renumber_factor(dat$TrueModel, levels = lv)
dat$XPWinner  <- renumber_factor(dat$XPWinner,  levels = lv)
stopifnot(!any(is.na(dat$TrueModel)), !any(is.na(dat$XPWinner)))

long <- dat %>%
  count(TrueModel, XPWinner) %>%
  complete(TrueModel, XPWinner, fill = list(n = 0L)) %>%
  group_by(TrueModel) %>%
  mutate(prop   = n / sum(n),
         isdiag = as.character(TrueModel) == as.character(XPWinner),
         lab    = sprintf("%.0f%%", 100 * prop)) %>%
  ungroup()

build_plot <- function(base_size, high = "grey15") {
  ggplot(long, aes(x = XPWinner, y = TrueModel, fill = prop)) +
    geom_tile(colour = "white", linewidth = base_size / 50) +
    geom_text(aes(label = lab, colour = isdiag),
              size = base_size / .pt * 0.85, show.legend = FALSE) +
    scale_colour_manual(values = c("TRUE" = "white", "FALSE" = "black")) +
    scale_fill_gradient(low = "white", high = high, limits = c(0, 1)) +
    coord_equal() +
    scale_x_discrete(labels = model_axis_labels) +
    scale_y_discrete(labels = model_axis_labels) +
    labs(x = "Recovered Model", y = "Simulated Model", fill = "Proportion") +
    theme_cowplot(base_size) +
    theme(text = element_text(face = "plain"),
          plot.title = element_text(face = "plain"),
          panel.grid = element_blank(),
          legend.key.height = unit(base_size / 22, "cm"))
}

save_publication_figure(
  build_plot(BASE_SIZE), "SuppFig6a_ModelRecovery", output_dir,
  submission_dir = submission_dir,
  width_cm = FIG_WIDTH_CM[["double"]], height_cm = 15
)

ggsave(file.path(output_dir, "SuppFig6a_ModelRecovery_poster.png"),
       build_plot(40, high = "red") + labs(title = "Model Recovery"),
       width = 8, height = 7, units = "in",
       dpi = 300, type = "cairo", bg = "white")

ggsave(file.path(output_dir, "SuppFig6a_ModelRecovery_composite.png"),
       build_plot(15, high = "red") + labs(title = "Model Recovery") +
         theme(plot.title = element_text(face = "bold", hjust = 0.5)),
       width = 6.4, height = 4, units = "in", dpi = 300, type = "cairo", bg = "white")

print(build_plot(BASE_SIZE))

rates <- long %>%
  filter(isdiag) %>%
  transmute(Model = TrueModel, Successes = n,
            RecoveryRate = sprintf("%.0f%%", 100 * prop)) %>%
  arrange(Model)
cat("\nDiagonal (recovery rate):\n")
print(as.data.frame(rates))

confusions <- long %>%
  filter(!isdiag, n > 0) %>%
  transmute(From = TrueModel, To = XPWinner, n,
            Percent = sprintf("%.0f%%", 100 * prop)) %>%
  arrange(From, To)
cat("\nOff-diagonal (confusions):\n")
print(as.data.frame(confusions))
