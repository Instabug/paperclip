library identifier: 'utils@jenkins_sharedLib_latest',
        retriever: modernSCM(
            [$class: 'GitSCMSource',
            remote: 'https://github.com/Instabug/ops.git',
            credentialsId: 'Github',
            ],
        )

def app
def status = 0
github_credentials = usernamePassword(credentialsId: '8d84cb87-b3cc-494d-8791-ff15230c51d5', usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_API_TOKEN')

node('main-agent') {
    ansiColor('xterm') {
    }
        stage('Clone repository') {
            deleteDir() // Delete workspace directory for cleanup
            checkout scm // Git plugin, checks out current commit of branch

            try {
                BRANCH_NAME = CHANGE_BRANCH
            } catch (MissingProperyException) {
            }

            if (JOB_NAME =~ /\/PR-\d+$/) {
            RUN_PIPELINE = false
            }
             else {
            RUN_PIPELINE = true
            utilsLib.setup() // Stop previous builds

             }
        }
        
        if (env.CHANGE_ID) { // if not PR
      stage('SonarQube Analysis') {
        withSonarQubeEnv('sonarqube-prod-dockercompose') {
          withCredentials([string(credentialsId: 'sonarqube-prod-jenkins-token', variable: 'SONARQUBE_PROD_TOKEN')]) {
            sh "docker run -u \$(id -u):\$(id -g) --rm -e SONAR_HOST_URL='$SONAR_HOST_URL' -e SONAR_SCANNER_OPTS='-Dsonar.projectKey=Instabug_iam-automation_AYjfUn3c5Wxt_0C1PueQ -Dsonar.pullrequest.key=" + pullRequest.number + " -Dsonar.pullrequest.branch=" + pullRequest.headRef + " -Dsonar.pullrequest.base=" + pullRequest.base + "' -e SONAR_LOGIN=$SONARQUBE_PROD_TOKEN -v `pwd`:/usr/src sonarsource/sonar-scanner-cli"
            }
        }
      }
        }

        stage("GitLeaks") {
            sh "curl -L -o gitleaks https://github.com/zricethezav/gitleaks/releases/download/v7.5.0/gitleaks-linux-amd64"
            sh "chmod +x gitleaks"

            if (env.CHANGE_ID) { // GitHub Pull Request
                // Find all commits that are descendants of the target branch and ancestors of the
                // current branch and pass them to GitLeaks comma-spearated.
                env.STATUS_CODE = sh(script: "git rev-list --ancestry-path origin/$CHANGE_TARGET...origin/$CHANGE_BRANCH | paste -s -d, | xargs ./gitleaks -v --commits", returnStatus: true)
            } else { // Branch Commits
                def currentCommit = utilsLib.commitHashForBuild(currentBuild.rawBuild)
                def lastSuccessfulCommit = utilsLib.getLastSuccessfulCommit()
                def doesLastCommitExist = sh(script: "git merge-base --is-ancestor $lastSuccessfulCommit HEAD", returnStatus: true)

                if (lastSuccessfulCommit && doesLastCommitExist == 0 && lastSuccessfulCommit != currentCommit) {
                    // If this branch has a previous successful build that still exists (not force
                    // pushed) and there is actually a change from the previous build, then get all
                    // commits from the last build up till this point and pass them to GitLeaks.
                    env.STATUS_CODE = sh(script: "git rev-list --ancestry-path $lastSuccessfulCommit..$currentCommit | paste -s -d, | xargs ./gitleaks -v --commits", returnStatus: true)
                } else {
                    // Get the first branching point between the current branch and master; this is
                    // the commit in master from which this branch was first created.
                    def branchPoint = sh(script: '''#!/bin/bash
                        diff -u <(git rev-list --first-parent HEAD) <(git rev-list --first-parent origin/master) | sed -ne 's/^ //p' | head -1
                    ''', returnStdout: true).replaceAll("\n", "")

                    if (branchPoint != "") {
                        // Get all commits between the first branching point and HEAD.
                        def commits = sh(script: "git rev-list --ancestry-path $branchPoint..HEAD", returnStdout: true).split("\n")

                        if (commits.size() != 0) {
                            env.STATUS_CODE = sh(script: "./gitleaks -v --leaks-exit-code=123 --commits=${commits.join(",")}", returnStatus: true)
                        } else {
                            env.STATUS_CODE = 0
                        }
                    } else {
                        env.STATUS_CODE = 0
                    }
                }
            }

            if (env.STATUS_CODE != "0") {
                if (env.CHANGE_ID) {
                    withCredentials([string(credentialsId: 'DANGER_GITHUB_API_TOKEN', variable: 'DANGER_GITHUB_API_TOKEN')]) {
                        sh(script: "export DANGER_GITHUB_API_TOKEN=${DANGER_GITHUB_API_TOKEN}")
                        sh(script: "curl -X POST -H \"Authorization: token \$DANGER_GITHUB_API_TOKEN\" -H \"Accept: application/vnd.github.v3+json\" https://api.github.com/repos/Instabug/${utilsLib.getRepoName()}/issues/${CHANGE_ID}/comments -d '{ \"body\": \"${currentBuild.fullDisplayName} failed GitLeaks check.\\nYou can check it out [here]($BUILD_URL).\" }'")
                    }

                    slackSend(teamDomain: "instabugteam", channel: "#alerts_gitleaks", color: "danger", message: "${currentBuild.fullDisplayName} failed GitLeaks check.\nYou can check it out (<${env.CHANGE_URL}|here>).")
                } else {
                    slackSend(teamDomain: "instabugteam", channel: "#alerts_gitleaks", color: "danger", message: "${currentBuild.fullDisplayName} failed GitLeaks check.\nYou can check it out (<${env.BUILD_URL}|here>).")
                }

                error("GitLeaks check failed!")
            }
        }
}
