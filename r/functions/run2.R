run2 <- function(name, expr, dir = "gitignore/run", reuse = TRUE) {
  path <- file.path(dir, paste0(name, ".Rds"))
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  
  if (reuse && file.exists(path)) {
    obj <- readRDS(path)
  } else {
    obj <- eval(expr)
    saveRDS(obj, path)
  }
  
  assign(name, obj, envir = parent.frame())
  invisible(obj)
}