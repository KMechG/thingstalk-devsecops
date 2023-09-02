pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' ///test
            }
        } 

      stage('Unit Tests - JUnit and JaCoCo') {
            steps {
              sh "mvn test"
            }
            post {
              always{
                junit 'target/surefire-reports/*.xml'
                jacoco execPattern: 'target/jacoco.exec'
              }
            }
          }
      stage('Mutations Tests - PIT') {
        steps {
          sh "mvn org.pitest:pitest-maven:mutationCoverage"
        }
        post {
          always{
            pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
            
          }
        }
      }

      stage('Docker Build and Push') {
        steps {
          withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
            sh 'printenv'
            sh 'sudo docker build -t karydock/thingstalk-app:""$GIT_COMMIT"" .'
            sh 'docker push karydock/thingstalk-app:""$GIT_COMMIT""'
          }
        }
}



  





    }
}