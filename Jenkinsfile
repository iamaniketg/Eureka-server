pipeline {
    agent any

    environment {
        PROJECT_ID = 'thinking-anthem-471805-a1'  // Your actual project ID
        IMAGE_NAME = "captainaniii/eureka-server"  // Your Docker Hub repo/image
        REGION = 'asia-southeast1'  // Your region
        ZONE = 'asia-southeast1-a'  // Your cluster zone
        CLUSTER_NAME = 'cluster-1'  // Your actual cluster name
        K8S_DEPLOYMENT = 'springboot-app'  // Assume your deployment name; change if different
        K8S_CONTAINER = 'springboot-app'  // Assume your container name; change if different
        // K8S_NAMESPACE = 'default'  // Uncomment and set if using a specific namespace
        MAVEN_HOME = tool name: 'maven', type: 'hudson.tasks.Maven$MavenInstallation'
        DOCKER_HOME = tool name: 'docker', type: 'org.jenkinsci.plugins.docker.commons.tools.DockerTool'
        PATH = "${MAVEN_HOME}/bin:${DOCKER_HOME}/bin:${env.PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                git(
                    branch: 'main',
                    credentialsId: 'github-credentials',  // Your token-based credential ID
                    url: 'https://github.com/PrashantMurtale/CategoryProduct.git'  // Changed to HTTPS
                )
            }
        }

        stage('Set up GCP') {
            steps {
                withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        sh '''
                            echo "Authenticating with GCP..."
                            gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                            gcloud config set project $PROJECT_ID
                        '''
                    }
                }
            }
        }

        stage('Build with Maven') {
            steps {
                sh '''
                    echo "Building Spring Boot JAR..."
                    mvn clean package -DskipTests
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.IMAGE_TAG = "${BUILD_NUMBER}"
                    def fullImage = "${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker build -t ${fullImage} ."
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    script {
                        def fullImage = "${IMAGE_NAME}:${IMAGE_TAG}"
                        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                        sh "docker push ${fullImage}"
                    }
                }
            }
        }

        stage('Deploy to GKE') {
            steps {
                withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        def fullImage = "${IMAGE_NAME}:${IMAGE_TAG}"
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
                        sh "gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID}"
                        // If you need to apply initial YAML once: sh "kubectl apply -f k8s/mysqlspringdeployment.yaml"
                        sh "kubectl set image deployment/${K8S_DEPLOYMENT} ${K8S_CONTAINER}=${fullImage} --record"  // Add -n ${K8S_NAMESPACE} if using namespace
                        sh "kubectl rollout status deployment/${K8S_DEPLOYMENT} --timeout=5m"  // Add -n ${K8S_NAMESPACE} if needed
                    }
                }
            }
            post {
                success {
                    echo 'Deployment successful!'
                }
                failure {
                    echo 'Deployment failed! Rolling back...'
                    withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
                        sh "gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID}"
                        sh "kubectl rollout undo deployment/${K8S_DEPLOYMENT}"  // Add -n ${K8S_NAMESPACE} if needed
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'echo "Pipeline finished - cleaning up..."'
        }
        success {
            sh 'echo "✅ Deployment successful!"'
        }
        failure {
            sh 'echo "❌ Deployment failed!"'
        }
    }
}