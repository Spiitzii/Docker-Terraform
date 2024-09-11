#!/bin/bash

#Install Docker
yum update -y
yum install -y docker
yum install -y git

#Start Docker
service docker start
systemctl enable docker

#Install Docker-Compose
curl -L "https://github.com/docker/compose/releases/download/v2.0.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone the Feedback-App repository
git clone https://github.com/atamankina/feedback-app.git /home/ec2-user/feedback-app

# Change directory to the feedback-app folder
cd /home/ec2-user/feedback-app

# Run Docker Compose to start the Feedback-App containers
sudo docker-compose up -d

# Verify that the containers are running
sudo docker ps

# Output feedback to Cloud-Init logs for confirmation
echo "Feedback-App has been successfully deployed."
