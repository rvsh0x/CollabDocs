#!/bin/bash

# === CONFIG ===
PROJECT_DIR="$HOME/abcd/CollabDocs"
TOMCAT_DIR="$PROJECT_DIR/apache-tomcat-10.1.55"
WAR_NAME="CollabDocs.war"
APP_NAME="CollabDocs"

echo "Build du projet Maven..."
cd "$PROJECT_DIR" || exit
mvn clean package

if [ $? -ne 0 ]; then
  echo "ERROR : Build Maven échoué"
  exit 1
fi

echo "Déploiement du WAR..."

WAR_PATH="$PROJECT_DIR/target/$WAR_NAME"

if [ ! -f "$WAR_PATH" ]; then
  echo "WAR introuvable : $WAR_PATH"
  exit 1
fi

# Supprimer ancienne version
rm -rf "$TOMCAT_DIR/webapps/$APP_NAME"
rm -f "$TOMCAT_DIR/webapps/$WAR_NAME"

# Copier nouveau WAR
cp "$WAR_PATH" "$TOMCAT_DIR/webapps/"

echo "Démarrage de Tomcat..."

cd "$TOMCAT_DIR/bin" || exit

# Stop propre si déjà lancé
./shutdown.sh 2>/dev/null

sleep 2

# Run Tomcat
./catalina.sh run
