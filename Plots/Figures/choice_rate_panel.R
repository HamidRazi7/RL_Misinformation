suppressMessages({ library(dplyr); library(ggplot2); library(cowplot) })

SPLIT_LEVELS <- c("Solvable", "Unsolvable")
SPLIT_COLS   <- c(Solvable = "#F8766D", Unsolvable = "#00BFC4")

p_stars <- function(p)
  ifelse(p < .001, "***", ifelse(p < .01, "**", ifelse(p < .05, "*", "n.s.")))

choice_rate_stats <- function(per_subject) {
  w <- tidyr::pivot_wider(per_subject, id_cols = subn, names_from = split,
                          values_from = p)
  vs_chance <- lapply(SPLIT_LEVELS, function(s)
    t.test(w[[s]], mu = .5))
  paired <- t.test(w$Solvable, w$Unsolvable, paired = TRUE)
  tibble(test = c(paste(SPLIT_LEVELS, "vs 0.5"),
                  "Solvable vs Unsolvable (paired)"),
         t  = c(sapply(vs_chance, `[[`, "statistic"), paired$statistic),
         df = c(sapply(vs_chance, `[[`, "parameter"), paired$parameter),
         p  = c(sapply(vs_chance, `[[`, "p.value"), paired$p.value)) |>
    mutate(label = p_stars(p))
}

choice_rate_panel <- function(per_subject, base_font = 25, title = NULL,
                              ylab = "Choice Rate Option 1 (%)", jitter_seed = 123,
                              dots = TRUE, ylim_top = 1.2) {
  k  <- base_font / 13
  ps <- per_subject |> mutate(split = factor(split, levels = SPLIT_LEVELS))
  bars <- ps |> group_by(split) |>
    summarise(m = mean(p), se = sd(p) / sqrt(n()),
              top = if (dots) max(p) else m + se, .groups = "drop")
  st <- choice_rate_stats(ps)

  star_y    <- bars$top + .04
  bracket_y <- max(star_y) + .08
  lab_size  <- function(lab) ifelse(lab == "n.s.", base_font * .30, base_font * .45)
  lab_vjust <- function(lab) ifelse(lab == "n.s.", -.3, .15)

  per_bar <- tibble(split = bars$split, y = star_y, label = st$label[1:2])
  paired  <- st$label[3]

  ggplot(bars, aes(split, m)) +
    geom_col(aes(fill = split), colour = "black", width = .8,
             linewidth = .55 * k) +
    geom_errorbar(aes(ymin = m - se, ymax = m + se), width = .25,
                  linewidth = .45 * k) +
    { if (dots)
        geom_point(data = ps, aes(split, p),
                   position = position_jitter(width = .2, height = 0, seed = jitter_seed),
                   shape = 21, fill = "black", colour = "black", size = 1.3 * k) } +
    geom_hline(yintercept = .5, linetype = "dashed", colour = "red",
               linewidth = .55 * k) +
    geom_text(data = per_bar, aes(split, y, label = label),
              size = lab_size(per_bar$label), vjust = lab_vjust(per_bar$label)) +
    annotate("segment", x = 1, xend = 2, y = bracket_y, yend = bracket_y,
             linewidth = .5 * k) +
    annotate("text", x = 1.5, y = bracket_y, label = paired,
             size = lab_size(paired), vjust = if (paired == "n.s.") -.4 else .2) +
    scale_fill_manual(values = SPLIT_COLS, guide = "none") +
    scale_y_continuous(breaks = seq(0, 1, .25), labels = function(x) x * 100,
                       expand = expansion(mult = 0)) +
    coord_cartesian(ylim = c(0, ylim_top), clip = "off") +
    guides(y = guide_axis(cap = "upper")) +
    labs(x = NULL, y = ylab, title = title) +
    theme_cowplot(base_font) +
    theme(axis.text  = element_text(size = base_font * .92, colour = "black"),
          axis.title = element_text(size = base_font),
          axis.title.y = element_text(hjust = .5 / ylim_top),
          axis.line  = element_line(linewidth = .5 * k, colour = "black"),
          axis.ticks = element_line(linewidth = .5 * k, colour = "black"),
          axis.ticks.length = unit(.22 * k, "cm"),
          plot.title.position = "plot",
          plot.title = element_text(size = base_font * .8, face = "bold",
                                    hjust = .5, lineheight = 1.05),
          plot.margin = margin(6 * k, 8 * k, 4 * k, 6 * k))
}

choice_rate_grouped <- function(per_subject, base_font = 25,
                                ylab = "Choice Rate Option 1 (%)", jitter_seed = 123,
                                dots = TRUE, ylim_top = 1.2, strip_size = .92) {
  k  <- base_font / 13
  ps <- per_subject |> mutate(split = factor(split, levels = SPLIT_LEVELS))
  groups <- levels(ps$group)

  bars <- ps |> group_by(group, split) |>
    summarise(m = mean(p), se = sd(p) / sqrt(n()),
              top = if (dots) max(p) else m + se, .groups = "drop")
  st <- lapply(split(ps, ps$group)[groups], choice_rate_stats)

  lab_size  <- function(lab) ifelse(lab == "n.s.", base_font * .30, base_font * .45)
  lab_vjust <- function(lab) ifelse(lab == "n.s.", -.3, .15)

  per_bar <- bars |> mutate(y = top + .04,
                            label = unlist(lapply(st, function(s) s$label[1:2])))
  brackets <- per_bar |> group_by(group) |> summarise(y = max(y) + .08) |>
    mutate(label = sapply(st[as.character(group)], function(s) s$label[3]))

  ggplot(bars, aes(split, m)) +
    geom_col(aes(fill = split), colour = "black", width = .8,
             linewidth = .55 * k) +
    geom_errorbar(aes(ymin = m - se, ymax = m + se), width = .25,
                  linewidth = .45 * k) +
    { if (dots)
        geom_point(data = ps, aes(split, p),
                   position = position_jitter(width = .2, height = 0, seed = jitter_seed),
                   shape = 21, fill = "black", colour = "black", size = 1.3 * k) } +
    geom_hline(yintercept = .5, linetype = "dashed", colour = "red",
               linewidth = .55 * k) +
    geom_text(data = per_bar, aes(split, y, label = label),
              size = lab_size(per_bar$label), vjust = lab_vjust(per_bar$label)) +
    geom_segment(data = brackets, aes(x = 1, xend = 2, y = y, yend = y),
                 linewidth = .5 * k, inherit.aes = FALSE) +
    geom_text(data = brackets, aes(x = 1.5, y = y, label = label),
              size = lab_size(brackets$label),
              vjust = ifelse(brackets$label == "n.s.", -.4, .2), inherit.aes = FALSE) +
    facet_grid(. ~ group) +
    scale_fill_manual(values = SPLIT_COLS, guide = "none") +
    scale_x_discrete(expand = expansion(add = .75)) +
    scale_y_continuous(breaks = seq(0, 1, .25), labels = function(x) x * 100,
                       expand = expansion(mult = 0)) +
    coord_cartesian(ylim = c(0, ylim_top), clip = "off") +
    guides(y = guide_axis(cap = "upper")) +
    labs(x = NULL, y = ylab) +
    theme_cowplot(base_font) +
    theme(axis.text  = element_text(size = base_font * .92, colour = "black"),
          axis.title = element_text(size = base_font),
          axis.title.y = element_text(hjust = .5 / ylim_top),
          axis.line  = element_line(linewidth = .5 * k, colour = "black"),
          axis.ticks = element_line(linewidth = .5 * k, colour = "black"),
          axis.ticks.length = unit(.22 * k, "cm"),
          panel.spacing = unit(0, "pt"),
          strip.background = element_blank(),
          strip.clip = "off",
          strip.text = element_text(size = base_font * strip_size, face = "bold",
                                    lineheight = 1.05, margin = margin(b = 2 * k)),
          plot.margin = margin(14 * k, 8 * k, 4 * k, 6 * k))
}
