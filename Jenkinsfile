pipeline {
  agent any

  environment {
      deploymentName = "devsecops"
      containerName = "devsecops-container"
      serviceName = "devsecops-svc"
      imageName = "sarmisthajena/numeric-app:${GIT_COMMIT}"
      applicationURL="http://devsecops-demo.eastus.cloudapp.azure.com"
      applicationURI="/increment/99"
    }

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar'
            }
        }
      stage('Unit Test') {
            steps {
              sh "mvn test"
            }
      }
      stage('Mutation Tests - PIT') {
            steps {
              sh "mvn org.pitest:pitest-maven:mutationCoverage"
            }
      }
      /* stage('SonarQube - SAST') {
            steps {
                withSonarQubeEnv('SonarQube'){
                  sh "mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=devsecops-numeric-application \
                        -Dsonar.host.url=http://devsecops-demo.southindia.cloudapp.azure.com:9000"// \
                        //-Dsonar.login=sqp_ce14eeaaeac98f61beb4c595ca87bdfb639a9a7f"
                }
                timeout(time: 2, unit: 'MINUTES'){
                    script {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
          } */
      stage('Vulnerability Scan - Docker') {
            steps {
              parallel(
                 "Dependency Scan": {
                    sh "mvn dependency-check:check"
                 },
                 "Trivy Scan": {
                    sh "bash trivy-docker-image-scan.sh"
                 },
                 "OPA Conftest": {
                    sh "/usr/local/bin/conftest test --policy opa-docker-security.rego Dockerfile"
                 }
              )
            }
      }
      stage('Docker Build and Push') {
            steps {
              withDockerRegistry([credentialsId: "docker-hub", url: ""]){
              sh 'printenv'
              sh 'sudo docker build -t sarmisthajena/numeric-app:""$GIT_COMMIT"" .'
              //sh 'docker tag siddharth67/numeric-app:""$GIT_COMMIT"" sarmisthajena/numeric-app:""$GIT_COMMIT""'
              sh 'docker push sarmisthajena/numeric-app:""$GIT_COMMIT""'
              }
            }
      }
      stage('Vulnerability Scan - Kubernetes') {
            steps {
              parallel(
                "OPA Scan": {
                   sh '/usr/local/bin/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
                },
                "Kubesec Scan": {
                   sh "bash kubesec-scan.sh"
                }
              )
            }
          }
      stage('Kubernetes Deployment - DEV') {
            steps {
                parallel(
                  "Deployment": {
                    withKubeConfig([credentialsId: "kubeconfig"]){
                  /* sh "sed -i 's#replace#sarmisthajena/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
                  sh "kubectl apply -f k8s_deployment_service.yaml" */
                  sh "bash k8s-deployment.sh"
                  }
                },
                "Rollout Status":{
                  withKubeConfig([credentialsId: "kubeconfig"]){
                  sh "bash k8s-deployment-rollout-status.sh"
                  }
                }
                )
            }
      }
  }
   post {
          always{
              junit 'target/surefire-reports/*.xml'
              jacoco execPattern: 'target/jacoco.exec'
              pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
              dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
          }
   }
}