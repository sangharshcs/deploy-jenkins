#!groovy
 
import jenkins.model.*
import hudson.security.*
import hudson.security.csrf.DefaultCrumbIssuer
 
def instance = Jenkins.getInstance()
 
def user = new File("/run/secrets/jenkins-user").text.trim()
def pass = new File("/run/secrets/jenkins-pass").text.trim()
 
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
if (hudsonRealm.getUser(user) == null) {
  hudsonRealm.createAccount(user, pass)
}
instance.setSecurityRealm(hudsonRealm)
 
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))
instance.save()
