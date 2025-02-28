output "lb_dns" {
  value = aws_lb.hung.dns_name
}
output "lb_sg" {
  value = aws_security_group.alb_sg.id
}
output "target_group_arn" {
  value = aws_lb_target_group.hung.arn
}
