#!/bin/bash
set -e

# Script parameters
IMAGE_NAME=$1
TAG=$2
EC2_HOST=$3
EC2_USER=$4
ENV_NAME=$5

echo "[$(date)] Starting deployment of image $IMAGE_NAME:$TAG to $EC2_HOST in $ENV_NAME" >> ~/deploy.log

# Replace dockerhub username and tag in .env.prod
sed -i "s/your_dockerhub_username/$(echo $IMAGE_NAME | cut -d '/' -f 1)/" .env.prod
sed -i "s/latest/$TAG/" .env.prod
sed -i "s/localhost,127.0.0.1/localhost,127.0.0.1,$EC2_HOST/" .env.prod

# Copy deployment files to EC2
scp -i ~/.ssh/deploy_key .env.prod $EC2_USER@$EC2_HOST:~/.env
scp -i ~/.ssh/deploy_key docker-compose.yml $EC2_USER@$EC2_HOST:~/docker-compose.yml

# Run deployment on EC2
ssh -i ~/.ssh/deploy_key $EC2_USER@$EC2_HOST <<EOF
  set -e
  echo "[$(date)] Running docker pull and compose up on EC2..." >> ~/deploy.log

  # Log in to Docker (optional if already authenticated)
  docker login -u $IMAGE_NAME -p $DOCKER_PASSWORD || true

  # Pull image explicitly
  docker pull $IMAGE_NAME:$TAG

  # Stop and remove existing container if exists
  docker compose down || true

  # Launch
  docker compose --env-file .env up -d

  echo "[$(date)] Deployment done" >> ~/deploy.log
EOF

echo "[$(date)] Deployment script completed." >> ~/deploy.log
