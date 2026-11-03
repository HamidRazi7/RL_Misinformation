library(dplyr)
library(tidyr)
library(here)

for (study in 1:2) {
  rates <- read.csv(here("Data", "Processed", sprintf("Study%d.csv", study))) %>%
    group_by(subn, Condition) %>%
    summarise(p = mean(C1), .groups = "drop") %>%
    mutate(split = ifelse(Condition %in% c(1, 3), "Solvable", "Unsolvable")) %>%
    group_by(subn, split) %>%
    summarise(p = mean(p), .groups = "drop") %>%
    pivot_wider(names_from = split, values_from = p)

  cat(sprintf("\nStudy %d (n = %d)\n", study, nrow(rates)))
  for (s in c("Solvable", "Unsolvable")) {
    tt <- t.test(rates[[s]], mu = 0.5)
    cat(sprintf("  %-10s vs 0.5: t(%d) = %.2f, p = %.2g\n", s, tt$parameter, tt$statistic, tt$p.value))
  }
  tt <- t.test(rates$Solvable, rates$Unsolvable, paired = TRUE)
  cat(sprintf("  Solvable vs Unsolvable: t(%d) = %.2f, p = %.2g\n", tt$parameter, tt$statistic, tt$p.value))
}
