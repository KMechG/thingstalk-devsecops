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
  





    }
}