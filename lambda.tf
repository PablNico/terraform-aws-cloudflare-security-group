locals {
  resource_count = var.enabled == "true" ?
    (var.multiple_region_enabled && length(var.multiple_region_list) > 0 ? length(var.multiple_region_list) : 1)
    : 0
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  count = local.resource_count
  name  = var.multiple_region_enabled && length(var.multiple_region_list) > 0 ?
    "UpdateCloudflareIps-${var.multiple_region_list[count.index]}" :
    "UpdateCloudflareIps"
}

resource "aws_iam_role" "iam_for_lambda" {
  count              = local.resource_count
  name               = var.multiple_region_enabled && length(var.multiple_region_list) > 0 ?
    "lambda-cloudflare-role-${var.multiple_region_list[count.index]}" :
    "lambda-cloudflare-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "policy" {
  count              = local.resource_count
  name               = var.multiple_region_enabled && length(var.multiple_region_list) > 0 ?
    "lambda-cloudflare-policy-${var.multiple_region_list[count.index]}" :
    "lambda-cloudflare-policy"
  description        = "Allows cloudflare ip updating lambda to change security groups"
  policy             = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Resource": [
          "arn:aws:logs:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "iam:GetRolePolicy",
          "iam:ListGroupPolicies",
          "ec2:DescribeSecurityGroups",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": [
          "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy" {
  count      = local.resource_count
  role       = aws_iam_role.iam_for_lambda[count.index].id
  policy_arn = aws_iam_policy.policy[count.index].arn
}

data "archive_file" "lambda_zip" {
  count       = local.resource_count
  type        = "zip"
  source_file = "${path.module}/cloudflare-security-group.py"
  output_path = "${path.module}/lambda-${var.multiple_region_enabled && length(var.multiple_region_list) > 0 ? var.multiple_region_list[count.index] : "default"}.zip"
}


resource "aws_lambda_function" "update-ips" {
  count            = local.resource_count
  function_name    = "UpdateCloudflareIps-${var.multiple_region_enabled && length(var.multiple_region_list) > 0 ? var.multiple_region_list[count.index] : "default"}"
  filename         = "${path.module}/lambda.zip"
  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256
  handler          = "cloudflare-security-group.lambda_handler"
  role             = aws_iam_role.iam_for_lambda[count.index].arn
  runtime          = "python3.9"
  timeout          = 60
  environment {
    variables = {
      SECURITY_GROUP_ID = var.security_group_id
    }
  }
}
