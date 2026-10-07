#!groovy

import jenkins.model.Jenkins
import hudson.model.Computer
import hudson.security.GlobalMatrixAuthorizationStrategy
import hudson.security.HudsonPrivateSecurityRealm
import hudson.security.csrf.DefaultCrumbIssuer

def instance = Jenkins.get()

// Admin credentials: controller only.  Agent credentials: worker only.
def adminUser = new File("/run/secrets/jenkins-user").text.trim()
def adminPass = new File("/run/secrets/jenkins-pass").text.trim()
def agentUser = new File("/run/secrets/agent-user").text.trim()
def agentPass = new File("/run/secrets/agent-pass").text.trim()

if (!adminUser || !adminPass) { throw new IllegalStateException("Admin secrets (jenkins-user / jenkins-pass) are empty") }
if (!agentUser || !agentPass) { throw new IllegalStateException("Agent secrets (agent-user / agent-pass) are empty") }
if (adminUser == agentUser) { throw new IllegalStateException("agent-user and jenkins-user must be different accounts; using the same name collapses the intended account separation") }

// Accounts are created or updated from the mounted secrets on every start.
def realm = new HudsonPrivateSecurityRealm(false)
[
  (adminUser): adminPass,
  (agentUser): agentPass
].each { username, password ->
  def existing = realm.getUser(username)
  if (existing == null) {
    realm.createAccount(username, password)
  } else {
    existing.addProperty(HudsonPrivateSecurityRealm.Details.fromPlainPassword(password))
  }
}
instance.setSecurityRealm(realm)

// Admin: full control. Agent: read, plus the computer permissions the Swarm plugin uses.
def strategy = new GlobalMatrixAuthorizationStrategy()
strategy.add(Jenkins.ADMINISTER, adminUser)
strategy.add(hudson.model.Hudson.READ, agentUser)
strategy.add(Computer.CREATE,     agentUser)
strategy.add(Computer.CONNECT,    agentUser)
strategy.add(Computer.DISCONNECT, agentUser)
strategy.add(Computer.BUILD,      agentUser)

instance.setAuthorizationStrategy(strategy)
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))

// No builds on the built-in node: it runs next to the admin secret and JENKINS_HOME.
instance.setNumExecutors(0)
instance.setMode(hudson.model.Node.Mode.EXCLUSIVE)
instance.save()
