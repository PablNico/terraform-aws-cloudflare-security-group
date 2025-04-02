locals {
  resource_count = var.enabled == "true" ?
    (var.multiple_region_enabled && length(var.multiple_region_list) > 0 ? length(var.multiple_region_list) : 1)
    : 0
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = local.resource_count
  statement_id  = "AllowExecutionFromCloudWatch-${var.multiple_region_enabled && length(var.multiple_region_list) > 0 ? var.multiple_region_list[count.index] : "default"}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update-ips[count.index].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudflare-update-schedule[count.index].arn
}

resource "aws_cloudwatch_event_rule" "cloudflare-update-schedule" {
  count       = local.resource_count
  name        = "cloudflare-update-schedule-${var.multiple_region_enabled && length(var.multiple_region_list) > 0 ? var.multiple_region_list[count.index] : "default"}"
  description = "Update Cloudflare IPs every day in ${var.multiple_region_enabled && length(var.multiple_region_list) > 0 ? var.multiple_region_list[count.index] : "default"} region"

  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "cloudflare-update-schedule" {
  count = local.resource_count
  rule  = aws_cloudwatch_event_rule.cloudflare-update-schedule[count.index].name
  arn   = aws_lambda_function.update-ips[count.index].arn
}