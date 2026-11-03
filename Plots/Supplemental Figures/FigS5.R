suppressPackageStartupMessages({
  library(ggplot2)
  library(cowplot)
  library(reshape2)
})

points_dir <- file.path(".", "Computational", "Hypothesis Tests")

params <- c("Conf_True", "Conf_False", "Disconf_True", "Disconf_False", "Beta", "rho")

modeldef <- data.frame(file   = c("it", "pa"),
                       suffix = c("_interaction", "_ttest"),
                       tag    = c("I", "T"),
                       stringsAsFactors = FALSE)

row_bottomTop <- do.call(c, lapply(seq_len(nrow(modeldef)), function(i) {
  paste0(params, modeldef$suffix[i])
}))

read_points <- function(study, model) {
  f <- file.path(points_dir, sprintf("PointsS%d_%s_T.csv", study, model))
  if (!file.exists(f)) stop("Missing input: ", f)
  read.csv(f, stringsAsFactors = FALSE)
}

build_study <- function(study) {
  np <- read_points(study, "np")
  do.call(rbind, lapply(seq_len(nrow(modeldef)), function(i) {
    re <- read_points(study, modeldef$file[i])
    C  <- cor(re[params], np[params])
    m  <- melt(C, varnames = c("Reparam", "Original"), value.name = "Correlation")
    m$Reparam   <- factor(paste0(as.character(m$Reparam), modeldef$suffix[i]),
                          levels = row_bottomTop)
    m$Original  <- factor(m$Original, levels = params)
    m$Correlation <- round(m$Correlation, 2)
    m$txtcol    <- ifelse(abs(m$Correlation) > 0.6, "white", "black")
    m
  }))
}

make_matrix <- function(d) {
  ggplot(d, aes(x = Original, y = Reparam, fill = Correlation)) +
    geom_tile(colour = "white", linewidth = 0.5) +
    geom_text(aes(label = sprintf("%.2f", Correlation), colour = txtcol), size = 7) +
    scale_colour_identity() +
    scale_fill_gradient2(low = "blue", mid = "white", high = "red",
                         midpoint = 0, limits = c(-1, 1), name = "Correlation") +
    labs(x = NULL, y = NULL) +
    theme_cowplot(35) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

for (s in c(1, 2)) {
  print(make_matrix(build_study(s)))
}

d_both <- rbind(transform(build_study(1), study = "Study 1"),
                transform(build_study(2), study = "Study 2"))
d_both$study <- factor(d_both$study, levels = c("Study 1", "Study 2"))
print(make_matrix(d_both) + facet_wrap(~ study, ncol = 2))

diag_dat <- do.call(rbind, lapply(c(1, 2), function(s) {
  np <- read_points(s, "np")
  do.call(rbind, lapply(seq_len(nrow(modeldef)), function(i) {
    re <- read_points(s, modeldef$file[i])
    r  <- diag(cor(re[params], np[params]))
    data.frame(study = s,
               tag   = modeldef$tag[i],
               param = params,
               j     = seq_along(params),
               r     = r)
  }))
}))
diag_dat$y <- diag_dat$j + (diag_dat$study - 1) * 2 + as.integer(diag_dat$tag == "I")
diag_dat$r  <- round(diag_dat$r, 2)
diag_dat$txtcol <- ifelse(abs(diag_dat$r) > 0.6, "white", "black")
diag_dat$label <- sprintf("S%d%s\n%.2f", diag_dat$study, diag_dat$tag, diag_dat$r)
diag_dat$param <- factor(diag_dat$param, levels = params)

p_diag <- ggplot(diag_dat, aes(x = param, y = y, fill = r)) +
  geom_tile(colour = "white", linewidth = 0.6) +
  geom_text(aes(label = label, colour = txtcol), size = 8) +
  scale_colour_identity() +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red",
                       midpoint = 0, limits = c(-1, 1), name = "Correlation") +
  scale_y_continuous(breaks = NULL) +
  labs(x = NULL, y = NULL) +
  theme_cowplot(35) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
print(p_diag)

scatter_params <- c("Conf_True", "Disconf_True", "Conf_False",
                     "Disconf_False", "Beta", "rho")
param_expressions <- list(
  Conf_True     = expression(alpha[conf]^{"verified"}),
  Disconf_True  = expression(alpha[disconf]^{"verified"}),
  Conf_False    = expression(alpha[conf]^{"debunked"}),
  Disconf_False = expression(alpha[disconf]^{"debunked"}),
  Beta          = expression(beta),
  rho           = expression(rho))

point_fill <- "#2C6E9B"

model_titles <- c(pa = "Paired t-test model",
                  it = "Interaction model")

fmt_r <- function(r) {
  if (r >= 0.99995) "italic(r) > 0.9999" else sprintf("italic(r) == %.4f", r)
}

if (!exists("RP_SCALE")) RP_SCALE <- 1

panel_scale <- function(vals) {
  rng <- range(vals)
  b   <- scales::breaks_pretty(3)(rng)
  b   <- b[b >= rng[1] - diff(rng) * 0.12 & b <= rng[2] + diff(rng) * 0.12]
  lims <- range(c(rng, b))
  pad  <- diff(lims) * 0.05
  if (RP_SCALE < 0.7) {
    ends <- c(b[1], b[length(b)])
    b <- c(ends[1], mean(ends), ends[2])
  } else if (length(b) > 4) {
    b <- b[seq(1, length(b), by = 2)]
  }
  list(lims = lims + c(-pad, pad), breaks = b)
}

make_one_panel <- function(model_file, study, par) {
  np <- read_points(study, "np")
  re <- read_points(study, model_file)
  df <- data.frame(x = np[[par]], y = re[[par]])
  r  <- cor(df$x, df$y)

  sc   <- panel_scale(c(df$x, df$y))
  lims <- sc$lims

  ggplot(df, aes(x = x, y = y)) +
    geom_abline(slope = 1, intercept = 0,
                linetype = "22", colour = "grey55", linewidth = 0.4) +
    geom_point(shape = 21, fill = point_fill, colour = "grey20",
               size = 1.9 * RP_SCALE, alpha = 0.75, stroke = 0.25) +
    {if (RP_SCALE >= 0.7)
       annotate("text", x = lims[1] + diff(lims) * 0.04,
                y = lims[2] - diff(lims) * 0.02,
                label = fmt_r(r), parse = TRUE,
                hjust = 0, vjust = 1, colour = "grey15", size = 4.2 * RP_SCALE)} +
    scale_x_continuous(breaks = sc$breaks,
                       labels = scales::label_number(accuracy = 0.01,
                                                     drop0trailing = TRUE),
                       expand = c(0, 0)) +
    scale_y_continuous(breaks = sc$breaks,
                       labels = scales::label_number(accuracy = 0.01,
                                                     drop0trailing = TRUE),
                       expand = c(0, 0)) +
    coord_cartesian(xlim = lims, ylim = lims, clip = "off") +
    labs(x = NULL, y = NULL) +
    theme_half_open(font_size = 13 * RP_SCALE) +
    theme(aspect.ratio = 1,
          plot.margin  = margin(2, 7, 2, 2),
          axis.text    = element_text(size = if (RP_SCALE < 0.7) 7.5 else
                                              12.5 * RP_SCALE, colour = "grey20"),
          axis.ticks   = element_line(linewidth = 0.35, colour = "grey20"),
          axis.line    = element_line(linewidth = 0.35, colour = "grey20"),
          axis.ticks.length = unit(2, "pt"))
}

make_scatter_grid <- function(model_file) {
  panels <- unlist(lapply(1:2, function(study)
    lapply(scatter_params, function(par) make_one_panel(model_file, study, par))),
    recursive = FALSE)

  body <- plot_grid(plotlist = panels, ncol = length(scatter_params),
                    align = "hv", axis = "tblr")

  bottom <- plot_grid(plotlist = lapply(scatter_params, function(par)
                        ggdraw() + draw_label(param_expressions[[par]], size = 26 * RP_SCALE)),
                      ncol = length(scatter_params))

  row_lab <- sapply(1:2, function(s)
    sprintf("Study %d (n = %d)", s, nrow(read_points(s, "np"))))
  left <- plot_grid(plotlist = lapply(row_lab, function(s)
                      ggdraw() + draw_label(s, size = 16 * RP_SCALE,
                                            fontface = "bold", angle = 90)),
                    ncol = 1)

  core <- plot_grid(left, body, NULL, bottom, ncol = 2,
                    rel_widths = c(0.055, 1), rel_heights = c(1, 0.13))

  ggdraw() +
    draw_plot(core, x = 0.04, y = 0.075, width = 0.957, height = 0.865) +
    draw_label(model_titles[[model_file]],
               x = 0.52, y = 0.982, vjust = 1, size = 22 * RP_SCALE,
               fontface = "bold") +
    draw_line(c(0.30, 0.74), c(0.958, 0.958), colour = "grey35",
              linewidth = 0.9 * RP_SCALE) +
    draw_label("Original model estimate",
               x = 0.52, y = 0.012, vjust = 0, size = 18 * RP_SCALE,
               fontface = "italic", colour = "grey30") +
    draw_label("Reparameterised model estimate",
               x = 0.013, y = 0.50, vjust = 0.5, angle = 90,
               size = 18 * RP_SCALE, fontface = "italic", colour = "grey30")
}

R_MIN <- min(unlist(lapply(c("pa", "it"), function(mf)
  lapply(1:2, function(st) {
    np <- read_points(st, "np"); re <- read_points(st, mf)
    sapply(scatter_params, function(pp) cor(np[[pp]], re[[pp]]))
  }))))
R_NOTE <- sprintf("All 24 correlations ≥ %.4f", R_MIN)

make_transposed_grid <- function() {
  combos <- list(c("pa", 1), c("pa", 2), c("it", 1), c("it", 2))

  panels <- unlist(lapply(scatter_params, function(par)
    lapply(combos, function(cb) make_one_panel(cb[1], as.integer(cb[2]), par))),
    recursive = FALSE)
  body <- plot_grid(plotlist = panels, ncol = length(combos),
                    align = "hv", axis = "tblr")

  left <- plot_grid(plotlist = lapply(scatter_params, function(par)
                      ggdraw() + draw_label(param_expressions[[par]],
                                            size = 23 * RP_SCALE)),
                    ncol = 1)

  study_hdr <- plot_grid(plotlist = lapply(combos, function(cb)
                           ggdraw() + draw_label(
                             sprintf("Study %s (n = %d)", cb[2],
                                     nrow(read_points(as.integer(cb[2]), "np"))),
                             size = 15 * RP_SCALE, colour = "grey30")),
                         ncol = length(combos))
  hdr_cell <- function(txt)
    ggdraw() +
      draw_label(txt, y = 0.62, size = 21 * RP_SCALE, fontface = "bold") +
      draw_line(c(0.06, 0.94), c(0.22, 0.22),
                colour = "grey35", linewidth = 0.9 * RP_SCALE)
  model_hdr <- plot_grid(hdr_cell(model_titles[["pa"]]),
                         hdr_cell(model_titles[["it"]]), ncol = 2)

  head <- plot_grid(model_hdr, study_hdr, ncol = 1, rel_heights = c(1, 1))
  core <- plot_grid(NULL, head, left, body, ncol = 2,
                    rel_widths = c(0.12, 1), rel_heights = c(0.10, 1))

  ggdraw() +
    draw_plot(core, x = 0.035, y = 0.055, width = 0.96, height = 0.90) +
    draw_label("Original model estimate", x = 0.53, y = 0.028, vjust = 0,
               size = 18 * RP_SCALE, fontface = "italic", colour = "grey30") +
    draw_label("Reparameterised model estimate", x = 0.012, y = 0.50,
               vjust = 0.5, angle = 90, size = 18 * RP_SCALE,
               fontface = "italic", colour = "grey30") +
    draw_label(R_NOTE, x = 0.53, y = 0.002, vjust = 0, size = 13,
               fontface = "bold", colour = "black")
}

p_scatter_ttest <- make_scatter_grid("pa")
print(p_scatter_ttest)

p_scatter_interaction <- make_scatter_grid("it")
print(p_scatter_interaction)

source(file.path(".",
                 "Plots", "save_publication_figure.R"))

RP_SCALE <- 0.55
reparam_combined <- cowplot::plot_grid(
  cowplot::plot_grid(make_scatter_grid("pa"), make_scatter_grid("it"), ncol = 1,
                     labels = c("a", "b"), label_size = 11),
  ggdraw() + draw_label(R_NOTE, size = 13, fontface = "bold", colour = "black"),
  ncol = 1, rel_heights = c(1, 0.04))
reparam_transposed <- make_transposed_grid()
RP_SCALE <- 1

save_publication_figure(
  reparam_transposed, "SuppFig_ReparamEquivalence_Transposed",
  "./Plots/Supplemental Figures",
  submission_dir = "./Plots/Submission",
  width_cm = FIG_WIDTH_CM[["double"]], height_cm = 24
)

save_publication_figure(
  reparam_combined, "SuppFig_ReparamEquivalence_Combined",
  "./Plots/Supplemental Figures",
  submission_dir = "./Plots/Submission",
  width_cm = FIG_WIDTH_CM[["double"]], height_cm = 22
)

for (s in c(1, 2)) {
  cat(sprintf("\nStudy %d diagonal recovery (min over parameters):\n", s))
  for (i in seq_len(nrow(modeldef))) {
    C <- cor(read_points(s, modeldef$file[i])[params], read_points(s, "np")[params])
    r <- diag(C); names(r) <- paste0(params, modeldef$suffix[i])
    cat(sprintf("  %-15s min = %.4f\n", modeldef$suffix[i], min(r)))
  }
}
