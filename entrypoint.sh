#!/bin/bash
TASK_FAMILY=$1
TASK_REVISION=$2
IMAGE_REPO_NAME=$3
CODEBUILD_RESOLVED_SOURCE_VERSION=$4
ECS_CLUSTER=$5
SERVICE_NAME=$6

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

ECR_IMAGE="$IMAGE_REPO_NAME:$CODEBUILD_RESOLVED_SOURCE_VERSION"
TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition "$TASK_FAMILY:$TASK_REVISION" --region "$AWS_DEFAULT_REGION")
NEW_TASK_DEFINTIION=$(echo $TASK_DEFINITION | jq --arg IMAGE "$ECR_IMAGE" '.taskDefinition | .containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities)')
NEW_TASK_INFO=$(aws ecs register-task-definition --region "$AWS_DEFAULT_REGION" --cli-input-json "$NEW_TASK_DEFINTIION")
NEW_REVISION=$(echo $NEW_TASK_INFO | jq '.taskDefinition.revision')
echo "::info::Created new task definion ${NEW_REVISION}"
aws ecs update-service --cluster ${ECS_CLUSTER} \
                       --service ${SERVICE_NAME} \
                       --task-definition ${TASK_FAMILY}:${NEW_REVISION}
echo "::info::Service updated successfully"

## https://github.com/aws/aws-cli/issues/3064#issuecomment-514214738