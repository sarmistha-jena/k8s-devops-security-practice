pipeline {
  agent any

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
            post{
                always{
                    junit 'target/surefire-reports/*.xml'
                    jacoco execPattern: 'target/jacoco.exec'
                }
            }
      }
      stage('Mutation Tests - PIT') {
            steps {
              sh "mvn org.pitest:pitest-maven:mutationCoverage"
            }
            post {
              always {
                pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
              }
            }
      }
      stage('SonarQube - SAST') {
            steps {
              sh "mvn clean verify sonar:sonar \
                    -Dsonar.projectKey=devsecops-numeric-application \
                    -Dsonar.host.url=http://devsecops-demo.southindia.cloudapp.azure.com:9000 \
                    -Dsonar.login=sqp_ce14eeaaeac98f61beb4c595ca87bdfb639a9a7f"
            }
          }
      stage('Docker Build and Push') {
            steps {
              withDockerRegistry([credentialsId: "docker-hub", url: ""]){
              sh 'printenv'
              sh 'docker build -t sarmisthajena/numeric-app:""$GIT_COMMIT"" .'
              //sh 'docker tag siddharth67/numeric-app:""$GIT_COMMIT"" sarmisthajena/numeric-app:""$GIT_COMMIT""'
              sh 'docker push sarmisthajena/numeric-app:""$GIT_COMMIT""'
              }
            }
      }
      stage('Kubernetes Deployment - DEV') {
            steps {
              withKubeConfig([credentialsId: "kubeconfig"]){
              //sh "sed -i 's#replace#sarmisthajena/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
              sh "sed -i 's#replace#sarmisthajena/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
              sh "kubectl apply -f k8s_deployment_service.yaml"
              }
            }
      }
  }
}