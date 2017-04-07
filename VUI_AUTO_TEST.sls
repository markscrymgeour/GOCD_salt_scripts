# Check that WAR folder exists for host deploying to
create_war_dir:
  file.directory:
    - name: '\\localhost\E$\WAR'

#Delete current WAR file in E drive to make way for Nexus Download
delete_current_war:
  file.absent:
    - name: \\localhost\E$\WAR\{{ pillar['appName']}}.war
    - require: 
      - file: create_war_dir 

# Download WAR file from NEXUS
jboss_module_downloaded:
  artifactory.downloaded:
    - artifact:
        artifactory_url: '{{ pillar['repoURL']}}'
        repository: ''
        artifact_id: '{{ pillar['appName']}}'
        group_id: '{{ pillar['groupID']}}'
        packaging: 'war'
        version: '{{ pillar['appVersion']}}'
    - target_file: \\localhost\E$\WAR\{{ pillar['appName']}}.war
    - require:
      - file: delete_current_war

# Undeploy only if NEXUS download has passed
undeploy_war:
  tomcat.undeployed:
    - name: /{{ pillar ['appName']}}
    - url: http://localhost:8080/manager
    - timeout: 400
    - require:
      - artifactory: jboss_module_downloaded

# Ensure Webapps is cleaned up if Tomcat undeploy works 
delete_current_ver:
  file.absent:
    - name: \\localhost\e$\apache-tomcat-8.0.18\webapps\{{ pillar['appName']}}*
    - require:
      - tomcat: undeploy_war

# Deploy downloaded WAR file to Tomcat
deploy_war:
  tomcat.war_deployed:
    - name: /{{ pillar['appName']}}
    - war: \\localhost\E$\WAR\{{ pillar['appName']}}.war
    - timeout: 4000
    - url: http://localhost:8080/manager
    - require:
      - tomcat: undeploy_war 
