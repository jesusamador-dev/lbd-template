output "s3_bucket_name" {
  value = aws_s3_bucket.lambda_bucket.bucket
}
