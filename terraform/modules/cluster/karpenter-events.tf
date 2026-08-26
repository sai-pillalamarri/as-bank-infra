resource "aws_cloudwatch_event_rule" "karpenter_health" {
  name = "${local.cluster_name}-karpenter-health"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })
}

resource "aws_cloudwatch_event_rule" "karpenter_spot_interruption" {
  name = "${local.cluster_name}-karpenter-spot-interruption"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_rule" "karpenter_rebalance" {
  name = "${local.cluster_name}-karpenter-rebalance"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })
}

resource "aws_cloudwatch_event_rule" "karpenter_instance_state" {
  name = "${local.cluster_name}-karpenter-instance-state"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  })
}

resource "aws_cloudwatch_event_rule" "karpenter_capacity_reservation" {
  name = "${local.cluster_name}-karpenter-capacity-reservation"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Capacity Reservation Instance Interruption Warning"]
  })
}

locals {
  karpenter_event_rules = {
    health               = aws_cloudwatch_event_rule.karpenter_health
    spot_interruption    = aws_cloudwatch_event_rule.karpenter_spot_interruption
    rebalance            = aws_cloudwatch_event_rule.karpenter_rebalance
    instance_state       = aws_cloudwatch_event_rule.karpenter_instance_state
    capacity_reservation = aws_cloudwatch_event_rule.karpenter_capacity_reservation
  }
}

resource "aws_cloudwatch_event_target" "karpenter" {
  for_each = local.karpenter_event_rules

  rule = each.value.name
  arn  = aws_sqs_queue.karpenter.arn
}

resource "aws_sqs_queue_policy" "karpenter" {
  queue_url = aws_sqs_queue.karpenter.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridge"
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",
            "sqs.amazonaws.com",
          ]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter.arn
      },
      {
        Sid       = "DenyUnencryptedTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.karpenter.arn
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}
