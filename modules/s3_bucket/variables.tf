variable "bucket_name" {
  type        = string
  description = "Creates a unique bucket name beginning with the specified prefix."
}

variable "bucket_policy_additional_statements" {
  type        = string
  default     = ""
  description = "Additional policy statements to be appended to the default bucket policy"
}
