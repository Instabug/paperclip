@Library('utils') _

// PRs only: SonarQube Analysis, in a pod of its own (podCI.sonar).
if (env.CHANGE_ID) {
  stage('SonarQube Analysis') {
    podCI.sonar(sonarScanner: 'sonar', projectKey: 'Instabug_paperclip_AYjfwIUG5Wxt_0C1PuhK')
  }
}
