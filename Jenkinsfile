def deployToKubernetesEnv(kube_context, environment) {
  timeout(time: 10, unit: 'MINUTES') {
    script {
      env.GIT_REPO = gitRepo
      env.GIT_COMMIT = gitCommit
      env.ORG_COMPONENT_IMAGE_SHA = orgComponentImageSha
      env.APP_VERSION = readFile('VERSION')
      env.APP_RELEASE = appRelease
      env.KUBE_CONTEXT = kube_context
      env.ENVIRONMENT = environment
      env.TEAM_NAME = 'platform'
    }
    // withCredentials([file(credentialsId: 'kube-config', variable: 'KUBECONFIG')]) {
      sh '''
        helm upgrade --wait --install \
          --set orgComponentImageSha=${ORG_COMPONENT_IMAGE_SHA} \
          --set gitRepo=$(echo $GIT_REPO | awk -F / '{ print $5 }') \
          --set gitCommit=${GIT_COMMIT} \
          --set appVersion=${APP_VERSION} \
          --set appRelease=${APP_RELEASE} \
          --set environment=${ENVIRONMENT} \
          --values ./k8s/charts/values.yaml \
          --values ./k8s/charts/values-${ENVIRONMENT}.yaml \
          ${COMPONENT_NAME}-${ENVIRONMENT} ./k8s/charts/ \
          --namespace=${TEAM_NAME}-${ENVIRONMENT}
      '''
    // }
  }
}

pipeline {
  environment{
    ORG_DOCKER_REGISTRY = 'registry-proxy.lbg.eu-gb.mybluemix.net/modelmaker'
  }
  agent {
    kubernetes {
      label 'jenkins-mip-r-hello-world'
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-mip-r-hello-world
spec:
  securityContext:
    runAsUser: 0
  containers:
  - name: r
    image: registry-proxy.lbg.eu-gb.mybluemix.net/modelmaker/ds/rocker/packrat:3.5.0
    imagePullPolicy: IfNotPresent
    command:
    - cat
    tty: true
  - name: jnlp
    image: registry-proxy.lbg.eu-gb.mybluemix.net/modelmaker/jnlp-slave:latest
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: docker-sock
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
      type: Socket
"""
    }
  }

  stages {
    stage ('Prepare') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          container('jnlp') {
            script {
              env.COMPONENT_NAME = 'mip-r-hello-world'

              // hipchatSend color: 'PURPLE', credentialId: 'hipchat', message: '$JOB_NAME <a href="$BUILD_URL">Build #$BUILD_NUMBER</a> building $HIPCHAT_CHANGES_OR_CAUSE', notify: true, room: "$COMPONENT_NAME", sendAs: '', server: '', textFormat: false, v2enabled: true

              // if (currentBuild.rawBuild.getCause(hudson.triggers.TimerTrigger.TimerTriggerCause)) {
              //   env.TIMER_CAUSE = true
              // }
            }

            sh '''
              echo $(git remote get-url origin) > GIT_REPO
              echo $(git rev-parse --verify HEAD) > GIT_COMMIT
              echo $(cat VERSION)-$(git rev-parse --short --verify HEAD) > RELEASE
            '''
            script {
              gitRepo = readFile('GIT_REPO')
              gitCommit = readFile('GIT_COMMIT')
              appRelease = readFile('RELEASE')
            }
          }
        }
      }
    }

    

    stage('Generate Model generator package') {
      steps {
        container('r') {
          script {
              env.COMPONENT_NAME = 'mip-r-hello-world-model'
          }
          sh '''
            Rscript -e "devtools::build()"
          '''
        }
      }
    }
    stage('Check style') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          container('jnlp') {
            sh '''
              echo "Check style"
              Rscript -e 'lintr::lint_package()'
            '''
          }
        }
      }
    }

    stage('Push package to Nexus') {
      steps{
        container('jnlp'){
          withCredentials([usernameColonPassword(credentialsId: 'nexus-3-credentials', variable: 'NEXUS_AUTH')]) {
            sh '''
              curl -u "${NEXUS_AUTH}" --upload-file sampleModelGenerator_0.1.0.tar.gz http://nexus.sandbox.extranet.group/nexus3/repository/r-hosted/src/contrib/sampleModelGenerator_0.1.0.tar.gz"
            '''
          }
        }
      }
    }

    stage('Build') {
      steps {
        container('jnlp') {
          sh '''
              DOCKER_REGISTRY_NAMESPACE="${DOCKER_REGISTRY_NAMESPACE:-platform}"
              ORG_IMAGE_NAME="${ORG_IMAGE_NAME:-${DOCKER_REGISTRY_NAMESPACE}/${COMPONENT_NAME}}"

              ORG_LATEST_IMAGE_TAG="${ORG_LATEST_IMAGE_TAG:-latest}"
              ORG_COMPONENT_VERSION="${ORG_COMPONENT_VERSION:-$(cat VERSION)}"

              set -e \
                && docker build --pull=true -t ${ORG_DOCKER_REGISTRY}/${ORG_IMAGE_NAME}:${ORG_LATEST_IMAGE_TAG} . \
                && docker tag ${ORG_DOCKER_REGISTRY}/${ORG_IMAGE_NAME} ${ORG_DOCKER_REGISTRY}/${ORG_IMAGE_NAME}:${ORG_COMPONENT_VERSION} \
                && docker push ${ORG_DOCKER_REGISTRY}/${ORG_IMAGE_NAME}:${ORG_LATEST_IMAGE_TAG} \
                && docker push ${ORG_DOCKER_REGISTRY}/${ORG_IMAGE_NAME}:${ORG_COMPONENT_VERSION} \
                && ORG_COMPONENT_SHA=$(docker push ${ORG_DOCKER_REGISTRY}/${ORG_IMAGE_NAME}:${ORG_COMPONENT_VERSION} | grep sha | cut -d ' ' -f 3) \
                && echo ${ORG_DOCKER_REGISTRY}/${ORG_IMAGE_NAME}@${ORG_COMPONENT_SHA} > ORG_COMPONENT_IMAGE_SHA
          '''
          script {
            orgComponentImageSha = readFile('ORG_COMPONENT_IMAGE_SHA')
          }
        }
      }
    }

    

    stage('Analyse code quality') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          container('jnlp') {
            sh '''
              sonar-scanner -v
              #sonar-scanner -Dsonar.projectKey=mip-r-hello-world \
              #-Dsonar.sources=. \
              #-Dsonar.host.url=http://sonarqube-platform-sonarqube:9000
            '''

            script {
              env.DEPLOY_TO_DEV = true
            }
          }
        }
      }
    }

    stage('Analyse code security') {
      when {
        environment name: 'TIMER_CAUSE', value: 'true'
      } 
      steps {
        timeout(time: 30, unit: 'MINUTES') {
          withCredentials([usernamePassword(credentialsId: 'veracode', usernameVariable: 'veracode_id', passwordVariable: 'veracode_key')]) {
            veracode applicationName: env.JOB_NAME, canFailJob: true, createProfile: true, criticality: 'VeryHigh', debug: false, fileNamePattern: '', replacementPattern: '', scanExcludesPattern: '', scanIncludesPattern: '', scanName: '', teams: 'Default', uploadExcludesPattern: '', uploadIncludesPattern: '**/**.R', useIDkey: true, vid: env.veracode_id, vkey: env.veracode_key, vpassword: '', vuser: ''
          }
        }
      }
    }

    stage('Deploy to DEV') {
      when {
        environment name: 'DEPLOY_TO_DEV', value: 'true'
      }
      steps {
        container('jnlp') {
          script {
            environment = 'dev'
            lock_name = env.COMPONENT_NAME + '_deploy_' + environment
            kube_context = env.REGION + '.pre.' + env.TEAM_DNS_ZONE
          }
          milestone(10)
          lock(lock_name) {
            script {
              deployToKubernetesEnv(kube_context, environment)
            }
          }
        }
      }
    }

    stage('Run integration tests') {
      parallel {
        stage('Web page performance') {
          steps {
            // container('sitespeed') {
              // sh '''
              //   /start.sh --speedIndex --outputFolder output --summary-detail http://mip-r-hello-world.platform.dev.infra.klikjam.io/
              // '''

              // publishHTML([
              //   allowMissing: false,
              //   alwaysLinkToLastBuild: false,
              //   keepAll: true,
              //   reportDir: 'output',
              //   reportFiles: 'index.html',
              //   reportName: 'Sitespeed Report',
              //   reportTitles: ''
              // ])
              echo "Run sitespeed"
            // }
          }
        }

        stage('Web page accessibility') {
          steps {
            // container('pa11y') {
              // sh '''
              //   pa11y --level error --standard WCAG2AA http://mip-r-hello-world.platform.dev.infra.klikjam.io/
              // '''
              echo "Running accessibility"
            // }
          }
        }
      }
    }

    stage('Approve deployment to SIT') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          script {
            //input message: 'Do you want to deploy to SIT?'
            env.DEPLOY_TO_SIT = 'true'
          }
        }
      }
    }
 
    stage('Deploy to SIT') {
      when {
        environment name: 'DEPLOY_TO_SIT', value: 'true'
      }
      steps {
        container('jnlp') {
          script {
            environment = 'sit'
            lock_name = env.COMPONENT_NAME + '_deploy_' + environment
            kube_context = env.REGION + '.pre.' + env.TEAM_DNS_ZONE
          }
          milestone(20)
          lock(lock_name) {
            script {
              deployToKubernetesEnv(kube_context, environment)
            }
          }
        }
      }
    }
  }

  post {
    success {
      // hipchatSend color: 'GREEN', credentialId: 'hipchat', message: '$JOB_NAME <a href="$BUILD_URL">Build #$BUILD_NUMBER</a> succeeded after $BUILD_DURATION', notify: true, room: "$COMPONENT_NAME", sendAs: '', server: '', textFormat: false, v2enabled: true
      echo "Passed"
    }

    failure {
      // hipchatSend color: 'RED', credentialId: 'hipchat', message: '$JOB_NAME <a href="$BUILD_URL">Build #$BUILD_NUMBER</a> failed after $BUILD_DURATION', notify: true, room: "$COMPONENT_NAME", sendAs: '', server: '', textFormat: false, v2enabled: true
      echo "Failed"
    }
  }
}
