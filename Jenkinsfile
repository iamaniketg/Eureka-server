pipeline {
    agent any

    environment {
        REGISTRY   = "docker.io/captainaniii"
        IMAGE_NAME = "springboot-app"
        MAVEN_HOME = tool name: 'maven', type: 'hudson.tasks.Maven$MavenInstallation'
        DOCKER_HOME = tool name: 'docker', type: 'org.jenkinsci.plugins.docker.commons.tools.DockerTool'
        PATH = "${MAVEN_HOME}/bin:${DOCKER_HOME}/bin:${env.PATH}"
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

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    script {
                        def fullImage = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                        sh "docker push ${fullImage}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    script {
                        def fullImage = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                        def deployment = "myapp-deployment"
                        def containerName = "myapp"

                        sh 'kubectl --kubeconfig=$KUBECONFIG_FILE set image deployment/myapp-deployment myapp=' + fullImage + ' --record'
                        sh 'kubectl --kubeconfig=$KUBECONFIG_FILE rollout status deployment/myapp-deployment'
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Build, Docker push, and Kubernetes deployment completed successfully!"
        }
        failure {
            script {
                node {
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                        echo "Deployment failed! Rolling back..."
                        sh 'kubectl --kubeconfig=$KUBECONFIG_FILE rollout undo deployment/myapp-deployment'
                    }
                }
            }
        }
    }
}
