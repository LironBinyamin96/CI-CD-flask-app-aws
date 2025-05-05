# Flask AWS App

This project is a simple backend application built with **Flask**, deployed as a **Docker image** via **Jenkins** to **AWS**.

The app connects to:
- **AWS RDS (MySQL)** for database operations  
- **AWS Secrets Manager** to securely fetch database credentials  
- Uses **Flask-CORS** to support communication with a frontend

## 🧩 Features

- RESTful API written in Python using Flask  
- Reads secrets securely using boto3 and Secrets Manager  
- Connects to an RDS database (MySQL)  
- Dockerized for portability  
- Integrated into CI/CD pipeline using Jenkins  
- Deployable to EC2 via Docker or ECS

## 🚀 Running Locally (with Docker)

```bash
docker build -t flask-aws-app .
docker run -p 5000:5000 flask-aws-app

 ## 🛠️ Jenkins CI/CD Pipeline (example steps)

Clone code from GitHub

Build Docker image using Dockerfile

Push to container registry (ECR or Docker Hub)

