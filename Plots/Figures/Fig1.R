codes_dir <- "."
fig_dir   <- file.path(".", "Plots", "Figures")

source(file.path("Plots", "Figures", "Fig1_Hypotheses.R"))
suppressMessages(library(tibble))

design <- tribble(
  ~split,        ~accuracy, ~option,    ~prob,
  "Solvable",    "True",    "Option 1", 0.80,
  "Solvable",    "True",    "Option 2", 0.20,
  "Solvable",    "False",   "Option 1", 0.50,
  "Solvable",    "False",   "Option 2", 0.50,
  "Unsolvable",  "True",    "Option 1", 0.50,
  "Unsolvable",  "True",    "Option 2", 0.50,
  "Unsolvable",  "False",   "Option 1", 0.80,
  "Unsolvable",  "False",   "Option 2", 0.20) |>
  mutate(accuracy = factor(accuracy, levels = c("True", "False")))

design_panel <- function(which, base_font, ylab = TRUE, title_size = base_font) {
  k    <- base_font / 13
  fill <- SPLIT_COLS[[which]]
  ggplot(filter(design, split == which), aes(accuracy, prob, fill = option)) +
    geom_col(position = position_dodge(width = .8), width = .7,
             colour = "black", linewidth = .55 * k) +
    geom_hline(yintercept = .5, linetype = "dashed", colour = "red",
               linewidth = .55 * k) +
    scale_fill_manual(values = c("Option 1" = fill,
                                 "Option 2" = scales::alpha(fill, .4))) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, .2),
                       labels = scales::label_number(accuracy = .01),
                       expand = expansion(mult = 0)) +
    scale_x_discrete(labels = c(True = "Verified", False = "Debunked")) +
    labs(x = "Verification Cue",
         y = if (ylab) "Probability of best outcome" else NULL,
         fill = NULL, title = which) +
    theme_cowplot(base_font) +
    theme(axis.text  = element_text(size = base_font * .92, colour = "black"),
          axis.title = element_text(size = base_font),
          axis.line  = element_line(linewidth = .5 * k, colour = "black"),
          axis.ticks = element_line(linewidth = .5 * k, colour = "black"),
          axis.ticks.length = unit(.22 * k, "cm"),
          plot.title = element_text(size = title_size, face = "bold", hjust = .5),
          legend.text = element_text(size = base_font * .88),
          legend.key.size = unit(.9 * k, "lines"),
          plot.margin = margin(14 * k, 8 * k, 4 * k, 6 * k))
}

timeline    <- png::readPNG(file.path(fig_dir, "Fig1a_timeline.png"))
TIMELINE_CM <- 10.5
FIG_W_CM    <- FIG_WIDTH_CM[["double"]]
ROW_CM      <- c(a = TIMELINE_CM * nrow(timeline) / ncol(timeline) + .6,
                 bc = 6.8, d = 7.8)

FONT <- 11

build_fig1 <- function(base_font, dots) {
  a <- ggdraw() +
    draw_grob(grid::rasterGrob(timeline, interpolate = TRUE),
              x = .5, y = .5, width = TIMELINE_CM / FIG_W_CM, height = 1,
              hjust = .5, vjust = .5)
  bc <- plot_grid(design_panel("Solvable", base_font),
                  design_panel("Unsolvable", base_font),
                  ncol = 2, labels = c("(b)", "(c)"), label_size = base_font * 1.2)
  d <- plot_grid(build_hypotheses(base_font, dots = dots),
                 labels = "(d)", label_size = base_font * 1.2)
  plot_grid(plot_grid(a, labels = "(a)", label_size = base_font * 1.2), bc, d,
            ncol = 1, rel_heights = ROW_CM)
}

for (v in list(list(dots = TRUE, stem = "Fig1_dots"),
               list(dots = FALSE, stem = "Fig1_nodots")))
  save_publication_figure(build_fig1(FONT, v$dots), v$stem, fig_dir,
                          width_cm = FIG_W_CM, height_cm = sum(ROW_CM))

hyp_all <- bind_rows(by_agent) |>
  mutate(group = factor(agent, levels = AGENTS$agent,
                        labels = paste(AGENTS$title, AGENTS$rule, sep = "\n")))

build_fig1_merged <- function(base_font, dots) {
  a <- ggdraw() +
    draw_grob(grid::rasterGrob(timeline, interpolate = TRUE),
              x = .5, y = .5, width = TIMELINE_CM / FIG_W_CM, height = 1,
              hjust = .5, vjust = .5)
  bc <- plot_grid(design_panel("Solvable", base_font),
                  design_panel("Unsolvable", base_font),
                  ncol = 2, labels = c("(b)", "(c)"), label_size = base_font * 1.2)
  d <- plot_grid(choice_rate_grouped(hyp_all, base_font = base_font, dots = dots,
                                     ylim_top = if (dots) 1.2 else 1.05,
                                     strip_size = .78),
                 labels = "(d)", label_size = base_font * 1.2)
  plot_grid(plot_grid(a, labels = "(a)", label_size = base_font * 1.2), bc, d,
            ncol = 1, rel_heights = ROW_CM)
}

for (v in list(list(dots = TRUE, stem = "Fig1_dots_merged"),
               list(dots = FALSE, stem = "Fig1_nodots_merged")))
  save_publication_figure(build_fig1_merged(FONT, v$dots), v$stem, fig_dir,
                          width_cm = FIG_W_CM, height_cm = sum(ROW_CM),
                          formats = c("pdf", "png"))

HYP_TITLES <- c("No learning from debunked information",
                "Equal learning from verified and debunked information",
                "Reduced learning from debunked information")
schematic <- tibble(
  group = factor(rep(HYP_TITLES, each = 2), levels = HYP_TITLES),
  split = factor(rep(SPLIT_LEVELS, 3), levels = SPLIT_LEVELS),
  m     = c(.75, .50,  .75, .75,  .75, .62))

choice_rate_schematic <- function(bars, base_font = 25, ylab = "Choice Rate Option 1 (%)",
                                  ylim_top = 1.05, strip_size = .92) {
  k  <- base_font / 13
  ns <- tibble(group = factor(HYP_TITLES[2], levels = HYP_TITLES), y = .85)
  chance <- tibble(group = factor(HYP_TITLES[3], levels = HYP_TITLES), x = 2.82, y = .5)
  ggplot(bars, aes(split, m)) +
    geom_col(aes(fill = split), colour = "black", width = .8, linewidth = .55 * k) +
    geom_hline(yintercept = .5, linetype = "dashed", colour = "red", linewidth = .55 * k) +
    geom_segment(data = ns, aes(x = 1, xend = 2, y = y, yend = y),
                 linewidth = .5 * k, inherit.aes = FALSE) +
    geom_text(data = ns, aes(x = 1.5, y = y, label = "n.s."), size = base_font * .36,
              vjust = -.4, inherit.aes = FALSE) +
    geom_text(data = chance, aes(x = x, y = y, label = "chance
level"), size = base_font * .30,
              colour = "red", hjust = 0, vjust = .5, lineheight = .9, inherit.aes = FALSE) +
    facet_grid(. ~ group, labeller = label_wrap_gen(width = 22)) +
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
          axis.text.x = element_text(size = base_font * .80, colour = "black"),
          axis.line  = element_line(linewidth = .5 * k, colour = "black"),
          axis.ticks = element_line(linewidth = .5 * k, colour = "black"),
          axis.ticks.length = unit(.22 * k, "cm"),
          panel.spacing = unit(0, "pt"),
          strip.background = element_blank(), strip.clip = "off",
          strip.text = element_text(size = base_font * strip_size, face = "bold",
                                    lineheight = 1.05, margin = margin(b = 2 * k)),
          plot.margin = margin(14 * k, 46 * k, 4 * k, 6 * k))
}

build_fig1_schematic <- function(base_font, font_d = base_font) {
  a <- ggdraw() +
    draw_grob(grid::rasterGrob(timeline, interpolate = TRUE),
              x = .5, y = .5, width = TIMELINE_CM / FIG_W_CM, height = 1,
              hjust = .5, vjust = .5)
  bc <- plot_grid(design_panel("Solvable", base_font, title_size = font_d * .92),
                  design_panel("Unsolvable", base_font, title_size = font_d * .92),
                  ncol = 2, labels = c("(b)", "(c)"), label_size = base_font * 1.2)
  d <- plot_grid(choice_rate_schematic(schematic, base_font = font_d),
                 labels = "(d)", label_size = base_font * 1.2)
  plot_grid(plot_grid(a, labels = "(a)", label_size = base_font * 1.2), bc, d,
            ncol = 1, rel_heights = ROW_CM)
}

FONT_SCHEMATIC <- 13
save_publication_figure(build_fig1_schematic(FONT, font_d = FONT_SCHEMATIC), "Fig1_schematic_v4", fig_dir,
                        width_cm = FIG_W_CM, height_cm = sum(ROW_CM),
                        formats = c("tiff", "pdf", "png"),
                        submission_dir = file.path(dirname(fig_dir), "Submission"))
