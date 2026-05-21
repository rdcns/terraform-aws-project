output "public_subnet_id" {
  value = aws_subnet.my-subnet.id
}

output "vpc" {
  value = aws_vpc.my-vpc.id
}