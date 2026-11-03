OLD_TO_NEW <- c(
  M1 = "M1", M5 = "M2", M3 = "M3", M2 = "M4", M4 = "M5", M6 = "M5rho",
  M1Rho = "M1rho",
  M5Rho = "M2rho",
  M3Rho = "M3rho",
  M2Rho = "M4rho"
)

MODEL_ORDER_SIX <- c(paste0("M", 1:5), "M5rho")
MODEL_ORDER_TEN <- c(MODEL_ORDER_SIX, paste0("M", 1:4, "rho"))

MODEL_PLOTMATH <- setNames(sub("rho$", "*rho", MODEL_ORDER_TEN), MODEL_ORDER_TEN)

model_axis_labels <- function(x) parse(text = MODEL_PLOTMATH[as.character(x)])

MODEL_SET_LEVELS <- c("Main text", "Perseveration variant")

model_set_group <- function(model) {
  factor(ifelse(as.character(model) %in% MODEL_ORDER_SIX,
                MODEL_SET_LEVELS[1], MODEL_SET_LEVELS[2]),
         levels = MODEL_SET_LEVELS)
}

MODEL_COLOURS <- setNames(
  c("#66c2a5", "#fc8d62", "#8da0cb", "#e78ac3", "#a6d854", "#ffd92f",
    "#1b9e77", "#d95f02", "#7570b3", "#a65628"),
  MODEL_ORDER_TEN
)

renumber_models <- function(x) {
  x <- as.character(x)
  unknown <- setdiff(unique(x), names(OLD_TO_NEW))
  if (length(unknown)) {
    stop("renumber_models(): no mapping for ", paste(unknown, collapse = ", "))
  }
  unname(OLD_TO_NEW[x])
}

renumber_factor <- function(x, levels = MODEL_ORDER_SIX) {
  factor(renumber_models(x), levels = levels)
}
