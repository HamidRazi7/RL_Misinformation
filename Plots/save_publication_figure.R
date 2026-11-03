FIG_WIDTH_CM <- c(single = 8.5, onehalf = 11.6, double = 17.6)

FIG_DPI_HALFTONE <- 300
FIG_DPI_BITMAP   <- 1200

FIG_BASE_SIZE <- 9

FIG_BAR_FILL_PRIMARY   <- "grey55"
FIG_BAR_FILL_SECONDARY <- "grey86"
FIG_BAR_FILL           <- FIG_BAR_FILL_PRIMARY

CM_PER_IN <- 2.54

find_ghostscript <- function() {
  candidates <- c(
    Sys.getenv("R_GSCMD"),
    Sys.which("gswin64c"), Sys.which("gswin32c"), Sys.which("gs"),
    file.path(Sys.getenv("LOCALAPPDATA"),
              "Programs/MiKTeX/miktex/bin/x64/mgs.exe")
  )
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (length(candidates)) candidates[[1]] else NA_character_
}

save_publication_figure <- function(plot,
                                    basename,
                                    dir,
                                    width_cm = FIG_WIDTH_CM[["double"]],
                                    height_cm = 10,
                                    dpi = FIG_DPI_HALFTONE,
                                    formats = c("tiff", "eps", "pdf", "png"),
                                    submission_dir = NULL) {
  if (is.null(submission_dir)) submission_dir <- dir
  for (d in unique(c(dir, submission_dir))) {
    if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  }

  if (width_cm > max(FIG_WIDTH_CM)) {
    warning("width ", width_cm, " cm exceeds the journal's widest column (",
            max(FIG_WIDTH_CM), " cm)")
  }

  w <- width_cm / CM_PER_IN
  h <- height_cm / CM_PER_IN
  path <- function(ext) {
    file.path(if (ext %in% c("tiff", "eps")) submission_dir else dir,
              paste0(basename, ".", ext))
  }

  if ("tiff" %in% formats) {
    ggplot2::ggsave(path("tiff"), plot, width = w, height = h, units = "in",
                    dpi = dpi, device = "tiff", compression = "lzw",
                    bg = "white")
  }

  if (any(c("pdf", "eps") %in% formats)) {
    ggplot2::ggsave(path("pdf"), plot, width = w, height = h, units = "in",
                    device = grDevices::cairo_pdf, bg = "white")
  }

  if ("eps" %in% formats) {
    gs <- find_ghostscript()
    if (is.na(gs)) {
      ggplot2::ggsave(path("eps"), plot, width = w, height = h, units = "in",
                      device = grDevices::cairo_ps, fallback_resolution = dpi,
                      bg = "white")
      warning("Ghostscript not found: ", basename,
              ".eps has embedded fonts, not outlines. Set R_GSCMD to a gs binary.")
    } else {
      status <- system2(gs, c("-q", "-dNOPAUSE", "-dBATCH", "-dNoOutputFonts",
                              "-sDEVICE=eps2write",
                              paste0("-sOutputFile=", shQuote(path("eps"))),
                              shQuote(path("pdf"))),
                        stdout = TRUE, stderr = TRUE)
      if (!is.null(attr(status, "status")) && attr(status, "status") != 0) {
        stop("Ghostscript failed for ", basename, ": ",
             paste(status, collapse = " "))
      }
    }
  }

  if (!("pdf" %in% formats) && file.exists(path("pdf"))) unlink(path("pdf"))

  if ("png" %in% formats) {
    ggplot2::ggsave(path("png"), plot, width = w, height = h, units = "in",
                    dpi = dpi, bg = "white")
  }

  message("wrote: ", basename, ".{", paste(formats, collapse = ","), "}  (",
          width_cm, " x ", height_cm, " cm @ ", dpi, " dpi)")
  invisible(vapply(formats, path, character(1)))
}
