@Library("Jenkins-shared-libraries") _
pipeline {
    agent { label 'binod' }

    environment {
        IMAGE_NAME = "notes-app:latest"
        DOCKER_COMPOSE_FILE = "docker-compose.yml"
    }

    options {
        skipDefaultCheckout true
        timestamps()
    }

    stages {
        stage("Cleanup Old Containers") {
            steps {
                echo "🧹 Stopping and removing old containers..."
                sh """
                    docker ps -aq --filter "name=web_cont" | xargs -r docker rm -f
                    docker ps -aq --filter "name=nginx_cont" | xargs -r docker rm -f
                    docker ps -aq --filter "name=db_cont" | xargs -r docker rm -f
                    docker network prune -f || true
                """
            }
        }

        stage("Checkout Code") {
            steps {
                script {
                    clone('https://github.com/KapilNampalliwar/django-notes-app.git', 'main')
                }
            }
        }

        stage("Build Docker Image") {
            steps {
                echo "🐳 Building Docker image..."
                sh "docker-compose -f $DOCKER_COMPOSE_FILE build --pull"
                echo "✅ Docker image built successfully"
            }
        }

        stage("Run Migrations") {
            steps {
                echo "🗄️ Running Django migrations..."
                sh "docker-compose run --rm web python manage.py migrate"
            }
        }

        stage("Run Tests") {
            steps {
                echo "🧪 Running Django tests..."
                script {
                    def testResult = sh(
                        script: "docker-compose run --rm web python manage.py test",
                        returnStatus: true
                    )
                    if (testResult != 0) {
                        error("⚠️ Tests failed. Aborting pipeline to prevent pushing broken image.")
                    } else {
                        echo "✅ All tests passed!"
                    }
                }
            }
        }

        stage("Push to DockerHub") {
            steps {
                echo "📤 Pushing Docker image to Docker Hub..."
                withCredentials([usernamePassword(credentialsId: "dockerHubCred", usernameVariable: "dockerHubUser", passwordVariable: "dockerHubPass")]) {
                    sh """
                        echo "$dockerHubPass" | docker login -u "$dockerHubUser" --password-stdin
                        docker tag $IMAGE_NAME ${dockerHubUser}/notes-app:latest
                        docker push ${dockerHubUser}/notes-app:latest
                    """
                }
            }
        }

        stage("Deploy with Docker Compose") {
            steps {
                echo "🚀 Deploying application..."
                sh """
                    docker-compose -f $DOCKER_COMPOSE_FILE down --remove-orphans
                    docker-compose -f $DOCKER_COMPOSE_FILE up -d
                    docker-compose -f $DOCKER_COMPOSE_FILE logs --tail=50 web
                """
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up unused Docker resources..."
            sh """
                docker image prune -f || true
                docker container prune -f || true
                docker volume prune -f || true
                docker network prune -f || true
            """
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs for errors."
        }
    }
}
