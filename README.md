# Jenkins CI/CD for Maven and Dockerized Java Applications ☕🐳

This repository contains **Jenkins CI/CD automation scripts** for:
- **Windows-based Maven applications** (using NSSM for service management)
- **Linux-based Dockerized applications** (using Docker Compose for deployment)

Each environment follows best practices for reliability, rollback, and dynamic configuration.

---

## ⚙️ Windows CI/CD for Maven Projects

### 🧰 Prerequisites
- Jenkins installed on Windows
- Java (JDK 17+)
- [NSSM](https://nssm.cc/download) installed (Non-Sucking Service Manager)
- The Maven project successfully builds a `.jar` file

### 🏗️ Build + Deployment Script (`deploy_maven_service.bat`)

This batch script automates:
1. Moving the built JAR file from Jenkins workspace
2. Stopping any existing service
3. Reinstalling it using NSSM
4. Starting it with proper logging

---

### 🐧 Linux CI/CD for Dockerized Applications
🧰 Prerequisites

Jenkins agent or server on Linux
Docker & Docker Compose installed
Docker Hub account credentials stored in Jenkins
A valid Dockerfile in your project repo

### 🏗️ Build + Deploy Script (docker_build_deploy.sh)

This script:

Builds Docker image using commit hash as tag
Pushes image to Docker Hub
Backs up the existing docker-compose.yml
Updates image tag and redeploys using Docker Compose
Skips build if same commit is already deployed
