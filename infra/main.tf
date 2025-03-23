terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Bucket S3 para almacenar el ZIP de la Lambda
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "lbd-projects-mocksy-bucket-${random_id.bucket_id.hex}"
}

resource "random_id" "bucket_id" {
  byte_length = 8
}

resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "deployment-package.zip"
  source = "../deployment-package.zip" # Ruta local del ZIP
}

# Validar si el IAM Role existe antes de usarlo
data "external" "iam_role_check" {
  program = ["bash", "./bash/check_iam_role.sh"]

  query = {
    role_name = var.lambda_role
  }
}

# Crear el rol si no existe
resource "aws_iam_role" "lambda_execution_role" {
  count = data.external.iam_role_check.result.exists == "true" ? 0 : 1

  name = var.lambda_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Adjuntar política AWSLambdaBasicExecutionRole
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = length(aws_iam_role.lambda_execution_role) > 0 ? aws_iam_role.lambda_execution_role[0].name : var.lambda_role
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

  depends_on = [aws_iam_role.lambda_execution_role]
}

# Adjuntar política AmazonCognitoPowerUser
resource "aws_iam_role_policy_attachment" "cognito_power_user" {
  role       = length(aws_iam_role.lambda_execution_role) > 0 ? aws_iam_role.lambda_execution_role[0].name : var.lambda_role
  policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoPowerUser"

  depends_on = [aws_iam_role.lambda_execution_role]
}

resource "aws_iam_role_policy_attachment" "s3_power_user" {
  role       = length(aws_iam_role.lambda_execution_role) > 0 ? aws_iam_role.lambda_execution_role[0].name : var.lambda_role
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"

  depends_on = [aws_iam_role.lambda_execution_role]
}


# Validar si la Lambda existe antes de usarla
data "external" "existing_lambda" {
  program = ["bash", "./bash/check_lambda.sh"]

  query = {
    lambda_name = var.lambda_function_name
  }
}

# Unificar creación y actualización de Lambda
resource "aws_lambda_function" "mocksy_lambda" {
  count         = data.external.existing_lambda.result.exists == "true" ? 0 : 1
  function_name = var.lambda_function_name
  handler       = "main.handler"
  runtime       = "python3.11"
  s3_bucket     = aws_s3_bucket.lambda_bucket.id
  s3_key        = aws_s3_object.lambda_zip.key

  source_code_hash = filebase64sha256("../deployment-package.zip")

  role =   length(aws_iam_role.lambda_execution_role) > 0 ? aws_iam_role.lambda_execution_role[0].arn : data.external.iam_role_check.result.arn

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      COGNITO_USER_POOL_ID = var.COGNITO_USER_POOL_ID
      COGNITO_CLIENT_ID    = var.COGNITO_CLIENT_ID
      COGNITO_DOMAIN       = var.COGNITO_DOMAIN
      DB_USER              = var.DB_USER
      DB_PASSWORD          = var.DB_PASSWORD
      DB_HOST              = var.DB_HOST
      DB_PORT              = var.DB_PORT
      DB_NAME              = var.DB_NAME
      PYTHONPATH           = var.PYTHONPATH
    }
  }
}

# Actualizar el código de la Lambda si ya existe
resource "null_resource" "lambda_update_trigger" {
  count = data.external.existing_lambda.result.exists == "true" ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      aws lambda update-function-code \
        --function-name "${var.lambda_function_name}" \
        --s3-bucket "${aws_s3_bucket.lambda_bucket.id}" \
        --s3-key "${aws_s3_object.lambda_zip.key}"
    EOT
  }
}
