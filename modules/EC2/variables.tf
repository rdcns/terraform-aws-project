variable "instance_name" {
    description = "Name of the EC2 instance"
    type        = string
    default     = "my-ec2-instance"
}

variable "ami" {
    description = "AMI ID for the EC2 instance"
    type        = string
    default     = ""
}

variable "instance_type" {
    description = "Type of the EC2 instance"
    type        = string
    default     = "t3.micro"
}