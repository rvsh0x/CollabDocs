# CollabDocs

Plateforme d'édition collaborative de documents texte en temps réel.

## Prérequis

| Composant | Version minimale |
|-----------|-----------------|
| JDK       | 11              |
| Maven     | 3.8+            |
| Tomcat    | 9.x             |
| MySQL     | 8.0+ / MariaDB 10.5+ |

## Installation

### 1. Base de données

```bash
mysql -u root -p < collabdocs.sql
```

Ou via MySQL Workbench / DBeaver : importer et exécuter `collabdocs.sql`.

### 2. Credentials de la base (si différents de root/root)

Modifier les constantes dans :

```
src/main/java/dao/DBConnection.java
```

```java
private static final String DB_URL      = "jdbc:mysql://localhost:3306/collabdocs?...";
private static final String DB_USER     = "root";      // ← votre utilisateur
private static final String DB_PASSWORD = "root";      // ← votre mot de passe
```

### 3. Build

```bash
cd CollabDocs
mvn clean package
```

Le fichier WAR est généré dans `target/CollabDocs.war`.

### 4. Déploiement sur Tomcat

Copier le WAR dans le répertoire `webapps/` de Tomcat :

```bash
cp target/CollabDocs.war /opt/tomcat/webapps/
```

Tomcat déploie automatiquement. Accéder à :

```
http://localhost:8080/CollabDocs/
```

## Comptes de test

| Utilisateur | Mot de passe | Rôle       |
|-------------|-------------|------------|
| admin       | admin123    | admin      |
| alice       | alice123    | registered |
| bob         | bob123      | registered |
| charlie     | charlie123  | registered |

## Structure du projet

```
CollabDocs/
├── src/main/java/
│   ├── model/          Entités POJO (User, Document, Message, Permission)
│   ├── dao/            Accès JDBC (UserDAO, DocumentDAO, MessageDAO, PermissionDAO)
│   ├── controller/     Servlets MVC
│   ├── websocket/      Endpoint WebSocket temps réel
│   ├── filter/         AuthFilter
│   └── util/           PasswordUtil (SHA-256)
├── src/main/webapp/
│   ├── WEB-INF/views/  Pages JSP (EL + JSTL, sans scriptlets)
│   ├── css/style.css   CSS custom + Bulma CDN
│   └── js/editor.js    Client WebSocket
├── pom.xml
├── collabdocs.sql
└── README.md
```

## Fonctionnalités

- Édition collaborative en temps réel via WebSocket
- Chat intégré par document avec historique
- Gestion des droits : propriétaire / lecture / écriture
- 3 types d'accès : public, par lien, privé
- Protection optionnelle par mot de passe
- Historique des versions avec restauration
- Panneau d'administration (gestion utilisateurs & documents)
- Reconnexion automatique WebSocket (backoff exponentiel)
- Debounce 300 ms sur les mises à jour de contenu
- Autoscroll du chat
- Raccourci clavier Ctrl+S / Cmd+S pour sauvegarder

## Protocole WebSocket

| Direction | Type | Description |
|-----------|------|-------------|
| Client → Serveur | `content_update` | Nouveau contenu du document |
| Client → Serveur | `chat_message`   | Message de chat |
| Client → Serveur | `save_request`   | Sauvegarder + archiver |
| Client → Serveur | `title_update`   | Nouveau titre |
| Client → Serveur | `cursor_move`    | Position du curseur |
| Serveur → Client | `init`           | Contenu initial + nb connectés |
| Serveur → Client | `content_update` | Diffusion modification |
| Serveur → Client | `chat_message`   | Diffusion message chat |
| Serveur → Client | `user_joined`    | Notification connexion |
| Serveur → Client | `user_left`      | Notification déconnexion |
| Serveur → Client | `saved`          | Confirmation sauvegarde |
| Serveur → Client | `title_update`   | Diffusion nouveau titre |
| Serveur → Client | `error`          | Message d'erreur |
