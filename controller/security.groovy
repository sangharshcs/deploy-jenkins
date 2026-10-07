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

// Create or update each account so Docker secrets remain the authoritative
// source of truth: a secret rotation followed by a container restart is enough.
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

// Matrix Authorization: admin gets full control.
// Agent account is granted the permissions below, which cover Swarm plugin
// registration and reconnection.  The agent cannot access job configuration,
// credentials, or administration pages.
//   Hudson.READ      – required for any authenticated REST/UI call
//   Computer.CREATE  – register a new (previously unknown) agent node
//   Computer.CONNECT – connect or reconnect an agent node
//   Computer.DISCONNECT – gracefully disconnect on shutdown
//   Computer.BUILD   – allow executors to be started on this node
def strategy = new GlobalMatrixAuthorizationStrategy()
strategy.add(Jenkins.ADMINISTER, adminUser)
strategy.add(hudson.model.Hudson.READ, agentUser)
strategy.add(Computer.CREATE,     agentUser)
strategy.add(Computer.CONNECT,    agentUser)
strategy.add(Computer.DISCONNECT, agentUser)
strategy.add(Computer.BUILD,      agentUser)

instance.setAuthorizationStrategy(strategy)
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))

// Jobs on the built-in node run inside the controller container where the
// admin secret (/run/secrets/jenkins-pass) and all of JENKINS_HOME — including
// secret.key, secrets/, users/, and jobs/ — are reachable by the build process.
// Zero executors forces every build onto a labelled worker instead.
instance.setNumExecutors(0)
instance.setMode(hudson.model.Node.Mode.EXCLUSIVE)
instance.save()
