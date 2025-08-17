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
        stage("Hello"){
            steps{
                script{
                    hello()
                }
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
                echo "Docker image build successfully"
            }
        }

        stage("Run Migrations") {
            steps {
                echo "🗄️ Running Django migrations..."
                sh "docker-compose -f $DOCKER_COMPOSE_FILE run --rm web python manage.py migrate"
            }
        }

        stage("Run Tests") {
            steps {
                echo "🧪 Running Django tests..."
                script {
                    def testResult = sh(
                        script: "docker-compose -f $DOCKER_COMPOSE_FILE run --rm web python manage.py test",
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
                        docker login -u ${dockerHubUser} -p ${dockerHubPass}
                        docker image tag $IMAGE_NAME ${dockerHubUser}/notes-app:latest
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
                    docker-compose -f $DOCKER_COMPOSE_FILE pull
                    docker-compose -f $DOCKER_COMPOSE_FILE up -d
                    docker-compose -f $DOCKER_COMPOSE_FILE logs --tail=100 web
                """
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up unused Docker resources..."
            sh 'docker image prune -f || true'
            sh 'docker container prune -f || true'
            sh 'docker volume prune -f || true'
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs for errors."
        }
    }
}
