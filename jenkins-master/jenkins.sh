#! /bin/bash -e

: "${JENKINS_HOME:="/var/jenkins_home"}"

JENKINS_WAR=/usr/share/jenkins/jenkins.war 
CONTROLPORT=8001

HTTPS_PORT=2017
HTTPS_HOST=0.0.0.0

SSL_KEYSTORE=$JENKINS_HOME/.ssl/wildcard.finaxys-lab.intra.jks
SSL_KEYSTORE_PASSWORD=24WhNone09

JAVA_OPTS="-Dhudson.model.ParametersAction.keepUndefinedParameters=true -Djenkins.install.runSetupWizard=false -Djava.io.tmpdir=$JENKINS_HOME/tmp -Djsse.enableSNIExtension=false -Djava.awt.headless=true -server -XX:+AlwaysPreTouch -XX:+UseG1GC -XX:+ExplicitGCInvokesConcurrent -XX:+ParallelRefProcEnabled -XX:+UseStringDeduplication -XX:+UnlockDiagnosticVMOptions -XX:G1SummarizeRSetStatsPeriod=1 -Xms1024M -Xmx3G"
JENKINS_OPTS="-jar $JENKINS_WAR --httpPort=-1 --httpsPort=$HTTPS_PORT --httpsListenAddress=$HTTPS_HOST --ajp13Port=-1 --httpsKeyStore=$SSL_KEYSTORE --httpsKeyStorePassword=$SSL_KEYSTORE_PASSWORD --controlPort=$CONTROLPORT"

FILE="/var/jenkins_home/.init.done"

if [ -f "$FILE" ]
then
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
	eval "exec java $JAVA_OPTS $JENKINS_OPTS \"\$@\""
fi
exec "$@"
else

touch "${COPY_REFERENCE_FILE_LOG}" || { echo "Can not write to ${COPY_REFERENCE_FILE_LOG}. Wrong volume permissions?"; exit 1; }
echo "--- Copying files at $(date)" >> "$COPY_REFERENCE_FILE_LOG"
find /usr/share/jenkins/ref/ -type f -exec bash -c '. /usr/local/bin/jenkins-support; for arg; do copy_reference_file "$arg"; done' _ {} +

#sed -i 's/##ADMIN_JENKINS##/'"$ADMIN_JENKINS"'/g' "/var/jenkins_home/config.xml"


mkdir -p $JENKINS_HOME/tmp
touch "$FILE"
  
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
        eval "exec java $JAVA_OPTS $JENKINS_OPTS \"\$@\""
fi

# As argument is not jenkins, assume user want to run his own process, for example a `bash` shell to explore this image
exec "$@"
fi
