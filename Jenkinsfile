@Library('utils@master') _

def app
def status = 0
github_credentials = usernamePassword(credentialsId: '8d84cb87-b3cc-494d-8791-ff15230c51d5', usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_API_TOKEN')

if (env.CHANGE_ID) { // if not PR
  node('main-agent') {
    ansiColor('xterm') {
      stage('Clone repository') {
        deleteDir() // Delete workspace directory for cleanup
        checkout scm // Git plugin, checks out current commit of branch

        try {
          BRANCH_NAME = CHANGE_BRANCH
        } catch (MissingProperyException) {
        }
      }
        
      stage('SonarQube Analysis') {
        sonarqube([
            sonarScanner: "sonar",
            projectKey: "Instabug_paperclip_AYjfwIUG5Wxt_0C1PuhK"
        ]);
      }
    }
  }
}
