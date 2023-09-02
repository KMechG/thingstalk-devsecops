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

    

   

          stage('SonarQube - SAST') {
      steps {
        withSonarQubeEnv('SonarQube') {
          sh " mvn clean verify sonar:sonar \
              -Dsonar.projectKey=thingstalk-devsecops \
              -Dsonar.projectName='thingstalk-devsecops' \
              -Dsonar.host.url=http://devsecopsthingstalk.eastus.cloudapp.azure.com:9000 \
              -Dsonar.token=sqp_69f520b397c0167372ef6aa2f7119b761e87494e"
        }
        // timeout(time: 2, unit: 'MINUTES') {
        //   script {
        //     waitForQualityGate abortPipeline: true
        //   }
        // }
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



        stage('kubernetes deployment - DEV') {
        steps {
          withKubeConfig([credentialsId: "kubeconfig"]) {
            
            sh "sed -i 's#replace#karydock/thingstalk-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
            sh  "kubectl apply -f k8s_deployment_service.yaml"
          }
        }
     }



  

      }

    }
