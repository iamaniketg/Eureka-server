pipeline {
    agent any
    environment {
        REGISTRY    = "docker.io/captainaniii" // change this
        IMAGE_NAME  = "springboot-app"
        KUBECONFIG  = credentials('kubeconfig') // kubeconfig file from Jenkins credentials
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
                    env.IMAGE_TAG = "${BUILD_NUMBER}"  // incremented image tag
                    def fullImage = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker build -t ${fullImage} ."
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
        success {
            script {
                def fullImage = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    sh "docker push ${fullImage}"
                }
            }
        }
        failure {
            script {
                def deployment = "myapp-deployment"
                sh "kubectl --kubeconfig $KUBECONFIG rollout undo deployment/${deployment}"
            }
        }
    }
}
