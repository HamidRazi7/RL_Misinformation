suppressPackageStartupMessages({
  library(ggplot2)
  library(reshape2)
  library(cowplot)
})

base <- "./Computational/Parameter Recovery"

d <- read.csv(file.path(base, "M4Rho_RecoveryData.csv"))

pars <- c("Conf_True", "Conf_False", "Disconf_True", "Disconf_False", "Beta", "rho")
display <- c("Conf True", "Conf False", "Disconf True", "Disconf False", "Beta", "Rho")

sim <- d[paste0("True_", pars)]
est <- d[paste0("Estimated_", pars)]
C <- cor(sim, est)
colnames(C) <- display
rownames(C) <- display

m <- melt(C, varnames = c("Simulated", "Estimated"), value.name = "Correlation")
m$Correlation <- round(m$Correlation, 2)

m$Simulated <- factor(m$Simulated, levels = display)
m$Estimated <- factor(m$Estimated, levels = display)

p_heat <- ggplot(m, aes(x = Estimated, y = Simulated, fill = Correlation)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%.2f", Correlation)), color = "black", size = 9) +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red",
                       midpoint = 0, limits = c(-1, 1), name = "Correlation") +
  labs(title = "Parameter Recovery", x = "Estimated", y = "Simulated") +
  theme_cowplot(40) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(base, "M4Rho_ParameterRecovery_Heatmap.png"), p_heat, width = 8, height = 6.6, dpi = 300, bg = "white")
cat("Saved ", file.path(base, "M4Rho_ParameterRecovery_Heatmap.png"), "\n", sep = "")
print(p_heat)

long <- data.frame(
  Parameter = rep(pars, each = nrow(d)),
  True      = unlist(d[paste0("True_", pars)]),
  Estimated = unlist(d[paste0("Estimated_", pars)])
)
long$Parameter <- factor(long$Parameter, levels = pars, labels = display)

stats <- do.call(rbind, lapply(levels(long$Parameter), function(p) {
  s <- subset(long, Parameter == p)
  data.frame(Parameter = p,
             label = sprintf("r = %.2f\nbias = %+.3f",
                             cor(s$True, s$Estimated),
                             mean(s$Estimated - s$True)))
}))

p_scat <- ggplot(long, aes(x = True, y = Estimated)) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "grey40") +
  geom_point(alpha = 0.55, size = 1.6, color = "black") +
  geom_smooth(method = "lm", se = FALSE, color = "red", linewidth = 0.8) +
  geom_text(data = stats, aes(label = label),
            x = Inf, y = -Inf, hjust = 1.05, vjust = -0.3, size = 3.4) +
  facet_wrap(~ Parameter, scales = "free", ncol = 3) +
  labs(title = "Parameter Recovery: Simulated vs Estimated",
       x = "Simulated (true)", y = "Estimated") +
  theme_cowplot(40)

ggsave(file.path(base, "M4Rho_Scatterplots.png"), p_scat, width = 11, height = 6.8, dpi = 300, bg = "white")
cat("Saved ", file.path(base, "M4Rho_Scatterplots.png"), "\n", sep = "")
print(p_scat)

print(round(C, 3))
