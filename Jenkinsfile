pipeline {
    agent any

    environment {
        PROJECT_ID = 'thinking-anthem-471805-a1'  // Your actual project ID
        IMAGE_NAME = "captainaniii/eureka-server"  // Your Docker Hub repo/image
        REGION = 'asia-southeast1'  // Your region
        ZONE = 'asia-southeast1-a'  // Your cluster zone
        CLUSTER_NAME = 'cluster-1'  // Your actual cluster name
        K8S_DEPLOYMENT = 'eureka-server'  // Your deployment name from YAML
        K8S_CONTAINER = 'eureka-server'  // Your container name from YAML (not used for apply, but kept for reference)
        // K8S_NAMESPACE = 'default'  // Uncomment and set if using a specific namespace, then add -n ${K8S_NAMESPACE} to kubectl commands
        MAVEN_HOME = tool name: 'maven'
        PATH = "${MAVEN_HOME}/bin:${env.PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                git(
                    branch: 'main',
                    credentialsId: 'github-credentials',  // Your token-based credential ID
                    url: 'https://github.com/iamaniketg/Eureka-server.git'  // Changed to HTTPS
                )
            }
        }

        stage('Install gcloud') {
            steps {
                script {
                    def gcloudPath = "${WORKSPACE}/google-cloud-sdk/bin/gcloud"
                    def kubectlPath = "${WORKSPACE}/google-cloud-sdk/bin/kubectl"
                    def gcloudInstalled = false
                    if (fileExists(gcloudPath)) {
                        try {
                            sh "${gcloudPath} --version"
                            gcloudInstalled = true
                        } catch (err) {
                            echo "Existing gcloud installation is invalid, will reinstall."
                        }
                    }
                    if (!gcloudInstalled) {
                        sh 'rm -rf google-cloud-sdk'
                        sh 'curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz'
                        sh 'tar -xf google-cloud-cli-linux-x86_64.tar.gz'
                        sh './google-cloud-sdk/install.sh --quiet --usage-reporting false --path-update false --bash-completion false'
                        sh "${WORKSPACE}/google-cloud-sdk/bin/gcloud components install kubectl --quiet"
                    }
                    sh "${gcloudPath} --version"  // Verify installation
                }
            }
        }

        stage('Set up GCP') {
            steps {
                withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        sh """
                            echo "Authenticating with GCP..."
                            ${WORKSPACE}/google-cloud-sdk/bin/gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS
                            ${WORKSPACE}/google-cloud-sdk/bin/gcloud config set project ${PROJECT_ID}
                        """
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
                    credentialsId: 'docker-cred',
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
                        sh "${WORKSPACE}/google-cloud-sdk/bin/gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS"
                        sh "${WORKSPACE}/google-cloud-sdk/bin/gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID}"
                        sh """
                            sed -i 's|image: .*|image: ${fullImage}|g' eureka-deployment.yaml
                            ${WORKSPACE}/google-cloud-sdk/bin/kubectl apply -f eureka-configmap.yaml
                            ${WORKSPACE}/google-cloud-sdk/bin/kubectl apply -f eureka-deployment.yaml
                            ${WORKSPACE}/google-cloud-sdk/bin/kubectl rollout status deployment/${K8S_DEPLOYMENT} --timeout=5m
                        """
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
                        sh "${WORKSPACE}/google-cloud-sdk/bin/gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS"
                        sh "${WORKSPACE}/google-cloud-sdk/bin/gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID}"
                        sh "${WORKSPACE}/google-cloud-sdk/bin/kubectl rollout undo deployment/${K8S_DEPLOYMENT}"
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