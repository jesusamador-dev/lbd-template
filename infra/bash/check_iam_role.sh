#!/bin/bash
set -e  # Detiene el script si hay un error

eval "$(jq -r '@sh "ROLE_NAME=\(.role_name)"')"

# Si la variable está vacía, devolver error
if [[ -z "$ROLE_NAME" ]]; then
  echo "❌ Error: 'role_name' no definido"
  echo '{"exists": "false"}'
  exit 1
fi

# Verificar si el IAM Role existe
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || echo "")

if [[ -n "$ROLE_ARN" ]]; then
  echo "{\"exists\": \"true\", \"arn\": \"$ROLE_ARN\"}"
else
  echo '{"exists": "false", "arn": ""}'
fi