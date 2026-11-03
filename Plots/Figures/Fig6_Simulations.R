suppressMessages({ library(dplyr); library(purrr) })

N_REP <- 50
cache_dir <- file.path("Data", "model_free_sim_cache")
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
parameter_file <- function(study, m) switch(as.character(m),
  `1` = file.path("Data", "Processed", sprintf("M1PointsS%d.csv", study)),
  `4` = file.path("Data", "Processed", sprintf("M4PointsS%d.csv", study)),
  `6` = file.path("Computational", "Model 5rho (Winning)", sprintf("M4RhoPointsS%d_full.csv", study)))

PFAV <- list(`1`=list(`1`=c(.8,.2), `0`=c(.5,.5)),
             `2`=list(`1`=c(.5,.5), `0`=c(.8,.2)),
             `3`=list(`1`=c(.8,.2), `0`=c(.5,.5)),
             `4`=list(`1`=c(.5,.5), `0`=c(.8,.2)))
rw <- function(gain, fav) if (gain) (if (fav) 10 else 1) else (if (fav) -1 else -10)

prep <- function(path) {
  read.csv(path) |>
    mutate(gain = Condition.Type == "gain",
           factual = as.integer(FeedbackType == 1),
           fav = as.integer(ifelse(gain, Reward == 10, Reward == -1)),
           acc = as.integer(TrialType)) |>
    arrange(subn, Trial) |>
    group_by(subn, Condition) |> mutate(pos = row_number() - 1) |> ungroup() |>
    mutate(block = pos %/% 5)
}

sim_agent <- function(seq, ct, dt, cf, df, beta, rho = 0) {
  Q <- matrix(0, 4, 2); C <- matrix(0, 4, 2); n <- nrow(seq)
  choice <- integer(n); favv <- integer(n)
  for (i in seq_len(n)) {
    cond <- seq$Condition[i]; acc <- seq$acc[i]; fct <- seq$factual[i]; gn <- seq$gain[i]
    q <- Q[cond, ]; c <- C[cond, ]
    p1 <- 1 / (1 + exp(-beta * (q[1] - q[2]) - rho * (c[1] - c[2])))
    ch <- if (runif(1) < p1) 1L else 2L
    shown <- if (fct == 1) ch else 3L - ch
    fav <- runif(1) < PFAV[[as.character(cond)]][[as.character(acc)]][shown]
    d <- rw(gn, fav) - q[shown]
    conf <- (shown == ch && d > 0) || (shown != ch && d < 0)
    a <- if (acc == 1) (if (conf) ct else dt) else (if (conf) cf else df)
    Q[cond, shown] <- q[shown] + a * d
    C[cond, ] <- 0
    C[cond, ch] <- 1
    choice[i] <- ch; favv[i] <- as.integer(fav)
  }
  tibble(Condition = seq$Condition, gain = seq$gain, factual = seq$factual,
         acc = seq$acc, fav = favv, Choice = choice, pos = seq$pos,
         block = seq$block)
}

simulate_all <- function(d, P, n_rep, seed) {
  set.seed(seed)
  subs <- sort(unique(d$subn)); stopifnot(nrow(P) == length(subs))
  purrr::map_dfr(seq_len(n_rep), function(rep) {
    purrr::map_dfr(seq_along(subs), function(i) {
      s <- subs[i]; p <- P[i, ]
      seq_i <- d |> filter(subn == s) |>
        select(Trial, Condition, acc, factual, gain, pos, block) |> arrange(Trial)
      sim_agent(seq_i, p$Conf_True, p$Disconf_True, p$Conf_False, p$Disconf_False, p$Beta,
                if ("rho" %in% names(P)) p$rho else 0) |>
        mutate(subn = s, rep = rep)
    })
  })
}

for (study in 1:2) {
  d <- prep(file.path("Data", "Processed", sprintf("Study%d.csv", study)))
  for (m in c(1, 4, 6)) {
    seed <- 1907 + 100 * study + m
    out <- file.path(cache_dir, sprintf("Study%d_M%d_rep%d_seed%d.rds", study, m, N_REP, seed))
    simulated <- simulate_all(d, read.csv(parameter_file(study, m)), N_REP, seed)
    saveRDS(list(simulated = simulated), out, compress = "gzip")
    cat("wrote", out, "\n")
  }
}
