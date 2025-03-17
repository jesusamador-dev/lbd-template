#!/bin/bash
set -e  # Detiene el script si hay un error

eval "$(jq -r '@sh "LAMBDA_NAME=\(.lambda_name)"')"

# Si la variable está vacía, devolver error
if [[ -z "$LAMBDA_NAME" ]]; then
  echo "❌ Error: 'lambda_name' no definido"
  echo '{"exists": "false"}'
  exit 1
fi

# Verificar si la Lambda existe y extraer su ARN
LAMBDA_ARN=$(aws lambda get-function --function-name "$LAMBDA_NAME" --query 'Configuration.FunctionArn' --output text 2>/dev/null || echo "")

if [[ -n "$LAMBDA_ARN" ]]; then
  echo "{\"exists\": \"true\", \"arn\": \"$LAMBDA_ARN\"}"
else
  echo '{"exists": "false", "arn": ""}'
fi


