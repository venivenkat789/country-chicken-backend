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
        NEXUS_MAVEN_URL  = 'http://13.53.174.188:8081'
        NEXUS_DOCKER_URL = '13.53.174.188:8082'

        MAVEN_REPO  = 'maven-releases'
        DOCKER_REPO = 'docker-releases'

        GROUP_ID = 'com.countrychicken'
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
                    env.VERSION = sh(
                        script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout",
                        returnStdout: true
                    ).trim()

                    env.JAR_NAME = "${APP_NAME}-${VERSION}"
                    echo "Version: ${VERSION}"
                }
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
                    nexusUrl: '13.53.174.188:8081',
                    groupId: "${GROUP_ID}",
                    version: "${VERSION}",
                    repository: "${MAVEN_REPO}",
                    credentialsId: 'nexus-credentials',
                    artifacts: [[
                        artifactId: "${APP_NAME}",
                        classifier: '',
                        file: "target/${APP_NAME}-${VERSION}.jar",
                        type: 'jar'
                    ]]
                )
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${NEXUS_DOCKER_URL}/${DOCKER_REPO}/${APP_NAME}:${VERSION} .
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
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f'
            cleanWs()
        }
    }
}
