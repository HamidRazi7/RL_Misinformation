suppressMessages({ library(dplyr); library(ggplot2); library(cowplot); library(purrr) })

codes_dir <- "."
cache_dir <- file.path("Data", "model_free_sim_cache")
data_dir  <- file.path("./Data/Processed")
supp_dir  <- file.path("./Computational/Models 1rho-4rho")
fig_dir   <- file.path("./Plots/Figures")
source(file.path("./Plots/save_publication_figure.R"))

STUDIES <- c(1L, 2L)
N_REP   <- 50
NEW_FROM_OLD <- c(M1 = "M1", M2 = "M4", M3 = "M3", M4 = "M5", M5 = "M2", M6 = "M6")

PFAV <- list(`1` = list(`1` = c(.8, .2), `0` = c(.5, .5)),
             `2` = list(`1` = c(.5, .5), `0` = c(.8, .2)),
             `3` = list(`1` = c(.8, .2), `0` = c(.5, .5)),
             `4` = list(`1` = c(.5, .5), `0` = c(.8, .2)))
rw <- function(gain, fav) if (gain) (if (fav) 10 else 1) else (if (fav) -1 else -10)

prep <- function(path) {
  read.csv(path) |>
    mutate(gain    = Condition.Type == "gain",
           factual = as.integer(FeedbackType == 1),
           fav     = as.integer(ifelse(gain, Reward == 10, Reward == -1)),
           acc     = as.integer(TrialType)) |>
    arrange(subn, Trial) |>
    group_by(subn, Condition) |> mutate(pos = row_number() - 1) |> ungroup()
}

sim_agent <- function(seq, ct, dt, cf, df, beta, rho = 0, tau = 1) {
  Q <- matrix(0, 4, 2); C <- matrix(0, 4, 2); n <- nrow(seq)
  ch_v <- integer(n); fav_v <- integer(n)
  for (i in seq_len(n)) {
    cond <- seq$Condition[i]; acc <- seq$acc[i]
    fct  <- seq$factual[i];   gn  <- seq$gain[i]
    q <- Q[cond, ]; cc <- C[cond, ]
    p1 <- 1 / (1 + exp(-beta * (q[1] - q[2]) - rho * (cc[1] - cc[2])))
    ch <- if (runif(1) < p1) 1L else 2L
    shown <- if (fct == 1) ch else 3L - ch
    fav <- runif(1) < PFAV[[as.character(cond)]][[as.character(acc)]][shown]
    d <- rw(gn, fav) - q[shown]
    conf <- (shown == ch && d > 0) || (shown != ch && d < 0)
    a <- if (acc == 1) (if (conf) ct else dt) else (if (conf) cf else df)
    Q[cond, shown] <- q[shown] + a * d
    other <- 3L - ch
    C[cond, ch]    <- C[cond, ch]    + tau * (1 - C[cond, ch])
    C[cond, other] <- C[cond, other] + tau * (0 - C[cond, other])
    ch_v[i] <- ch; fav_v[i] <- as.integer(fav)
  }
  tibble(Condition = seq$Condition, gain = seq$gain, factual = seq$factual,
         acc = seq$acc, fav = fav_v, Choice = ch_v, pos = seq$pos)
}

simulate_points <- function(d, P, n_rep = 40, seed) {
  set.seed(seed)
  subs <- sort(unique(d$subn))
  stopifnot(nrow(P) == length(subs))
  seqs <- lapply(subs, function(s) d |> filter(subn == s) |>
                   select(Trial, Condition, acc, factual, gain, pos) |> arrange(Trial))
  names(seqs) <- as.character(subs)
  purrr::map_dfr(seq_len(n_rep), function(r)
    purrr::map_dfr(seq_along(subs), function(i) {
      p <- P[i, ]
      sim_agent(seqs[[as.character(subs[i])]], p$Conf_True, p$Disconf_True,
                p$Conf_False, p$Disconf_False, p$Beta, rho = p$rho,
                tau = p$tau) |>
        mutate(subn = subs[i], rep = r)
    }))
}

add_history <- function(df, grp) {
  df |> arrange(across(all_of(grp)), Condition, pos) |>
    group_by(across(all_of(c(grp, "Condition")))) |>
    mutate(stay = as.integer(Choice == lag(Choice)),
           run  = {
             s <- stay; r <- integer(length(s)); kk <- 0L
             for (i in seq_along(s)) {
               if (is.na(s[i])) { r[i] <- NA_integer_; kk <- 0L }
               else { r[i] <- kk; kk <- if (s[i] == 1) kk + 1L else 0L }
             }
             r
           }) |>
    ungroup() |> filter(!is.na(stay))
}

sem <- function(x) sd(x) / sqrt(length(x))

agg_obs <- function(h, val, keys)
  h |> group_by(subn, across(all_of(keys))) |>
    summarise(p = mean(.data[[val]]), .groups = "drop") |>
    group_by(across(all_of(keys))) |>
    summarise(m = mean(p), lo = mean(p) - sem(p), hi = mean(p) + sem(p),
              .groups = "drop")

agg_sim <- function(h, val, keys)
  h |> group_by(rep, subn, across(all_of(keys))) |>
    summarise(p = mean(.data[[val]]), .groups = "drop") |>
    group_by(rep, across(all_of(keys))) |>
    summarise(g = mean(p), .groups = "drop") |>
    group_by(across(all_of(keys))) |>
    summarise(m = mean(g), lo = quantile(g, .025), hi = quantile(g, .975),
              .groups = "drop")

agg_sim_sem <- function(h, val, keys)
  h |> group_by(rep, subn, across(all_of(keys))) |>
    summarise(p = mean(.data[[val]]), .groups = "drop") |>
    group_by(rep, across(all_of(keys))) |>
    summarise(g = mean(p), se = sem(p), .groups = "drop") |>
    group_by(across(all_of(keys))) |>
    summarise(m = mean(g), lo = mean(g) - mean(se), hi = mean(g) + mean(se),
              .groups = "drop")

load_study <- function(STUDY) {
  d <- prep(file.path(data_dir, sprintf("Study%d.csv", STUDY)))

  get_sim <- function(m_old)
    readRDS(file.path(cache_dir, sprintf("Study%d_M%d_rep%d_seed%d.rds", STUDY,
                                         m_old, N_REP, 1907 + 100 * STUDY + m_old)))$simulated

  main_sims <- purrr::map_dfr(c(1, 4, 6), function(m)
    get_sim(m) |> mutate(model = unname(NEW_FROM_OLD[paste0("M", m)])))

  rho_file  <- file.path(supp_dir, sprintf("M1RhoPointsS%d.csv", STUDY))
  rho_cache <- file.path(cache_dir, sprintf("Study%d_M1rho_rep%d_diag.rds", STUDY, N_REP))
  if (!file.exists(rho_file))
    stop(basename(rho_file), " not found; run M1Rho_FitPoints.jl ", STUDY, " first")
  if (file.exists(rho_cache) && file.mtime(rho_cache) > file.mtime(rho_file)) {
    rho_sim <- readRDS(rho_cache)
  } else {
    message("simulating M1+rho ...")
    rho_sim <- simulate_points(d, read.csv(rho_file), n_rep = N_REP,
                               seed = 5500 + STUDY)
    saveRDS(rho_sim, rho_cache, compress = "gzip")
  }

  tag <- function(df) df |> mutate(subn = paste0("S", STUDY, "_", subn))
  list(sims_h = bind_rows(main_sims, rho_sim |> mutate(model = "M1rho")) |>
         tag() |> add_history(c("model", "rep", "subn")),
       obs_h  = d |> tag() |> add_history("subn"))
}

per_study <- lapply(STUDIES, load_study)
sims_h <- purrr::map_dfr(per_study, "sims_h")
obs_h  <- purrr::map_dfr(per_study, "obs_h")

rl_mod <- sims_h |> mutate(rb = pmin(run, 4)) |> agg_sim("stay", c("model", "rb"))
rl_sem <- sims_h |> mutate(rb = pmin(run, 4)) |> agg_sim_sem("stay", c("model", "rb"))
rl_obs <- obs_h  |> mutate(rb = pmin(run, 4)) |> agg_obs("stay", "rb") |>
  mutate(model = "Observed")

per_study <- lapply(STUDIES, load_study)
sims_h <- purrr::map_dfr(per_study, "sims_h")
obs_h  <- purrr::map_dfr(per_study, "obs_h")

rl_mod <- sims_h |> mutate(rb = pmin(run, 4)) |> agg_sim("stay", c("model", "rb"))
rl_obs <- obs_h  |> mutate(rb = pmin(run, 4)) |> agg_obs("stay", "rb")

FONT <- 11

LABS <- c(M1    = "No Confirmation Bias &
No Perseveration (M1)",
          M1rho = "Only Perseveration (M1ρ)",
          M5    = "Only Confirmation Bias (M5)",
          M6    = "Confirmation Bias &
Perseveration (M5ρ)")
MOD_COLS   <- c(M1 = "#8C8C8C", M1rho = "#8FB3DE", M5 = "#F26241", M6 = "#3A75AE")
MOD_SHAPES <- c(M1 = 22, M1rho = 23, M5 = 24, M6 = 21)

build_fig6 <- function(base_font, legend_side = "left") {
  k <- base_font / 13
  ggplot() +
    geom_hline(yintercept = .5, linetype = "dashed", colour = "grey45", linewidth = .6 * k) +
    geom_ribbon(data = rl_mod, aes(rb, ymin = lo, ymax = hi, fill = model), alpha = .18, colour = NA) +
    geom_line(data = rl_mod, aes(rb, m, colour = model), linewidth = .8 * k) +
    geom_point(data = rl_mod, aes(rb, m, fill = model, shape = model),
               colour = "black", size = 2.2 * k, stroke = .4 * k) +
    geom_errorbar(data = rl_obs, aes(rb, ymin = lo, ymax = hi), width = .12,
                  linewidth = .6 * k, colour = "black") +
    geom_point(data = rl_obs, aes(rb, m), shape = 21, fill = "white", colour = "black",
               size = 3 * k, stroke = .8 * k) +
    scale_colour_manual(values = MOD_COLS, labels = LABS, breaks = names(LABS)) +
    scale_fill_manual(values = MOD_COLS, labels = LABS, breaks = names(LABS)) +
    scale_shape_manual(values = MOD_SHAPES, labels = LABS, breaks = names(LABS)) +
    scale_x_continuous(breaks = 0:4, labels = c("0", "1", "2", "3", "4+")) +
    scale_y_continuous(breaks = seq(.5, .9, .1), labels = function(x) x * 100,
                       limits = c(.45, .9), expand = c(0, 0)) +
    labs(x = "Consecutive Repeats Already Made", y = "Repetition Probability (%)",
         colour = NULL, fill = NULL, shape = NULL) +
    theme_cowplot(base_font) +
    theme(axis.text  = element_text(size = base_font * .92, colour = "black"),
          axis.title = element_text(size = base_font),
          axis.line  = element_line(linewidth = .5 * k, colour = "black"),
          axis.ticks = element_line(linewidth = .5 * k, colour = "black"),
          legend.position = legend_side,
          legend.text = element_text(size = base_font * .85, lineheight = .95),
          legend.key.height = unit(2.1 * k, "lines"),
          legend.key.width  = unit(1.8 * k, "lines"),
          plot.margin = margin(6 * k, 10 * k, 4 * k, 4 * k))
}

for (side in c("left", "right")) {
  stem <- if (side == "left") "Fig6_ChoiceRepetition" else "Fig6_ChoiceRepetition_right"
  save_publication_figure(build_fig6(FONT, side), stem, fig_dir,
                          width_cm = FIG_WIDTH_CM[["double"]], height_cm = 9)
  ggsave(file.path(fig_dir, paste0(stem, "_large.png")), build_fig6(25, side),
         width = 18, height = 9.5, dpi = 300, bg = "white")
  message("wrote ", stem)
}
