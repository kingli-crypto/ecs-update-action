#!/bin/bash
TASK_REVISION=$1
ECR_IMAGE=$2
ECS_CLUSTER=$3
SERVICE_NAME=$4

TASK_FAMILY=$(aws ecs describe-services --services worker-ethereum --cluster STG-SECBB-BIPS-ADDSVC --query "services[0].taskDefinition" --output text | sed  "s/..*task-definition\/\(..*\):..*/\1/")
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
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