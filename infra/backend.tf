terraform {
  # Backend configuration will be provided by GitHub Actions
  # This allows for environment-specific state files
  backend "s3" {
    # These values will be overridden by -backend-config flags
    bucket = "placeholder"
    key    = "placeholder"
    region = "placeholder"
  }
} 