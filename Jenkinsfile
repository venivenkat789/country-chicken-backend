pipeline {
    agent any

    tools {
        maven 'maven3.9.12'
        jdk 'java17'
    }

    environment {
        APP_NAME        = 'country-chicken-backend'
        NEXUS_URL       = '3.89.152.50:8081'
        MAVEN_REPO      = 'maven-releases'
        DOCKER_REPO     = 'docker-releases'
        GROUP_ID        = 'com.countrychicken'
        VERSION         = "${BUILD_NUMBER}"
        JAR_NAME        = 'country-chicken-backend-1.0.0.jar'
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/srikanth78933/country-chicken-backend.git'
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Upload JAR to Nexus') {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: "${NEXUS_URL}",
                    groupId: "${GROUP_ID}",
                    version: "${VERSION}",
                    repository: "${MAVEN_REPO}",
                    credentialsId: 'nexus-credentials',
                    artifacts: [
                        [
                            artifactId: "${APP_NAME}",
                            classifier: '',
                            file: "target/${JAR_NAME}",
                            type: 'jar'
                        ]
                    ]
                )
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                  docker build \
                  -t ${NEXUS_URL}/${DOCKER_REPO}/${APP_NAME}:${VERSION} \
                  -t ${NEXUS_URL}/${DOCKER_REPO}/${APP_NAME}:latest .
                """
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-nexus-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                      echo ${DOCKER_PASS} | docker login ${NEXUS_URL} \
                      -u ${DOCKER_USER} --password-stdin

                      docker push ${NEXUS_URL}/${DOCKER_REPO}/${APP_NAME}:${VERSION}
                      docker push ${NEXUS_URL}/${DOCKER_REPO}/${APP_NAME}:latest

                      docker logout ${NEXUS_URL}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build & Push Successful"
        }

        failure {
            echo "❌ Build Failed"
        }

        always {
            sh 'docker system prune -f'
            cleanWs()
        }
    }
}
