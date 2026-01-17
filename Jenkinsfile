pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    tools {
        maven 'maven3.9.11'
        jdk 'java17'
    }

    environment {
        APP_NAME         = 'country-chicken-backend'

        NEXUS_MAVEN_URL  = '13.53.174.188:8081'
        NEXUS_DOCKER_URL = '13.53.174.188:8082'

        MAVEN_REPO       = 'maven-releases'
        DOCKER_REPO      = 'docker-releases'

        GROUP_ID         = 'com.countrychicken'
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/venivenkat789/country-chicken-backend.git'
            }
        }

        stage('Set Version') {
            steps {
                script {
                    def version = sh(
                        script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout",
                        returnStdout: true
                    ).trim()

                    if (!version) {
                        error "Version not found in pom.xml"
                    }

                    env.VERSION = version
                    env.JAR_NAME = "${APP_NAME}-${version}.jar"

                    echo "Version detected: ${env.VERSION}"
                }
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Verify JAR') {
            steps {
                sh "ls -lh target/${JAR_NAME}"
            }
        }

        stage('Upload JAR to Nexus') {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: "${NEXUS_MAVEN_URL}",
                    groupId: "${GROUP_ID}",
                    version: "${VERSION}",
                    repository: "${MAVEN_REPO}",
                    credentialsId: 'nexus-credentials',
                    artifacts: [[
                        artifactId: "${APP_NAME}",
                        classifier: '',
                        file: "target/${JAR_NAME}",
                        type: 'jar'
                    ]]
                )
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build \
                  -t ${NEXUS_DOCKER_URL}/${DOCKER_REPO}/${APP_NAME}:${VERSION} .
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-nexus-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                    echo "\$DOCKER_PASS" | docker login ${NEXUS_DOCKER_URL} \
                        -u "\$DOCKER_USER" --password-stdin

                    docker push ${NEXUS_DOCKER_URL}/${DOCKER_REPO}/${APP_NAME}:${VERSION}

                    docker logout ${NEXUS_DOCKER_URL}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Build & Push Successful"
        }
        failure {
            echo "Build Failed"
        }
        always {
            sh 'docker system prune -f'
            cleanWs()
        }
    }
}
