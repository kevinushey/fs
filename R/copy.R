#' Copy a files, directories and links.
#'
#' `file_copy()` copies files. `link_copy()` creates a new link pointing to the
#' same location as the previous link. `dir_copy()` copies the directory
#' recursively to the new location.
#' @param new_path Character vector of paths to the new locations
#' @param overwrite Overwrite files if they exist. If this is `FALSE` and the
#'   file exists an error will be thrown.
#' @template fs
#' @name copy
#' @export
#' @examples
#' file_create("foo")
#' file_copy("foo", "bar")
#' try(file_copy("foo", "bar"))
#' file_copy("foo", "bar", overwrite = TRUE)
#' file_delete(c("foo", "bar"))
file_copy <- function(path, new_path, overwrite = FALSE) {
  path <- path_expand(path)
  new_path <- path_expand(new_path)
  copyfile_(path, new_path, isTRUE(overwrite))

  invisible(path_tidy(new_path))
}

#' @rdname copy
#' @examples
#' dir_create("foo")
#' # Create a directory and put a few files in it
#' files <- file_create(c("foo/bar", "foo/baz"))
#' file_exists(files)
#'
#' # Copy the directory
#' dir_copy("foo", "foo2")
#' file_exists(path("foo2", path_file(files)))
#'
#' # Create a link to the directory
#' link_create("foo", "loo")
#' link_path("loo")
#' link_copy("loo", "loo2")
#' link_path("loo2")
#'
#' # Cleanup
#' dir_delete(c("foo", "foo2"))
#' @export
dir_copy <- function(path, new_path, overwrite = FALSE) {
  path <- path_expand(path)
  new_path <- path_expand(new_path)

  stopifnot(all(is_dir(path)))

  to_delete <- isTRUE(overwrite) & dir_exists(new_path)
  if (any(to_delete)) {
    dir_delete(new_path[to_delete])
  }

  dirs <- dir_list(path, recursive = TRUE)

  # Remove first path from directories and prepend new path
  new_dirs <- path(new_path, sub("[^/]*/", "", dirs))
  dir_create(c(new_path, new_dirs))

  files <- file_list(path, recursive = TRUE,
    type = c("unknown", "file", "FIFO", "socket", "character_device", "block_device"))

  if (length(files) > 0) {
    # Remove first path from files and prepend new path
    new_files <- path(new_path, sub("[^/]*/", "", files))
    file_copy(files, new_files)
  }

  links <- file_list(path, type = "symlink", recursive = TRUE)
  if (length(links) > 0) {
    new_links <- path(new_path, sub("[^/]*/", "", links))
    link_copy(links, new_links)
  }

  invisible(path_tidy(new_path))
}

#' @rdname copy
#' @export
link_copy <- function(path, new_path, overwrite = FALSE) {
  path <- path_expand(path)
  new_path <- path_expand(new_path)

  stopifnot(all(is_link(path)))

  to_delete <- isTRUE(overwrite) & link_exists(new_path)
  if (any(to_delete)) {
    link_delete(new_path[to_delete])
  }

  invisible(link_create(link_path(path), new_path))
}