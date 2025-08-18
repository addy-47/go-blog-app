locals {
  # Read the GitHub token from a file. This file is git-ignored.
  # Using a local variable allows us to use the file() function.
  github_token = chomp(file("${path.module}/github_token.txt"))
}