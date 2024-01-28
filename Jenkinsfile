def registry = 'https://<registry>.jfrog.io'
def imageName = '<jfrog-docker-image-path>'
def version   = '2.1.5'
pipeline {
    agent { label 'maven' }
environment { PATH = "/opt/apache-maven-3.9.6/bin:$PATH" }

    stages {
        stage('Build') {
            steps {
                sh 'mvn clean deploy -Dmaven.test.skip=true'
            }
        }
        stage("MVN test"){
            steps{
                sh 'mvn surefire-report:report'
            }
        }


      stage('SonarQube analysis') {
        environment {
            scannerHome = tool 'sonar-scanner'
            }
        steps {
            withSonarQubeEnv('sonar-server') {
                sh "${scannerHome}/bin/sonar-scanner"
                    }
                }
        }

        // Push the Maven build to Jfrog artifact
        stage("Jar Publish") {
        steps {
            script {
                     def server = Artifactory.newServer url:registry+"/artifactory" ,  credentialsId:"jfrog-jenkins"
                     def properties = "buildid=${env.BUILD_ID},commitid=${GIT_COMMIT}";
                     def uploadSpec = """{
                          "files": [
                            {
                              "pattern": "jarstaging/(*)",
                              "target": "project-maven/{1}",
                              "flat": "false",
                              "props" : "${properties}",
                              "exclusions": [ "*.sha1", "*.md5"]
                            }
                         ]
                     }"""
                     def buildInfo = server.upload(uploadSpec)
                     buildInfo.env.collect()
                     server.publishBuildInfo(buildInfo)

                     }
                }
            }


        stage("Docker Build") {
         steps {
         script {
            app = docker.build(imageName+":" + version)
            }
         }
        }

     // Jfrog cred should be set at jenkins
     stage("Docker publish") {
        steps {
            script {
            docker.withRegistry(registry, "jfrog-jenkins") {
                app.push()
            }
            }
        }
     }
     // This tgz file should generated at jenkins server where it is acting as control server for kubernetes cluster
     stage("K8s deploy") {
       steps {
          script {
          sh "helm install project project.0.1.tgz"
          }
       }
     }
    }
}
