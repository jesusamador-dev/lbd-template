variable "COGNITO_USER_POOL_ID" {
  description = "ID del User Pool de Cognito"
}

variable "COGNITO_CLIENT_ID" {
  description = "ID del Cliente de la aplicación en Cognito"
}

variable "COGNITO_DOMAIN" {
  description = "Dominio de Cognito"
}

variable "DB_USER" {
  description = "Usuario de la base de datos"
}

variable "DB_PASSWORD" {
  description = "Contraseña de la base de datos"
}

variable "DB_HOST" {
  description = "Host de la base de datos"
}

variable "DB_PORT" {
  description = "Puerto de la base de datos"
}

variable "DB_NAME" {
  description = "Nombre de la base de datos"
}

variable "lambda_already_exists" {
  description = "Indica si la función Lambda ya existe en AWS"
  type        = bool
  default     = false
}

variable "lambda_function_name" {
  type    = string
  default = "lambda-test"
}

variable "lambda_role" {
  type    = string
  default = "kuosel-lambda-execution-role"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}