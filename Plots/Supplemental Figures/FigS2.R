library(ggplot2)
library(cowplot)
library(dplyr)
library(tidyverse)
library(reshape2)

rl_root <- "."
data_dir <- file.path(rl_root, "Data", "Processed")
source(file.path(rl_root, "Plots", "save_publication_figure.R"))

src <- parse(file.path(rl_root, "Plots", "Figures", "Fig4.R"))
for (e in src) {
  if (is.call(e) && identical(e[[1]], as.name("<-")) &&
      as.character(e[[2]]) %in% c("build_points", "make_lr_plot", "FONT")) eval(e)
}

ns <- c(47, 57)
stars <- function(p) if (p < 0.001) "***" else if (p < 0.01) "**" else if (p < 0.05) "*" else "n.s."
sigmoid <- function(v) 1 / (1 + exp(-v))

lr_panel <- function(study) {
  b <- read.csv(file.path(data_dir, sprintf("Supp3S%dBetas.csv", study)))$b
  S <- unname(as.matrix(read.csv(file.path(data_dir, sprintf("Supp3S%dCovmtx.csv", study)))))
  w <- list(Conf_True = c(.5, .5, 0, 0), Disconf_True = c(.5, -.5, 0, 0),
            Conf_False = c(0, 0, .5, .5), Disconf_False = c(0, 0, .5, -.5))
  long <- bind_rows(lapply(names(w), function(v) {
    wv <- c(w[[v]], 0, 0, 0)
    m <- sum(wv * b); se <- sqrt(sum(wv^2 * diag(S)))
    tibble(variable = v, mean = sigmoid(m), lo = sigmoid(m - se), hi = sigmoid(m + se))
  })) %>%
    mutate(Condition = factor(ifelse(grepl("True", variable), "True", "False"), levels = c("True", "False")),
           Type = factor(ifelse(grepl("Conf", variable), "Confirmatory", "Disconfirmatory"),
                         levels = c("Confirmatory", "Disconfirmatory")))
  p <- c(True = 2 * pt(-abs(b[2] / sqrt(S[2, 2])), ns[study] - 1),
         False = 2 * pt(-abs(b[4] / sqrt(S[4, 4])), ns[study] - 1))
  cat(sprintf("Study %d: verified t(%d) = %.2f, p = %.2g; debunked t(%d) = %.2f, p = %.2g\n", study,
              ns[study] - 1, b[2] / sqrt(S[2, 2]), p[1], ns[study] - 1, b[4] / sqrt(S[4, 4]), p[2]))
  pts <- build_points(read.csv(file.path(data_dir, sprintf("Supp3S%dPoints.csv", study))))
  g <- make_lr_plot(long, pts, sprintf("Study %d", study), FONT, sapply(p, stars))
  k <- which(sapply(g$layers, function(l) inherits(l$geom, "GeomText")))
  g$layers[[k]]$data$vj <- ifelse(g$layers[[k]]$data$label == "n.s.", -0.35, 0.2)
  g$layers[[k]]$aes_params$vjust <- NULL
  g$layers[[k]]$mapping$vjust <- quote(vj)
  g
}

rec <- read.csv(file.path(rl_root, "Computational", "Parameter Recovery", "M4Pers_RecoveryData.csv"))
pars <- c("Conf_True", "Conf_False", "Disconf_True", "Disconf_False", "Beta", "rho", "tau")
display <- c("Conf_Verified", "Conf_Debunked", "Disconf_Verified", "Disconf_Debunked", "Beta", "Rho", "Tau")
C <- cor(rec[paste0("True_", pars)], rec[paste0("Estimated_", pars)])
dimnames(C) <- list(display, display)
m <- melt(C, varnames = c("Simulated", "Estimated"), value.name = "Correlation") %>%
  mutate(Simulated = factor(Simulated, levels = display), Estimated = factor(Estimated, levels = display))
p_heat <- ggplot(m, aes(Estimated, Simulated, fill = Correlation)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%.2f", Correlation)), size = 2.2) +
  coord_fixed() +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0, limits = c(-1, 1)) +
  labs(title = "Parameter Recovery", x = "Estimated", y = "Simulated") +
  theme_cowplot(FONT * 0.8) +
  theme(axis.text = element_text(size = FONT * 0.75), axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(hjust = 0.5), legend.title = element_text(size = FONT * 0.8),
        legend.text = element_text(size = FONT * 0.7), legend.key.width = unit(0.3, "cm"))

long_rec <- data.frame(Parameter = factor(rep(display, each = nrow(rec)), levels = display),
                       True = unlist(rec[paste0("True_", pars)]),
                       Estimated = unlist(rec[paste0("Estimated_", pars)]))
r_lab <- long_rec %>% group_by(Parameter) %>%
  summarise(label = sprintf("r = %.2f", cor(True, Estimated)))
p_scat <- ggplot(long_rec, aes(True, Estimated)) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", colour = "grey40", linewidth = 0.4) +
  geom_point(shape = 21, size = 1.3, fill = "grey50", colour = "black", stroke = 0.3, alpha = 0.5) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "red", linewidth = 0.5) +
  geom_text(data = r_lab, aes(label = label), x = Inf, y = -Inf, hjust = 1.1, vjust = -0.6,
            size = 2, inherit.aes = FALSE) +
  facet_wrap(~ Parameter, scales = "free", ncol = 4) +
  scale_x_continuous(breaks = scales::breaks_pretty(4)) +
  scale_y_continuous(breaks = scales::breaks_pretty(4)) +
  labs(x = "Simulated", y = "Estimated") +
  theme_cowplot(FONT * 0.8) +
  theme(strip.background = element_rect(fill = "grey90", colour = NA),
        strip.text = element_text(size = FONT * 0.7, margin = margin(2, 0, 2, 0)),
        axis.text = element_text(size = FONT * 0.6), panel.spacing = unit(0.3, "cm"))

set.seed(4)
top <- plot_grid(lr_panel(1), lr_panel(2), ncol = 2, labels = c("(a)", "(b)"), label_size = FONT * 1.2)
heat_row <- plot_grid(NULL, p_heat, NULL, ncol = 3, rel_widths = c(0.15, 0.7, 0.15), labels = c("(c)", "", ""),
                      label_size = FONT * 1.2, hjust = 0, label_x = 0.01)
fig <- plot_grid(top, heat_row, p_scat, ncol = 1, rel_heights = c(1, 0.95, 0.9))
save_publication_figure(fig, "FigS2_GradualPerseveration", file.path(rl_root, "Plots", "Supplemental Figures"),
                        width_cm = FIG_WIDTH_CM[["double"]], height_cm = 23)
