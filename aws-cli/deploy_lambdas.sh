
#!/bin/bash

# Stop on first error
set -e

# ===================================================================================
# SCRIPT SETUP
# ===================================================================================

# Get the absolute path of the directory where this script is located
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Navigate to the project root directory (which is one level up from the script's directory)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
cd "$PROJECT_ROOT"

# ===================================================================================
# CONFIGURATION
# ===================================================================================

# AWS Region where you want to deploy the Lambda functions
AWS_REGION="us-east-1"

# A unique name for your S3 bucket to store Lambda code.
# AWS S3 bucket names are globally unique.
# TODO: Replace with your desired unique S3 bucket name.
S3_BUCKET_NAME="costinsight-lambda-code-bucket-unique-name"

# Name for the IAM Role that will be created and used by the Lambda functions
IAM_ROLE_NAME="CostInsightLambdaRole"

# Names for the Lambda functions
FETCHER_FUNCTION_NAME="CostInsight-CloudWatchFetcher"
SHUTDOWN_FUNCTION_NAME="CostInsight-AutoShutdown"

# Paths to your Lambda source code (relative to the project root)
FETCHER_LAMBDA_PATH="lambda/cloudwatch-fetcher.js"
SHUTDOWN_LAMBDA_PATH="lambda/instance-auto-shutdown.js"

# ===================================================================================
# SCRIPT LOGIC
# ===================================================================================

echo "Starting Lambda deployment process from project root: $PROJECT_ROOT"

# 1. Create S3 bucket for Lambda code
echo "Step 1/6: Creating S3 bucket '$S3_BUCKET_NAME'..."
if aws s3 ls "s3://$S3_BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb "s3://$S3_BUCKET_NAME" --region "$AWS_REGION"
    echo "S3 bucket created successfully."
else
    echo "S3 bucket '$S3_BUCKET_NAME' already exists. Skipping creation."
fi

# 2. Create IAM Role and attach policies
echo "Step 2/6: Creating IAM Role '$IAM_ROLE_NAME'..."

# Define the trust relationship policy for Lambda
TRUST_POLICY_JSON='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}'

# Define the required permissions policy
PERMISSIONS_POLICY_JSON='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeRegions",
                "ec2:StopInstances",
                "cloudwatch:GetMetricStatistics",
                "ce:GetCostAndUsage",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:GetRole"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}'

# Create the IAM role if it doesn't exist
if ! aws iam get-role --role-name "$IAM_ROLE_NAME" >/dev/null 2>&1; then
    aws iam create-role --role-name "$IAM_ROLE_NAME" --assume-role-policy-document "$TRUST_POLICY_JSON"
    echo "IAM role '$IAM_ROLE_NAME' created."
else
    echo "IAM role '$IAM_ROLE_NAME' already exists."
fi

# Attach the AWS managed policy for basic Lambda execution
MANAGED_POLICY_ARN="arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
if ! aws iam list-attached-role-policies --role-name "$IAM_ROLE_NAME" --query "AttachedPolicies[?PolicyArn=='$MANAGED_POLICY_ARN']" --output text | grep -q "."; then
    echo "Attaching AWSLambdaBasicExecutionRole policy..."
    aws iam attach-role-policy --role-name "$IAM_ROLE_NAME" --policy-arn "$MANAGED_POLICY_ARN"
else
    echo "AWSLambdaBasicExecutionRole policy already attached."
fi

# Create and attach the custom permissions policy
POLICY_NAME="${IAM_ROLE_NAME}Policy"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"

if ! aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
    echo "Creating custom permissions policy..."
    aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "$PERMISSIONS_POLICY_JSON"
else
    echo "Custom permissions policy '$POLICY_NAME' already exists."
fi

if ! aws iam list-attached-role-policies --role-name "$IAM_ROLE_NAME" --query "AttachedPolicies[?PolicyArn=='$POLICY_ARN']" --output text | grep -q "."; then
    echo "Attaching custom permissions policy..."
    aws iam attach-role-policy --role-name "$IAM_ROLE_NAME" --policy-arn "$POLICY_ARN"
else
    echo "Custom permissions policy already attached."
fi

echo "IAM role setup complete."

# Get the IAM Role ARN
ROLE_ARN=$(aws iam get-role --role-name "$IAM_ROLE_NAME" --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"

# Wait for a few seconds to ensure the IAM role is fully propagated
echo "Waiting for IAM role propagation..."
sleep 10

# 3. Package and Upload CostInsight-CloudWatchFetcher Lambda
echo "Step 3/6: Packaging and uploading '$FETCHER_FUNCTION_NAME'..."
zip -j "${FETCHER_FUNCTION_NAME}.zip" "$FETCHER_LAMBDA_PATH"
aws s3 cp "${FETCHER_FUNCTION_NAME}.zip" "s3://$S3_BUCKET_NAME/"
rm "${FETCHER_FUNCTION_NAME}.zip"
echo "'$FETCHER_FUNCTION_NAME' packaged and uploaded to S3."

# 4. Create or Update CostInsight-CloudWatchFetcher Lambda function
echo "Step 4/6: Creating/Updating Lambda function '$FETCHER_FUNCTION_NAME'..."
if aws lambda get-function --function-name "$FETCHER_FUNCTION_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "Function '$FETCHER_FUNCTION_NAME' already exists. Updating code..."
    aws lambda update-function-code --function-name "$FETCHER_FUNCTION_NAME" --s3-bucket "$S3_BUCKET_NAME" --s3-key "${FETCHER_FUNCTION_NAME}.zip" --region "$AWS_REGION" --publish
else
    echo "Creating new function '$FETCHER_FUNCTION_NAME'..."
    aws lambda create-function \
      --function-name "$FETCHER_FUNCTION_NAME" \
      --runtime "nodejs18.x" \
      --role "$ROLE_ARN" \
      --handler "cloudwatch-fetcher.handler" \
      --code "S3Bucket=$S3_BUCKET_NAME,S3Key=${FETCHER_FUNCTION_NAME}.zip" \
      --timeout 30 \
      --memory-size 256 \
      --region "$AWS_REGION" \
      --publish
fi

# 5. Package and Upload CostInsight-AutoShutdown Lambda
echo "Step 5/6: Packaging and uploading '$SHUTDOWN_FUNCTION_NAME'..."
zip -j "${SHUTDOWN_FUNCTION_NAME}.zip" "$SHUTDOWN_LAMBDA_PATH"
aws s3 cp "${SHUTDOWN_FUNCTION_NAME}.zip" "s3://$S3_BUCKET_NAME/"
rm "${SHUTDOWN_FUNCTION_NAME}.zip"
echo "'$SHUTDOWN_FUNCTION_NAME' packaged and uploaded to S3."

# 6. Create or Update CostInsight-AutoShutdown Lambda function
echo "Step 6/6: Creating/Updating Lambda function '$SHUTDOWN_FUNCTION_NAME'..."
if aws lambda get-function --function-name "$SHUTDOWN_FUNCTION_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "Function '$SHUTDOWN_FUNCTION_NAME' already exists. Updating code..."
    aws lambda update-function-code --function-name "$SHUTDOWN_FUNCTION_NAME" --s3-bucket "$S3_BUCKET_NAME" --s3-key "${SHUTDOWN_FUNCTION_NAME}.zip" --region "$AWS_REGION" --publish
else
    echo "Creating new function '$SHUTDOWN_FUNCTION_NAME'..."
    aws lambda create-function \
      --function-name "$SHUTDOWN_FUNCTION_NAME" \
      --runtime "nodejs18.x" \
      --role "$ROLE_ARN" \
      --handler "instance-auto-shutdown.handler" \
      --code "S3Bucket=$S3_BUCKET_NAME,S3Key=${SHUTDOWN_FUNCTION_NAME}.zip" \
      --timeout 15 \
      --memory-size 128 \
      --region "$AWS_REGION" \
      --publish
fi

echo "========================================================"
echo "✅ Deployment Successful!"
echo "========================================================"
echo "Summary:"
echo " - S3 Bucket: s3://$S3_BUCKET_NAME"
echo " - IAM Role: $IAM_ROLE_NAME"
echo " - Lambda Fetcher: $FETCHER_FUNCTION_NAME"
echo " - Lambda Shutdown: $SHUTDOWN_FUNCTION_NAME"
echo "Don't forget to configure the function URLs or API Gateway triggers as needed."
echo "Remember to replace the placeholder S3_BUCKET_NAME in the script for future runs."
