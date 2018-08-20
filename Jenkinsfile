pipeline {
    agent {
        docker { image 'r-base'} 
  }
    stages {
        stage('testing pipeline'){
            steps{
                echo 'test1'
                sh 'mkdir from-jenkins'
                sh 'touch from-jenkins/test.txt'
                }
            }
        stage('Build'){
            steps{
                echo "Build"
                }
            }
        }
    }
