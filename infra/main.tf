provider "aws" {
  region = vars.aws_region
}

# Bucket S3 para almacenar el ZIP de la Lambda
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "kuosel-lambda-bucket-${random_id.bucket_id.hex}"
}

resource "random_id" "bucket_id" {
  byte_length = 8
}

resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "deployment-package.zip"
  source = "../deployment-package.zip" # Ruta local del ZIP
}

# Data source para buscar el rol existente
data "aws_iam_role" "existing_role" {
  name = vars.lambda_role
}

# Crear el rol si no existe
resource "aws_iam_role" "lambda_execution_role" {
  count = can(data.aws_iam_role.existing_role.name) ? 0 : 1

  name = vars.lambda_role

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
  role       = coalesce(try(data.aws_iam_role.existing_role.name, null), try(aws_iam_role.lambda_execution_role[0].name, null))
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Adjuntar política AmazonCognitoPowerUser
resource "aws_iam_role_policy_attachment" "cognito_power_user" {
  role       = coalesce(try(data.aws_iam_role.existing_role.name, null), try(aws_iam_role.lambda_execution_role[0].name, null))
  policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoPowerUser"
}

resource "aws_iam_role_policy_attachment" "s3_power_user" {
  role       = coalesce(try(data.aws_iam_role.existing_role.name, null), try(aws_iam_role.lambda_execution_role[0].name, null))
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Data source para buscar la Lambda existente
data "aws_lambda_function" "existing_lambda" {
  function_name = vars.lambda_function_name
}

# Unificar creación y actualización de Lambda
resource "aws_lambda_function" "kuosel_lambda" {
  count         = length(try(data.aws_lambda_function.existing_lambda.id, [])) > 0 ? 0 : 1
  function_name = vars.lambda_function_name
  handler       = "main.handler"
  runtime       = "python3.11"
  s3_bucket     = aws_s3_bucket.lambda_bucket.id
  s3_key        = aws_s3_object.lambda_zip.key

  source_code_hash = filebase64sha256("../deployment-package.zip")

  role = coalesce(
    try(data.aws_iam_role.existing_role.arn, null),
    length(aws_iam_role.lambda_execution_role) > 0 ? aws_iam_role.lambda_execution_role[0].arn : null
  )

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
      PYTHONPATH           = "/var/task/dependencies:/var/task"
    }
  }
}

# Actualizar el código de la Lambda si ya existe
resource "null_resource" "lambda_update_trigger" {
  count = length(try(data.aws_lambda_function.existing_lambda.arn, [])) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      aws lambda update-function-code \
        --function-name ${data.aws_lambda_function.existing_lambda.function_name} \
        --s3-bucket ${aws_s3_bucket.lambda_bucket.id} \
        --s3-key ${aws_s3_object.lambda_zip.key}
    EOT
  }
}