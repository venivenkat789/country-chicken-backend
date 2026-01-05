pipeline {
    agent any
    
    stages {
        stage('Step 1: Get Code') {
            steps {
                echo 'Getting code from Git...'
                checkout scm
            }
        }
        
        stage('Step 2: Build') {
            steps {
                echo 'Building with Maven...'
                sh 'mvn clean compile'
            }
        }
        
        stage('Step 3: Test') {
            steps {
                echo 'Running tests...'
                sh 'mvn test'
            }
        }
        
        stage('Step 4: Create JAR') {
            steps {
                echo 'Creating JAR file...'
                sh 'mvn package -DskipTests'
                
                script {
                    // Show what was created
                    sh 'ls -la target/*.jar'
                }
            }
        }
        
        stage('Step 5: Save JAR') {
            steps {
                echo 'Saving JAR file...'
                archiveArtifacts 'target/*.jar'
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline done!'
        }
    }
}