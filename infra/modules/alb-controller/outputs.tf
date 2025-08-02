# ALB Controller Module - outputs.tf

output "alb_controller_role_arn" {
  description = "ARN of the ALB Controller IAM role"
  value       = aws_iam_role.aws_lb_controller_role.arn
}

output "alb_controller_role_name" {
  description = "Name of the ALB Controller IAM role"
  value       = aws_iam_role.aws_lb_controller_role.name
}

output "alb_controller_policy_arn" {
  description = "ARN of the ALB Controller IAM policy"
  value       = aws_iam_policy.aws_lb_controller_policy.arn
} 