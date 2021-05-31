

variable "project_id" {
  description = "The GCP project to use for integration tests"
}

variable "random_string_for_testing" {
  description = "A random string of characters to be appended to resource names to ensure uniqueness"
  default     = "a1"
}
