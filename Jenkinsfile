pipeline {
  agent any

  environment {
    deploymentName = "tb-node"
    containerName = "tb-node-container"
    serviceName = "tb-node-svc"
    imageName = "karydock/thingstalk-app:${GIT_COMMIT}"
    //imageName = "docker.io/karydock/thingstalk-app"
    applicationURL="http://20.49.135.102:8080"
    applicationURI="increment/99"
    COSIGN_PASSWORD=credentials('cosign-password')
    COSIGN_PRIVATE_KEY=credentials('cosign-private-key')
     COSIGN_PUBLIC_KEY=credentials('cosign-public-key')
      IMAGE_VERSION='3.5.0'
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
            sh " mvn clean verify sonar:sonar    -Dsonar.projectKey=thingstalk-devsecops      -Dsonar.projectName='thingstalk-devsecops'   -Dsonar.host.url=http://devsecopscicdthingstalk.eastus.cloudapp.azure.com:9000"
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
				sh 'sudo docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
			}   	
      	)
      }
    }







      stage('Docker Build and Push') {
        steps {
          withDockerRegistry([credentialsId: "dockerhub", url: ""]) {
            sh 'printenv'
            sh 'sudo docker build -t $imageName .'
            sh 'docker push $imageName'
          }
        }
      }
      stage('sign the container image') {
      steps {
        withDockerRegistry([credentialsId: "dockerhub", url: ""]) {
        sh 'cosign version'
        sh 'cosign sign --key $COSIGN_PRIVATE_KEY $imageName -y'
        }
      }
    }
     stage('verify the container image') {
      steps {
        withDockerRegistry([credentialsId: "dockerhub", url: ""]) {
        sh 'cosign version'
        sh 'cosign verify --key $COSIGN_PUBLIC_KEY $imageName '
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
       
      stage('Integration Tests - DEV') {
        steps {
          script {
            try {
              withKubeConfig([credentialsId: 'kubeconfig']) {
                sh "bash integration-test.sh"
              }
            } catch (e) {
              withKubeConfig([credentialsId: 'kubeconfig']) {
                sh "kubectl -n default rollout undo deploy ${deploymentName}"
              }
              throw e
            }
          }
        }
    }





      stage('OWASP ZAP - DAST') {
        steps {
          withKubeConfig([credentialsId: 'kubeconfig']) {
            sh 'bash zap.sh'
          }
        }
  } 
        stage('Prompte to PROD?') {
      steps {
        timeout(time: 2, unit: 'DAYS') {
          input 'Do you want to Approve the Deployment to Production Environment/Namespace?'
        }
      }
    }

      stage('K8S CIS Benchmark') {
        steps {
          script {

            parallel(
              "Master": {
                sh "bash cis-master.sh"
              },
              "Etcd": {
                sh "bash cis-etcd.sh"
              },
              "Kubelet": {
                sh "bash cis-kubelet.sh"
              }
            )

          }
        }
      }

      stage('K8S Deployment - PROD') {
        steps {
          parallel(
            "Deployment": {
              withKubeConfig([credentialsId: 'kubeconfig']) {
                sh "sed -i 's#replace#${imageName}#g' k8s_PROD-deployment_service.yaml"
                sh "kubectl -n prod apply -f k8s_PROD-deployment_service.yaml"
              }
            },
            "Rollout Status": {
              withKubeConfig([credentialsId: 'kubeconfig']) {
                sh "bash k8s-PROD-deployment-rollout-status.sh"
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
