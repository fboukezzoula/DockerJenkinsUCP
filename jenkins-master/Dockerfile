FROM dtr.finaxys-lab.intra/workshop-demo/jdk:8u131

MAINTAINER fboukezzoula@finaxys.com

RUN yum update -y && yum install -y tar git zip unzip bind-utils && yum clean all

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG http_port=8080

#ARG agent_port=50000

ENV JENKINS_HOME /var/jenkins_home
#ENV JENKINS_SLAVE_AGENT_PORT ${agent_port}

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container, 
# ensure you use the same uid
RUN groupadd -g ${gid} ${group} \
    && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

# Jenkins home directory is a volume, so configuration and build history 
# can be persisted and survive image upgrades
VOLUME /var/jenkins_home

# `/usr/share/jenkins/ref/` contains all reference configuration we want 
# to set on a fresh new installation. Use it to bundle additional plugins 
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

ENV TINI_VERSION 0.14.0
ENV TINI_SHA 6c41ec7d33e857d4779f14d9c74924cab0c7973485d2972419a3b7c7620ff5fd

# Use tini as subreaper in Docker container to adopt zombie processes 
RUN curl -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-amd64 -o /bin/tini && chmod +x /bin/tini \
  && echo "$TINI_SHA  /bin/tini" | sha256sum -c -

#COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

# COPY several files for customize the Jenkins Master

COPY /config.xml /usr/share/jenkins/ref/config.xml
COPY /buildtriggerbadge.xml /usr/share/jenkins/ref/buildtriggerbadge.xml
COPY /docker-slaves.xml /usr/share/jenkins/ref/docker-slaves.xml
COPY /jenkins.CLI.xml /usr/share/jenkins/ref/jenkins.CLI.xml
COPY /jenkins.model.JenkinsLocationConfiguration.xml /usr/share/jenkins/ref/jenkins.model.JenkinsLocationConfiguration.xml

# jenkins version being bundled in this docker image
ARG JENKINS_VERSION
ENV JENKINS_VERSION ${JENKINS_VERSION:-2.60.1}

# Can be used to customize where jenkins.war get downloaded from
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum 
# see https://github.com/docker/docker/issues/8331
RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war 

ENV JENKINS_UC https://updates.jenkins.io
RUN chown -R ${user} "$JENKINS_HOME" /usr/share/jenkins/ref

# for main web interface:
EXPOSE ${http_port}

# will be used by attached slave agents:
#EXPOSE ${agent_port}

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]

# from a derived Dockerfile, can use `RUN plugins.sh active.txt` to setup /usr/share/jenkins/ref/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh
COPY install-plugins.sh /usr/local/bin/install-plugins.sh

RUN chmod 755 /usr/local/bin/install-plugins.sh /usr/local/bin/plugins.sh

USER ${user}

RUN /usr/local/bin/install-plugins.sh ace-editor active-directory ant antisamy-markup-formatter async-http-client authentication-tokens bouncycastle-api branch-api build-timeout buildtriggerbadge cloudbees-folder config-file-provider credentials-binding credentials display-url-api docker-commons docker-slaves dockerhub-notification durable-task email-ext embeddable-build-status envinject external-monitor-job favorite ghprb git-client git-server git github-api github-branch-source github-organization-folder github gradle greenballs handlebars hashicorp-vault icon-shim jackson2-api javadoc jquery-detached junit ldap mailer mapdb-api matrix-auth matrix-project metadata metrics modernstatus momentjs pam-auth pegdown-formatter pipeline-build-step pipeline-graph-analysis pipeline-input-step pipeline-maven pipeline-milestone-step pipeline-rest-api pipeline-stage-step pipeline-stage-view pipeline-utility-steps plain-credentials remote-terminal-access resource-disposer scm-sync-configuration script-security sonar sse-gateway ssh-credentials ssh-slaves structs subversion timestamper token-macro update-sites-manager variant windows-slaves workflow-aggregator workflow-api workflow-basic-steps workflow-cps workflow-durable-task-step workflow-job workflow-multibranch workflow-remote-loader workflow-scm-step workflow-step-api workflow-support ws-cleanup

