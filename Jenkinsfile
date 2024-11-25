#!groovy
import groovy.json.JsonOutput

pipeline {
    agent any
    stages {
         stage('Clone repository') {
            steps {
                script{
                checkout scm
                }
            }
        }

        stage('Build') {
            steps {
                script{
                  app = docker.build("nodejs_app")
                }
            }
        }
        stage('Unit Tests') {
            steps {
                script{
                    docker.build("test:latest","--target tests .")
                }
            }
        }
        stage('Publish') {
            steps {
                input 'Do you want publish an image?'
                script{
                    docker.withRegistry('https://917097974384.dkr.ecr.eu-north-1.amazonaws.com', 'ecr:eu-north-1:aws-credentials') {
                    app.push("${env.BUILD_NUMBER}")
                    app.push("latest")
                    }
                }
            }
        }
        stage('Deploy') {
            steps {
                script {
                    withCredentials([file(credentialsId: "k8s-config", variable: 'K8S_CONFIG')]) {
                       sh 'cat $K8S_CONFIG > config'
                    }
                    sh 'export KUBECONFIG=`pwd`/config'
                    sh 'curl -fsSLO https://get.helm.sh/helm-v3.16.3-linux-amd64.tar.gz'
                    sh 'tar xzvf helm-v3.16.3-linux-amd64.tar.gz'
                    sh './linux-amd64/helm upgrade --install my-app ./.cicd/helm --namespace default --set image.name=917097974384.dkr.ecr.eu-north-1.amazonaws.com/nodejs_app,image.tag=latest --atomic'
                }

            }
        }
    }
    post {
        success {
            echo ' ===> success'
            notifyChat(":white_check_mark: Successful deploy")
        }

        failure {
            echo ' ===> failure'
            notifyChat(":x: Failed build")
        }
    }
}

void notifyChat(String message, String channel = "deploy") {
    withCredentials([string(credentialsId: 'notify-webhook-url', variable: 'NOTIFY_WEBHOOK_URL')]) {
        String text = "**${message}**\r\n${env.JOB_NAME} - ${RUN_DISPLAY_URL}"
        String payload = JsonOutput.toJson([
            text: text,
            channel: channel,
            username: 'jenkins',
            icon_emoji: ':jenkins:'
        ])
        // … + '${NOTIFY_WEBHOOK_URL}' — to avoid warning: «A secret was passed to "sh" using Groovy String interpolation, which is insecure.»
        def notify_response = sh (script: "curl --connect-timeout 5 --max-time 5 -X POST --data-urlencode \'payload=${payload}\' " + '${NOTIFY_WEBHOOK_URL} || true', returnStdout: true)
        echo " ===> notify_response: ${notify_response}"
    }
}
