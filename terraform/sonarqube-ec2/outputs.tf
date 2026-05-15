output "public_ip" {
  description = "Public IP of the SonarQube instance"
  value       = aws_instance.sonarqube.public_ip
}

output "url" {
  description = "SonarQube URL"
  value       = "http://${aws_instance.sonarqube.public_dns}:9000"
}
