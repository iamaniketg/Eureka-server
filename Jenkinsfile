pipeline {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17' // Maven + JDK 17
            args  '-v /var/run/docker.sock:/var/run/docker.sock' // mount docker
        }
    }
    environment {
        REGISTRY    = "docker.io/captainaniii"
        IMAGE_NAME  = "springboot-app"
        KUBECONFIG  = credentials('kubeconfig')
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/iamaniketg/Eureka-server.git'
            }
        }
        stage('Build & Test') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    env.IMAGE_TAG = "${BUILD_NUMBER}"
                    def fullImage = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker build -t ${fullImage} ."
                }
            }
        }
        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    sh "docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    def fullImage = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    def deployment = "myapp-deployment"
                    def containerName = "myapp"

                    sh "kubectl --kubeconfig $KUBECONFIG set image deployment/${deployment} ${containerName}=${fullImage} --record"
                    sh "kubectl --kubeconfig $KUBECONFIG rollout status deployment/${deployment}"
                }
            }
        }
    }
    post {
        failure {
            script {
                sh "kubectl --kubeconfig $KUBECONFIG rollout undo deployment/myapp-deployment"
            }
        }
    }
}
