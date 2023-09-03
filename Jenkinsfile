pipeline {
  agent any

  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "karydock/thingstalk-app:${GIT_COMMIT}"
    applicationURL="http://devsecops-demo.eastus.cloudapp.azure.com"
    applicationURI="/increment/99"
  }

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
            sh " mvn clean verify sonar:sonar      -Dsonar.projectKey=thingstalk-devsecops      -Dsonar.projectName='thingstalk-devsecops'   -Dsonar.host.url=http://devsecopsthingstalk.eastus.cloudapp.azure.com:9000  "
          }
          timeout(time: 2, unit: 'MINUTES') {
            script {
              waitForQualityGate abortPipeline: true
            }
          }
        }
    }
      
     
         stage('Vulnerability Scan - Docker') {
      steps {
        parallel(
        	"Dependency Scan": {
        		sh "mvn dependency-check:check"
			},
			"Trivy Scan":{
				sh "bash trivy-docker-image-scan.sh"
			 },
			"OPA Conftest":{
				sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
			}   	
      	)
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


      stage('Vulnerability Scan - Kubernetes') {
        steps {
          parallel(
            "OPA Scan": {
              sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
            },
            "Kubesec Scan": {
              sh "bash kubesec-scan.sh"
            }
            //,
            // "Trivy Scan": {
            //   sh "bash trivy-k8s-scan.sh"
            // }
          )
        }
    }




       stage('OWASP ZAP - DAST') {
      steps {
        withKubeConfig([credentialsId: 'kubeconfig']) {
          sh 'bash zap.sh'
        }
      }
    }



      stage('K8S Deployment - DEV') {
          steps {
            parallel(
              "Deployment": {
                withKubeConfig([credentialsId: 'kubeconfig']) {
                  sh "bash k8s-deployment.sh"
                }
              },
              "Rollout Status": {
                withKubeConfig([credentialsId: 'kubeconfig']) {
                  sh "bash k8s-deployment-rollout-status.sh"
                }
              }
            )
          }
      }

  }

    post {
       always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
          //pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
          dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
          publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report'])
       }
    }





  



    }
