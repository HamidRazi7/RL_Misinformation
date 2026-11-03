suppressPackageStartupMessages({
  library(ggplot2)
  library(cowplot)
  library(reshape2)
  library(dplyr)
})

fig_dir <- "./Plots/Figures"

pars    <- c("Conf_True", "Disconf_True", "Conf_False", "Disconf_False", "Beta", "rho")
display <- c("Conf True", "Disconf True", "Conf False", "Disconf False", "Beta", "Rho")

make_cor_heat <- function(Points) {
  C <- cor(Points[pars])
  colnames(C) <- rownames(C) <- display
  Cdf <- as.data.frame(C); Cdf$P1 <- rownames(C)
  df <- melt(Cdf, id.vars = "P1", variable.name = "P2",
             value.name = "Correlation") %>%
    mutate(P1 = factor(P1, levels = display),
           P2 = factor(P2, levels = display),
           lab = sprintf("%.2f", round(Correlation, 2)))
  ggplot(df, aes(x = P2, y = P1, fill = Correlation)) +
    geom_tile(color = "white", linewidth = 0.8) +
    geom_text(aes(label = lab), color = "black", size = 6) +
    scale_fill_gradient2(low = "blue", mid = "white", high = "red",
                         midpoint = 0, limits = c(-1, 1), name = "Correlation") +
    coord_equal() +
    labs(x = NULL, y = NULL) +
    theme_cowplot(35) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 35),
          axis.text.y = element_text(size = 35),
          legend.key.height = unit(1.6, "cm"))
}

S1 <- read.csv(file.path(fig_dir, "M6NoreparamPointsS1.csv"))
S2 <- read.csv(file.path(fig_dir, "M6NoreparamPointsS2.csv"))

p1 <- make_cor_heat(S1) + ggtitle("Correlation Between the Parameters (Study 1)")
p2 <- make_cor_heat(S2) + ggtitle("Correlation Between the Parameters (Study 2)")

ggsave(file.path(fig_dir, "M6Noreparam_CorHeatmap_Study1.png"), p1,
       width = 7.5, height = 7, dpi = 300, bg = "white")
ggsave(file.path(fig_dir, "M6Noreparam_CorHeatmap_Study2.png"), p2,
       width = 7.5, height = 7, dpi = 300, bg = "white")

combo <- cowplot::plot_grid(p1 + ggtitle("Correlation Between the Parameters (Study 1)"),
                            p2 + ggtitle("Correlation Between the Parameters (Study 2)"),
                            nrow = 1, align = "h", axis = "tb")
ggsave(file.path(fig_dir, "M6Noreparam_CorHeatmaps.png"), combo,
       width = 15, height = 7, dpi = 300, bg = "white")

print(p1)
print(p2)
print(combo)

cat("Saved M6Noreparam_CorHeatmap_Study1.png, _Study2.png, M6Noreparam_CorHeatmaps.png\n")
