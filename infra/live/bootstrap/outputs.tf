output "state_bucket" {
  description = "Configurar como variable de repositorio TF_STATE_BUCKET."
  value       = aws_s3_bucket.state.bucket
}

output "plan_role_arn" {
  description = "Configurar como variable de repositorio AWS_PLAN_ROLE_ARN."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Configurar como variable de repositorio AWS_APPLY_ROLE_ARN."
  value       = aws_iam_role.apply.arn
}
