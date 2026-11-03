library(dplyr)
library(tidyr)
library(ggplot2)
library(cowplot)
library(here)

Points <- read.csv(here("Data", "Processed", "PointsSuppM1_S2.csv"))

Points <- Points %>%
  rename(
    True_Chosen_Pos = postrue_1,
    True_Chosen_Neg = negtrue_1,
    True_Unchosen_Pos = postrue_2,
    True_Unchosen_Neg = negtrue_2,

    False_Chosen_Pos = posfalse_1,
    False_Chosen_Neg = negfalse_1,
    False_Unchosen_Pos = posfalse_2,
    False_Unchosen_Neg = negfalse_2
  )

create_long_data <- function(points_df, feedback_type) {
  levels <- paste0(feedback_type, c("_Chosen_Pos", "_Chosen_Neg", "_Unchosen_Pos", "_Unchosen_Neg"))
  points_df %>%
    pivot_longer(cols = all_of(levels), names_to = "variable", values_to = "value") %>%
    group_by(variable) %>%
    summarise(mean = mean(value), sem = sd(value) / sqrt(n()), .groups = "drop") %>%
    mutate(sem_lower = mean - sem, sem_upper = mean + sem,
           Group = factor(variable, levels = levels))
}

create_plot <- function(long_data, points_df, feedback_type, title) {

  point_data <- points_df %>%
    pivot_longer(
      cols = c(
        paste0(feedback_type, "_Chosen_Pos"),
        paste0(feedback_type, "_Chosen_Neg"),
        paste0(feedback_type, "_Unchosen_Pos"),
        paste0(feedback_type, "_Unchosen_Neg")
      ),
      names_to = "variable",
      values_to = "value"
    ) %>%
    mutate(
      Group = factor(variable, levels = c(
        paste0(feedback_type, "_Chosen_Pos"),
        paste0(feedback_type, "_Chosen_Neg"),
        paste0(feedback_type, "_Unchosen_Pos"),
        paste0(feedback_type, "_Unchosen_Neg")
      ))
    )

  x_labels <- if(feedback_type == "True") {
    c(expression(alpha["VC+"]), expression(alpha["VC-"]), expression(alpha["VU+"]), expression(alpha["VU-"]))
  } else {
    c(expression(alpha["DC+"]), expression(alpha["DC-"]), expression(alpha["DU+"]), expression(alpha["DU-"]))
  }

  ggplot(long_data, aes(x = Group, y = mean, fill = Group)) +
    geom_bar(stat = "identity", position = position_dodge(), width = 0.6) +
    geom_errorbar(
      aes(ymin = sem_lower, ymax = sem_upper),
      width = 0.2, linewidth = 1.5
    ) +
    geom_point(
      data = point_data,
      aes(x = Group, y = value),
      position = position_jitter(width = 0.05),
      size = 4,
      alpha = 0.6,
      color = "black"
    ) +
    scale_fill_manual(values = c(
      "#4682B4",
      "#B0C4DE",
      "#FF6347",
      "#FFA07A"
    )) +
    scale_x_discrete(labels = x_labels) +
    scale_y_continuous(
      limits = c(0, 1),
      breaks = seq(0, 1, by = 0.20)
    ) +
    theme_cowplot(40) +
    theme(
      legend.position = "none",
      plot.title = element_text(hjust = 0.5, face = "bold", size = 40),
      axis.title.y = element_text(size = 40, face = "bold"),
      axis.text.x = element_text(size = 40),
      axis.text.y = element_text(size = 40)
    ) +
    labs(
      title = title,
      x = "",
      y = "Learning Rate"
    )
}

long_data_true <- create_long_data(Points, "True")
long_data_false <- create_long_data(Points, "False")

plot_true <- create_plot(long_data_true, Points, "True", "Verified Feedback")
plot_false <- create_plot(long_data_false, Points, "False", "Debunked Feedback")

print(long_data_true)
print(long_data_false)
plot_true
plot_false
