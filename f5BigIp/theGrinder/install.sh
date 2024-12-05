### The Grinder testing framework: https://github.com/cossme/grinder

apt -y install openjdk-11-jdk openjdk-8-jre unzip tar gzip wget curl
update-alternatives --config java
ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/local/java

cd /tmp
wget https://github.com/cossme/grinder/releases/download/4.0.0/grinder-4.0.0-binary.zip
cd /usr/local
unzip /tmp/grinder*.zip
cd grinder-4.0.0
touch etc/grinder.properties
chmod a+w etc/grinder.properties
mkdir bin

cat >> bin/setGrinderEnv.sh <<EOF
GRINDERPATH=`pwd`/..
GRINDERPROPERTIES=$GRINDERPATH/etc/grinder.properties
CLASSPATH=$GRINDERPATH/lib/grinder.jar:$CLASSPATH
JAVA_HOME=/usr/local/java
PATH=$JAVA_HOME/bin:$PATH
#echo "DEBUG: GRINDERPROPERTIES=$GRINDERPROPERTIES | JAVA_HOME=$JAVA_HOME "
export CLASSPATH PATH GRINDERPROPERTIES
EOF

cat >> bin/startAgent.sh <<EOF
#!/bin/bash
. ./setGrinderEnv.sh
java -classpath $CLASSPATH net.grinder.Grinder $GRINDERPROPERTIES
EOF

cat >> bin/startProxy.sh << EOF
#!/bin/bash
. ./setGrinderEnv.sh
java -classpath $CLASSPATH net.grinder.TCPProxy -console -http > grinder.py
EOF

cat >> bin/startConsole.sh <<EOF
#!/bin/bash
. ./setGrinderEnv.sh
java -classpath $CLASSPATH net.grinder.Console
EOF

chmod a+x bin/*.sh