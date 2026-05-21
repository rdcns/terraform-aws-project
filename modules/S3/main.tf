resource "aws_s3_bucket" "bucket" {
  bucket = "cia-project-bucket"

  tags = {
    Name        = "CIA-Project-Bucket"
    Environment = "Dev"
  }
}