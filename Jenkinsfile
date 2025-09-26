pipeline {
    agent any

    environment {
        PROJECT_ID = 'springbootapp-gke'
        REPO = 'springboot-app'
        IMAGE_NAME = "us-central1-docker.pkg.dev/springbootapp-gke/springboot-app/springboot-app"
        IMAGE_TAG = 'latest'
        REGION = 'us-central1'
        ZONE = 'us-central1-a'
        CLUSTER_NAME = 'gke-cluster'
		PATH = "/home/murtale_prashant/google-cloud-sdk/bin:$PATH"
    }

    stages {
        stage('Checkout') {
            steps {
                git(
                    branch: 'main',
                    credentialsId: 'github-ssh-cred',
                    url: 'git@github.com:PrashantMurtale/CategoryProduct.git'
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

        stage('Docker Auth') {
            steps {
                withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        gcloud auth configure-docker ${REGION}-docker.pkg.dev -q
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build -t us-central1-docker.pkg.dev/springbootapp-gke/springboot-app/springboot-app:latest .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                    echo "Pushing Docker image to GCP Artifact Registry..."
					docker push us-central1-docker.pkg.dev/springbootapp-gke/springboot-app/springboot-app:latest
                '''
            }
        }

        stage('Deploy to GKE') {
            steps {
                withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GCP_KEY')]) {
                    sh '''
						export PATH=/home/murtale_prashant/google-cloud-sdk/bin:$PATH
                        gcloud auth activate-service-account --key-file=$GCP_KEY
                        gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID
                        echo "Applying Kubernetes manifests..."
                        kubectl apply -f k8s/mysqlspringdeployment.yaml --validate=false
                    '''
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