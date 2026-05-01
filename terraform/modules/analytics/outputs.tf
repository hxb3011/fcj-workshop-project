output "getter_role_arn"    { value = aws_iam_role.getter_role.arn }
output "athena_workgroup_name" { value = aws_athena_workgroup.log_project_workgroup.name }