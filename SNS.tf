/*
provider "aws" {
  region = "us-east-1"
}
resource "aws_sns_topic" "GoGreen_SNS" {
  name = "GoGreen_SNS"
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.GoGreen_SNS.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [data.aws_caller_identity.current.account_id]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.GoGreen_SNS.arn,
    ]

    sid = "__default_statement_ID"
  }
}

# # SNS Topic Subscription
# resource "aws_sns_topic_subscription" "GoGreen-SNS-Policy" {​​​​​​​​
#   topic_arn = aws_sns_topic.GoGreen-SNS.arn
#   #"arn:aws:sns:${​​​​​​​​data.aws_region.current.name}​​​​​​​​:${​​​​​​​​data.aws_caller_identity.current.account_id}​​​​​​​​:GoGreen-SNS"
#   protocol  = "email-json"
#   endpoint  = "abdullayevasevaraxon@gmail.com"
# }​​​​​​​​

# Passing Account_ID and Region_NAME
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
*/