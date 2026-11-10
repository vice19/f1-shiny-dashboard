# ============================================================
# PRO_UI SERVER WRAPPER
# Reuses the main server.R located in the parent folder ("app/")
# so you only maintain a single server logic and a single dataset folder.
# ============================================================

parent_dir = normalizePath("..", winslash = "/")
source(file.path(parent_dir, "server.R"))

main_server = server

server = function(input, output, session) {
  # Temporarily set working directory to the parent "app/" directory
  # so read_csv("f1_data_2025/...") finds the dataset seamlessly.
  old_wd = setwd(parent_dir)
  on.exit(setwd(old_wd))

  main_server(input, output, session)
}
