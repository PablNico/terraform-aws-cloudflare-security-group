variable "security_group_id" {
  description = "An existing security group to populate with cloudflare ips as ingress rules."
}
variable "enabled" {
  description = "Whether to do anything at all, useful if cloudflare is not needed on all environments. Accepts the string 'true' or 'false'."
  default     = "true"
}
variable "multiple_region_enabled" {
  description = "Check whether resources will be created in multiple regions."
  default     = false
}
variable "multiple_region_list" {
  description = "List for the multiple region setup."
  default = []
}
variable "schedule_expression" {
  description = "The cloudwatch schedule expression used to run the updater lambda."
  default     = "cron(0 20 * * ? *)"
}
