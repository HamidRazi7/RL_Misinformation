suppressMessages(library(purrr))

codes_dir <- "."
rl_dir    <- "."
data_dir  <- file.path(rl_dir, "Data/Processed")
fig_dir   <- file.path(rl_dir, "Plots/Figures")

source(file.path(fig_dir, "choice_rate_panel.R"))
source(file.path(rl_dir, "Plots", "save_publication_figure.R"))

STUDY <- as.integer(Sys.getenv("DIAG_STUDY", unset = "1"))

ALPHA_TRUE <- 0.15
BETA       <- 0.5
AGENTS <- tibble(
  agent       = c("Ignored", "Discounted", "Equal"),
  alpha_false = c(0, ALPHA_TRUE / 3, ALPHA_TRUE),
  title       = c("False information ignored",
                  "False information discounted",
                  "False information treated as true"),
  rule        = c("α_false = 0", "0 < α_false < α_true", "α_false = α_true"))

PFAV <- list(`1` = list(`1` = c(.8, .2), `0` = c(.5, .5)),
             `2` = list(`1` = c(.5, .5), `0` = c(.8, .2)),
             `3` = list(`1` = c(.8, .2), `0` = c(.5, .5)),
             `4` = list(`1` = c(.5, .5), `0` = c(.8, .2)))
rw <- function(gain, fav) if (gain) (if (fav) 10 else 1) else (if (fav) -1 else -10)

sim_m1 <- function(seq, a_true, a_false, beta) {
  Q <- matrix(0, 4, 2); n <- nrow(seq); ch_v <- integer(n)
  for (i in seq_len(n)) {
    cond <- seq$Condition[i]; acc <- seq$acc[i]
    q  <- Q[cond, ]
    ch <- if (runif(1) < 1 / (1 + exp(-beta * (q[1] - q[2])))) 1L else 2L
    shown <- if (seq$factual[i] == 1) ch else 3L - ch
    fav   <- runif(1) < PFAV[[as.character(cond)]][[as.character(acc)]][shown]
    a <- if (acc == 1) a_true else a_false
    Q[cond, shown] <- q[shown] + a * (rw(seq$gain[i], fav) - q[shown])
    ch_v[i] <- ch
  }
  tibble(Condition = seq$Condition, Choice = ch_v)
}

d <- read.csv(file.path(data_dir, sprintf("Study%d.csv", STUDY))) |>
  mutate(gain    = Condition.Type == "gain",
         factual = as.integer(FeedbackType == 1),
         acc     = as.integer(TrialType)) |>
  arrange(subn, Trial)
seqs <- split(d |> select(Condition, acc, factual, gain), d$subn)

set.seed(1100 + STUDY)
sims <- purrr::pmap_dfr(AGENTS, function(agent, alpha_false, ...)
  purrr::imap_dfr(seqs, ~ sim_m1(.x, ALPHA_TRUE, alpha_false, BETA) |>
                    mutate(subn = .y)) |>
    mutate(agent = agent))

per_agent <- sims |>
  mutate(split = ifelse(Condition %in% c(1, 3), "Solvable", "Unsolvable")) |>
  group_by(agent, subn, split) |>
  summarise(p = mean(Choice == 1), .groups = "drop")
by_agent <- split(per_agent, per_agent$agent)[AGENTS$agent]

for (a in AGENTS$agent) {
  cat(sprintf("\n%s (alpha_false = %.3f)\n", a,
              AGENTS$alpha_false[AGENTS$agent == a]))
  print(by_agent[[a]] |> group_by(split) |> summarise(m = mean(p)) |>
          as.data.frame(), digits = 3)
  print(as.data.frame(choice_rate_stats(by_agent[[a]])), digits = 3)
}

build_hypotheses <- function(base_font, dots = TRUE,
                             ylim_top = if (dots) 1.2 else 1.05)
  plot_grid(plotlist = lapply(seq_len(nrow(AGENTS)), function(i)
    choice_rate_panel(by_agent[[AGENTS$agent[i]]], base_font = base_font,
                      title = sprintf("%s\n%s", AGENTS$title[i], AGENTS$rule[i]),
                      ylab = if (i == 1) "Choice Rate Option 1 (%)" else NULL,
                      dots = dots, ylim_top = ylim_top)),
    nrow = 1, rel_widths = c(1.12, 1, 1))

if (sys.nframe() == 0L) {
  stem <- sprintf("Fig1_Hypotheses_S%d", STUDY)
  save_publication_figure(build_hypotheses(FIG_BASE_SIZE), stem, fig_dir,
                          width_cm = FIG_WIDTH_CM[["double"]], height_cm = 6.5,
                          formats = c("pdf", "png"))
  ggsave(file.path(codes_dir, sprintf("Fig1_Hypotheses_large_S%d.png", STUDY)),
         build_hypotheses(25), width = 18, height = 7.5, dpi = 300, bg = "white")
  message("wrote ", stem)
}
