# Rapport complet du projet CollabDocs


## 1) Vue d'ensemble

CollabDocs est une application web Java qui permet :
- de creer des documents texte ;
- de les partager avec des droits (lecture/ecriture) ;
- de les modifier en collaboration en temps reel (WebSocket) ;
- de discuter via un chat par document ;
- de sauvegarder un historique de versions.

Le projet suit globalement un style **MVC** :
- **Model** : classes metier (`User`, `Document`, etc.) ;
- **View** : pages JSP (`home.jsp`, `editor.jsp`, etc.) ;
- **Controller** : servlets (`LoginServlet`, `DocumentServlet`, etc.).

---

## 2) Stack technique

- **Langage backend** : Java 11
- **Serveur web** : Tomcat 10 (Jakarta namespace)
- **Build** : Maven (`war`)
- **Base de donnees** : MySQL/MariaDB
- **Acces DB** : JDBC natif (pas de Hibernate/JPA)
- **Vues** : JSP + JSTL
- **Frontend** : JavaScript vanilla + CSS + Bulma
- **Temps reel** : WebSocket (endpoint serveur + client JS)
- **Format messages WS** : JSON (`org.json`)

---

## 3) Arborescence logique

- `src/main/java/model` : objets metier
- `src/main/java/dao` : acces base de donnees
- `src/main/java/controller` : servlets (routes HTTP)
- `src/main/java/filter` : filtre d'authentification
- `src/main/java/websocket` : endpoint temps reel
- `src/main/java/util` : utilitaires (hash mot de passe)
- `src/main/webapp/WEB-INF/views` : pages JSP
- `src/main/webapp/js` : JS frontend de l'editeur
- `src/main/webapp/css` : styles globaux
- `src/main/webapp/WEB-INF/web.xml` : config web.xml
- `collabdocs.sql` : schema + donnees de demo
- `pom.xml` : dependances Maven

---

## 4) Base de donnees (fichier `collabdocs.sql`)

### Tables

1. `users`
- stocke les utilisateurs.
- colonnes importantes : `username`, `email`, `password_hash`, `role`.

2. `documents`
- stocke les documents.
- colonnes importantes : `title`, `content`, `owner_id`, `access_type`, `share_token`, `password_hash`.

3. `permissions`
- associe un utilisateur a un document avec un niveau `read`/`write`.
- contrainte unique `(user_id, document_id)` pour eviter les doublons.

4. `messages`
- chat par document.
- lie a `document_id`, optionnellement a `user_id`.

5. `document_history`
- versions sauvegardees des documents.

### Relations

- `documents.owner_id -> users.id`
- `permissions.user_id -> users.id`
- `permissions.document_id -> documents.id`
- `messages.document_id -> documents.id`
- `messages.user_id -> users.id`
- `document_history.document_id -> documents.id`
- `document_history.saved_by -> users.id`

### Jeu de donnees initial

Le script insere :
- 4 utilisateurs (`admin`, `alice`, `bob`, `charlie`)
- 3 documents demo
- des permissions
- des messages
- un debut d'historique

Important : les commentaires de hashes dans le SQL sont incoherents a certains endroits (notes de calcul), mais ce sont les **valeurs inserees** qui comptent.

---

## 5) Build et dependances (`pom.xml`)

### Packaging

- `war` : application deployee dans Tomcat.

### Dependances principales

- `jakarta.servlet-api` (provided)
- `jakarta.websocket-server-api` (provided)
- `jakarta.websocket-client-api` (provided)
- JSTL API + implementation
- `mysql-connector-j`
- `org.json`

### Plugins

- `maven-compiler-plugin` (Java 11)
- `maven-war-plugin`

---

## 6) Configuration web (`src/main/webapp/WEB-INF/web.xml`)

### Sessions

- timeout de session : 30 minutes.

### Filtre

- `AuthFilter` protege :
  - `/editor/*`
  - `/admin/*`
  - `/home`
  - `/document/*`

### Servlets routees

- `/index.jsp` -> `IndexServlet`
- `/login` -> `LoginServlet`
- `/register` -> `RegisterServlet`
- `/logout` -> `LogoutServlet`
- `/home` -> `HomeServlet`
- `/document/*` -> `DocumentServlet`
- `/editor/*` + `/d/*` -> `EditorServlet`
- `/admin` + `/admin/*` -> `AdminServlet`

### Pages d'erreurs

- 404, 403, 500 vers `error.jsp`.

---

## 7) Couche Model (`src/main/java/model`)

## `User.java`

Role : represente un utilisateur.

Attributs :
- `id`, `username`, `email`, `passwordHash`, `role`, `createdAt`

Methodes importantes :
- `isAdmin()` : retourne true si role = `admin`.

## `Document.java`

Role : represente un document.

Attributs :
- `id`, `title`, `content`, `ownerId`, `accessType`, `shareToken`, `passwordHash`, `createdAt`, `updatedAt`
- `ownerUsername` (champ de confort pour affichage)

Methodes importantes :
- `isPublic()`
- `hasPassword()`

## `Permission.java`

Role : represente une permission sur un document.

Attributs :
- `userId`, `documentId`, `level`
- `username`, `documentTitle` (affichage)

Methode :
- `canWrite()`

## `Message.java`

Role : represente un message de chat.

Attributs :
- `documentId`, `userId` (nullable), `username`, `content`, `sentAt`

---

## 8) Couche utilitaire (`src/main/java/util`)

## `PasswordUtil.java`

Role : hash/verif de mot de passe.

Methodes :
- `hash(plainPassword)` : SHA-256 -> hex lowercase
- `verify(plainPassword, storedHash)` : compare hash calcule et hash stocke
- `bytesToHex(bytes)` : helper interne

Note securite pedagogique : SHA-256 sans salt n'est pas ideal en production ; preferer BCrypt/Argon2.

---

## 9) Couche DAO (`src/main/java/dao`)

Les DAO font le lien Java <-> SQL via JDBC.

## `DBConnection.java`

Role : singleton de connexion DB.

Methodes :
- `getInstance()` : instance unique
- `getConnection()` : connexion valide/reconnectee si besoin
- `close()` : fermeture propre

Points a connaitre :
- credentials en dur (`root`/`root`) ;
- une seule connexion partagee (simple mais limite sous charge).

## `UserDAO.java`

Methodes :
- `createUser(User)`
- `findById(int)`
- `findByUsername(String)`
- `usernameExists(String)`
- `emailExists(String)`
- `getAllUsers()`
- `updateRole(int, String)`
- `deleteUser(int)`
- `map(ResultSet)` (privee)

## `DocumentDAO.java`

Methodes CRUD :
- `createDocument(Document)` (genere share token si absent)
- `findById(int)`
- `findByShareToken(String)`
- `findByOwner(int)`
- `findAccessibleByUser(int)`
- `findSharedWithUser(int)`
- `getAllDocuments()`
- `updateContent(int, String)`
- `updateTitle(int, String)`
- `deleteDocument(int)`

Historique :
- `saveHistory(int, String, Integer)`
- `getHistory(int)` retourne des `Object[]` : `[id, savedAt, username, content]`

Mapping :
- `map(ResultSet)` (privee)

## `PermissionDAO.java`

Methodes :
- `addPermission(userId, docId, level)` (UPSERT)
- `getPermission(userId, docId)`
- `getUsersForDocument(docId)`
- `removePermission(userId, docId)`

## `MessageDAO.java`

Methodes :
- `saveMessage(Message)`
- `getMessages(docId, limit)` (dernier N, remis en ordre chrono)
- `countMessages(docId)`
- `map(ResultSet)` (privee)

---

## 10) Couche Controller (`src/main/java/controller`)

## `IndexServlet.java`

Route principale de redirection :
- si utilisateur connecte -> `/home`
- sinon -> `/login`

## `LoginServlet.java`

- `doGet()` : affiche la page login, ou redirige home si deja connecte
- `doPost()` :
  - valide saisie
  - charge utilisateur par username
  - verifie mot de passe via `PasswordUtil.verify`
  - cree session et redirige home

## `LogoutServlet.java`

- `doGet()` : invalide session, redirige login
- `doPost()` : delegue a `doGet()`

## `RegisterServlet.java`

- `doGet()` : page inscription (ou home si deja connecte)
- `doPost()` :
  - valide username/email/password
  - verifie unicite username/email
  - hash mot de passe
  - cree user
  - connecte automatiquement

Helpers :
- `setErrorAndForward(...)`
- `trim(...)`

## `HomeServlet.java`

- `doGet()` :
  - charge docs proprietaire (`myDocs`)
  - charge docs partages (`sharedDocs`)
  - forward vers `home.jsp`

## `DocumentServlet.java`

### `doGet()`

- `/new` : formulaire creation
- `/share` : page gestion partage

### `doPost()`

- `/new` : creation document (`handleCreate`)
- `/delete` : suppression (`handleDelete`)
- `/share` : ajout/retrait droits (`handleShareUpdate`)

### Methodes internes

- `handleCreate(req, resp)`
- `handleDelete(req, resp)`
- `handleSharePage(req, resp)`
- `handleShareUpdate(req, resp)`
- `trim(String)`
- `parseId(String)`

## `EditorServlet.java`

Role central : ouvrir un document en edition.

Supporte 2 acces :
- `/editor/{id}`
- `/d/{shareToken}`

Etapes de `doGet()` :
1. Identifier document (id ou token)
2. Verifier autorisation de lecture (`canView`)
3. Gerrer protection mot de passe document
4. Calculer droit d'ecriture (`canEdit`)
5. Charger messages et historique
6. Forward vers `editor.jsp`

Methodes :
- `canView(User, Document, HttpServletRequest)`
- `canEdit(User, Document)`

## `AdminServlet.java`

`doGet()` :
- charge dashboard admin avec stats :
  - nombre users/docs/admins/messages.

`doPost()` :
- `/user` -> `handleUserAction` (changer role / supprimer)
- `/doc` -> `handleDocAction` (supprimer doc)

Helpers :
- `loadDashboard(...)`
- `handleUserAction(...)`
- `handleDocAction(...)`
- `parseId(...)`

---

## 11) Filtre de securite (`src/main/java/filter/AuthFilter.java`)

`AuthFilter` :
- verifie qu'un user est en session ;
- redirige sinon vers `/login` ;
- pour `/admin...`, exige `user.isAdmin()`.

Ce filtre s'applique aux routes protegees configurees dans `web.xml`.

---

## 12) Temps reel WebSocket (`src/main/java/websocket`)

## `HttpSessionConfigurator.java`

Role :
- pendant le handshake WebSocket, recupere la session HTTP ;
- copie l'objet `user` dans les `userProperties` WS.

But :
- connaitre l'utilisateur dans `DocumentWebSocket`.

## `DocumentWebSocket.java`

Endpoint :
- `@ServerEndpoint("/ws/doc/{docId}")`

Etat global :
- `ROOMS` : map `docId -> set de sessions connectees`.

Callbacks :
- `@OnOpen` :
  - determine username
  - ajoute session a la room
  - envoie message `init` (contenu courant + count)
  - notifie les autres (`user_joined`)
- `@OnMessage` :
  - parse JSON
  - switch sur `type` :
    - `content_update` -> broadcast autres
    - `chat_message` -> save DB + broadcast tous
    - `save_request` -> update DB + save history + broadcast `saved`
    - `cursor_move` -> broadcast autres
    - `title_update` -> update DB + broadcast autres
- `@OnClose` :
  - retire session
  - notifie `user_left`
- `@OnError` :
  - log serveur

Helpers internes :
- `broadcastAll(...)`
- `broadcastExcept(...)`
- `sendTo(...)`
- classe interne `SessionWrapper` (equals/hashCode sur session id)

---

## 13) Frontend vues JSP (`src/main/webapp/WEB-INF/views`)

## Layout

### `layout/header.jsp`
- declaration HTML, CSS Bulma + style custom
- navbar
- script burger menu mobile

### `layout/footer.jsp`
- footer global + fermeture `body/html`

## Auth

### `auth/login.jsp`
- formulaire login
- affiche message d'erreur
- propose comptes demo

### `auth/register.jsp`
- formulaire inscription
- affiche erreurs de validation

## Pages metier

### `home.jsp`
- liste docs proprietaire (`myDocs`)
- liste docs partages (`sharedDocs`)
- actions : ouvrir, partager, supprimer

### `document-new.jsp`
- creation d'un document
- choix access type : `link`, `public`, `private`
- mot de passe optionnel

### `document-share.jsp`
- affiche lien de partage
- liste collaborateurs et droits
- ajout/retrait d'invites
- JS local : `copyShareLink()`, `showToast()`

### `editor.jsp`
- page principale edition collaborative
- injecte `COLLAB_CONFIG` pour `editor.js` :
  - `docId`, `canEdit`, `username`, `wsUrl`
- structure UI :
  - toolbar
  - textarea document
  - chat
  - modal historique
- injecte `HISTORY_DATA` pour restauration versions
- charge `js/editor.js`

### `admin.jsp`
- tableau de bord admin
- stats globales
- gestion utilisateurs
- gestion documents

### `error.jsp`
- page d'erreur personnalisee (403/404/500)

---

## 14) Frontend statique

## `src/main/webapp/js/editor.js`

C'est le coeur client du temps reel.

### Etat et refs

- recupere references DOM (textarea, chat, boutons, status)
- garde l'etat WS (`ws`, timers, reconnexion, presence)
- construit plusieurs URLs WS candidates (`buildWsCandidates`)

### Fonctions principales

- `connect()` :
  - ouvre socket
  - timeout de connexion
  - handlers `onopen/onclose/onerror/onmessage`
- `scheduleReconnect()` :
  - reconnexion exponential backoff
- `handleMessage(msg)` :
  - traite types entrants (`init`, `content_update`, `chat_message`, etc.)
- `send(obj)` :
  - envoie JSON si socket ouverte
  - sinon affiche notification
- listeners UI :
  - edition texte (debounce)
  - edition titre (debounce)
  - sauvegarde bouton + Ctrl/Cmd+S
  - envoi chat
  - ouverture historique
- chat helpers :
  - `appendChatMessage`, `appendSystemMessage`, `scrollChatToBottom`
- presence/compteur :
  - `updateUserCount`, `updatePresence`
- statut :
  - `setConnStatus`, `showSaveStatus`, `showNotification`
- historique modal :
  - `window.openHistory`, `window.closeHistory`, `window.restoreVersion`
- helpers :
  - `setTextareaValue`, `formatTime`, `buildWsCandidates`
- demarrage :
  - `connect()`

### `src/main/webapp/css/style.css`

Role :
- theme general de l'app
- style editeur/chat
- responsive mobile
- notifications toast
- styles home/admin

---

## 15) Fichier racine web

## `src/main/webapp/index.jsp`

Contenu :
- `<jsp:forward page="/"/>`

But :
- rediriger vers le flux normal de l'application.

---

## 16) Flux fonctionnels (pas a pas)

## Connexion utilisateur
1. user ouvre `/login`
2. submit -> `LoginServlet#doPost`
3. verif credentials
4. session creee, redirection `/home`

## Creation document
1. user ouvre `/document/new`
2. submit -> `DocumentServlet#handleCreate`
3. insert DB via `DocumentDAO#createDocument`
4. redirection vers `/editor/{id}`

## Ouverture editeur
1. `EditorServlet#doGet`
2. verif acces + mdp doc + droits
3. load messages + historique
4. render `editor.jsp`
5. navigateur charge `editor.js`
6. `editor.js` ouvre WebSocket `/ws/doc/{id}`

## Edition collaborative
1. user tape -> event `input`
2. debounce -> envoi `content_update`
3. serveur recoit -> diffuse aux autres sessions
4. autres clients mettent a jour textarea

## Chat
1. submit chat -> `chat_message`
2. serveur sauvegarde message DB
3. serveur broadcast a tous
4. clients ajoutent message dans le panneau chat

## Sauvegarde version
1. clic sauvegarder / Ctrl+S -> `save_request`
2. serveur met a jour `documents.content`
3. serveur insere snapshot dans `document_history`
4. serveur envoie `saved` (timestamp)

---

## 17) Points forts du projet

- architecture claire en couches ;
- routes bien separees (auth, document, admin, editor) ;
- droits lecture/ecriture et partage ;
- historique de versions ;
- chat + temps reel ;
- vues JSP lisibles ;
- CSS propre et UX correcte.

---

## 18) Limites techniques et axes d'amelioration

1. **Securite mot de passe**
- utiliser BCrypt/Argon2 plutot que SHA-256 simple.

2. **Gestion DB**
- eviter une unique connexion globale ; preferer pool (`HikariCP`).

3. **Validation frontend/backend**
- deja presente partiellement ; peut etre renforcee.

4. **WebSocket robustesse**
- logs + metriques + fallback proxy a formaliser.

5. **Historique**
- objets `Object[]` peu typage ; creer un modele `DocumentHistory`.

6. **Tests**
- ajouter tests unitaires DAO/Servlets + integration.

7. **Configuration**
- externaliser credentials DB (variables d'env / fichier config).

---

## 19) Glossaire simple (debutant)

- **Servlet** : classe Java qui traite une requete HTTP.
- **JSP** : page HTML avec balises serveur Java.
- **DAO** : classe qui parle a la base SQL.
- **Session** : espace serveur pour memoriser l'utilisateur connecte.
- **WebSocket** : canal temps reel bidirectionnel client <-> serveur.
- **JSON** : format texte structure pour echanger des messages.
- **MVC** : modele / vue / controleur.
- **WAR** : archive deployable dans Tomcat.

---

## 20) Checklist "comprehension du projet"

Si tu comprends ces 10 points, tu maitrises deja bien le projet :
- comment un utilisateur se connecte (`LoginServlet`) ;
- comment un document est cree (`DocumentServlet`) ;
- comment un document est ouvert (`EditorServlet`) ;
- comment les droits sont verifies (`canView`, `canEdit`, `AuthFilter`) ;
- comment le chat est persiste (`MessageDAO`) ;
- comment l'historique est enregistre (`saveHistory`) ;
- comment fonctionne le handshake WS (`HttpSessionConfigurator`) ;
- comment les messages WS sont routés (`DocumentWebSocket#onMessage`) ;
- comment le client JS envoie/recoit (`editor.js`) ;
- comment `web.xml` mappe toutes les routes.

---

## 21) Technologies expliquees en detail

Cette section explique les technos en profondeur (pas juste leurs noms), avec leur role exact dans CE projet.

### 21.1 Java Servlet (Jakarta Servlet)

Une **Servlet** est une classe Java executee par Tomcat pour traiter des requetes HTTP.

Dans CollabDocs :
- chaque URL importante est reliee a une servlet (`/login`, `/home`, `/editor/*`, etc.) ;
- chaque servlet herite de `HttpServlet` ;
- `doGet()` traite les requetes GET (affichage de pages) ;
- `doPost()` traite les actions POST (creation, suppression, login, etc.).

Cycle simplifie :
1. le navigateur appelle une URL ;
2. Tomcat trouve la servlet mappee dans `web.xml` ;
3. la servlet lit les parametres (`req.getParameter`) ;
4. la servlet execute la logique metier (via DAO) ;
5. la servlet redirige (`sendRedirect`) ou affiche une vue JSP (`forward`).

### 21.2 JSP + JSTL + EL

Une **JSP** est un template serveur qui genere du HTML.

Dans le projet :
- les JSP sont dans `WEB-INF/views` (non accessibles directement par URL brute) ;
- les servlets font `forward` vers ces JSP ;
- les donnees passees via `req.setAttribute(...)` sont lues en JSP.

**JSTL** :
- `c:if`, `c:choose`, `c:forEach`, `c:out` pour conditions/boucles/sortie echappee.

**EL (Expression Language)** :
- `${doc.title}`, `${sessionScope.user}`, `${not empty error}`.

Interet pedagogique :
- separe presentation (JSP) et logique Java (Servlet/DAO).

### 21.3 JDBC

**JDBC** est l'API Java standard pour executer des requetes SQL.

Dans CollabDocs :
- les DAO ouvrent des `PreparedStatement` ;
- `PreparedStatement` protege des injections SQL (parametres `?`) ;
- `ResultSet` convertit les lignes SQL en objets Java ;
- les DAO encapsulent SQL et mapping.

Pattern typique utilise :
- `String sql = "... WHERE id = ?"`
- `PreparedStatement ps = conn.prepareStatement(sql)`
- `ps.setInt(1, id)`
- `ResultSet rs = ps.executeQuery()`
- `map(rs)` -> objet metier

### 21.4 MySQL / MariaDB

La base relationnelle stocke :
- utilisateurs ;
- documents ;
- droits ;
- messages de chat ;
- historique des versions.

Le schema utilise :
- des FK (`FOREIGN KEY`) pour garantir la coherence ;
- des contraintes `UNIQUE` pour eviter les doublons ;
- des regles `ON DELETE` (`CASCADE`, `SET NULL`) pour comportement automatique lors d'une suppression.

### 21.5 WebSocket

**WebSocket** cree un canal persistant bidirectionnel entre navigateur et serveur.

Pourquoi indispensable ici :
- HTTP est request/response, pas ideal pour "temps reel" ;
- WebSocket permet de pousser instantanement les modifications aux autres clients.

Dans ce projet :
- endpoint serveur : `@ServerEndpoint("/ws/doc/{docId}")` ;
- client JS : `new WebSocket(url)` ;
- format echange : JSON avec champ `type`.

Exemples de messages :
- client -> serveur : `content_update`, `chat_message`, `save_request` ;
- serveur -> clients : `init`, `content_update`, `chat_message`, `saved`, etc.

### 21.6 Tomcat 10

Tomcat est le conteneur qui :
- charge le WAR ;
- instancie servlets et endpoint WebSocket ;
- gere sessions HTTP ;
- sert les ressources statiques (`/css`, `/js`) ;
- applique les mappings de `web.xml`.

Point critique vu pendant debug :
- si un mapping servlet capture trop large (`/`), les assets statiques peuvent etre rediriges.

### 21.7 Maven

Maven gere :
- les dependances (`pom.xml`) ;
- la compilation Java ;
- la creation du WAR final.

Commandes typiques :
- `mvn clean package` -> produit `target/CollabDocs.war`.

### 21.8 Bulma + CSS custom

Bulma fournit une base de composants CSS (navbar, buttons, forms, tables).
Le fichier `style.css` ajoute le theme visuel CollabDocs :
- couleurs editeur/chat ;
- layout editeur split ;
- responsive mobile ;
- notifications toast.

### 21.9 JavaScript Frontend

Le fichier `editor.js` :
- gere la connexion WS ;
- attache les listeners UI ;
- envoie/recoit les messages JSON ;
- met a jour DOM (texte, chat, presence, statut).

Il fonctionne en IIFE (`(function(){...})();`) avec `use strict` pour eviter pollution globale.

---

## 22) Documentation exhaustive fichier par fichier

Ce chapitre detaille chaque fichier source principal, avec ses fonctions/methodes.

## 22.1 Backend Java

### Fichier: `src/main/java/dao/DBConnection.java`

Role :
- fournir une connexion JDBC partagee.

Methodes :
- `getInstance()` :
  - cree l'instance singleton si absente.
- `getConnection()` :
  - renvoie une connexion valide ;
  - tente reconnect si `null`, `closed` ou invalide.
- `close()` :
  - ferme la connexion et reset singleton.

Variables importantes :
- `DB_URL`, `DB_USER`, `DB_PASSWORD`, `DRIVER_CLASS`.

### Fichier: `src/main/java/dao/UserDAO.java`

Role :
- operations SQL sur la table `users`.

Methodes publiques :
- `createUser(User user)` :
  - insert user ;
  - recupere ID auto-genere.
- `findById(int id)` :
  - select par ID.
- `findByUsername(String username)` :
  - select par username.
- `usernameExists(String username)` :
  - retourne true si deja present.
- `emailExists(String email)` :
  - idem pour email.
- `getAllUsers()` :
  - liste complete ordonnee.
- `updateRole(int userId, String role)` :
  - change role.
- `deleteUser(int id)` :
  - supprime user.

Methodes privees :
- `getConn()` :
  - helper connexion.
- `map(ResultSet rs)` :
  - convertit ligne SQL -> `User`.

### Fichier: `src/main/java/dao/DocumentDAO.java`

Role :
- CRUD + historique pour `documents`.

Methodes publiques :
- `createDocument(Document doc)` :
  - genere `shareToken` si absent ;
  - insert en DB.
- `findById(int id)` :
  - charge doc + owner username.
- `findByShareToken(String token)` :
  - charge doc via token.
- `findByOwner(int userId)` :
  - docs proprietaire.
- `findAccessibleByUser(int userId)` :
  - owner + permissions (union SQL).
- `findSharedWithUser(int userId)` :
  - docs partages (non owner).
- `getAllDocuments()` :
  - liste admin.
- `updateContent(int docId, String content)` :
  - ecrit contenu courant.
- `updateTitle(int docId, String title)` :
  - met a jour titre.
- `deleteDocument(int docId)` :
  - suppression.
- `saveHistory(int docId, String content, Integer savedBy)` :
  - snapshot version.
- `getHistory(int docId)` :
  - retourne liste d'objets `[id, saved_at, username, content]`.

Methodes privees :
- `getConn()`
- `map(ResultSet rs)`

### Fichier: `src/main/java/dao/PermissionDAO.java`

Role :
- gestion table `permissions`.

Methodes :
- `addPermission(int userId, int docId, String level)` :
  - insert/update (upsert).
- `getPermission(int userId, int docId)` :
  - retourne `read`/`write` ou `null`.
- `getUsersForDocument(int docId)` :
  - liste des collaborateurs.
- `removePermission(int userId, int docId)` :
  - retire partage.

### Fichier: `src/main/java/dao/MessageDAO.java`

Role :
- gestion chat persiste.

Methodes :
- `saveMessage(Message message)` :
  - insert message.
- `getMessages(int docId, int limit)` :
  - lit N derniers messages (ordre final chronologique).
- `countMessages(int docId)` :
  - nombre total messages doc.
- `map(ResultSet rs)` :
  - ligne SQL -> `Message`.

### Fichier: `src/main/java/model/User.java`

Methodes metier :
- getters/setters standards
- `isAdmin()` : role admin ?
- `toString()`

### Fichier: `src/main/java/model/Document.java`

Methodes metier :
- getters/setters standards
- `isPublic()`
- `hasPassword()`
- `toString()`

### Fichier: `src/main/java/model/Permission.java`

Methodes metier :
- getters/setters
- `canWrite()`
- `toString()`

### Fichier: `src/main/java/model/Message.java`

Methodes :
- getters/setters
- `toString()`

### Fichier: `src/main/java/util/PasswordUtil.java`

Methodes :
- `hash(String plainPassword)`
- `verify(String plainPassword, String storedHash)`
- `bytesToHex(byte[] bytes)` (privee)

### Fichier: `src/main/java/filter/AuthFilter.java`

Methodes du filtre :
- `init(FilterConfig)` (vide)
- `doFilter(ServletRequest, ServletResponse, FilterChain)` :
  - cast HTTP ;
  - check session user ;
  - redirect login si absent ;
  - check admin si URL `/admin` ;
  - sinon `chain.doFilter`.
- `destroy()` (vide)

### Fichier: `src/main/java/controller/IndexServlet.java`

Methodes :
- `doGet(...)` :
  - session user ? `/home` : `/login`.

### Fichier: `src/main/java/controller/LoginServlet.java`

Methodes :
- `doGet(...)` :
  - si deja connecte -> home ;
  - sinon forward login JSP.
- `doPost(...)` :
  - lire username/password ;
  - validations de base ;
  - charger user ;
  - verifier hash ;
  - creer session + redirect home ;
  - sinon forward login avec erreur.

### Fichier: `src/main/java/controller/LogoutServlet.java`

Methodes :
- `doGet(...)` :
  - invalide session ;
  - redirect login.
- `doPost(...)` :
  - delegue a `doGet`.

### Fichier: `src/main/java/controller/RegisterServlet.java`

Methodes :
- `doGet(...)` :
  - si connecte -> home ;
  - sinon forward register JSP.
- `doPost(...)` :
  - lire form ;
  - valider format ;
  - check doublons username/email ;
  - creer user ;
  - login auto + redirect home.
- `setErrorAndForward(...)` :
  - helper pour repop + message.
- `trim(String s)` :
  - helper null-safe.

### Fichier: `src/main/java/controller/HomeServlet.java`

Methodes :
- `doGet(...)` :
  - charge `myDocs` ;
  - charge `sharedDocs` ;
  - forward vers home.

### Fichier: `src/main/java/controller/DocumentServlet.java`

Methodes entrees :
- `doGet(...)` :
  - route `/new` ou `/share`.
- `doPost(...)` :
  - route `/new`, `/delete`, `/share`.

Methodes internes :
- `handleCreate(...)`
- `handleDelete(...)`
- `handleSharePage(...)`
- `handleShareUpdate(...)`
- `trim(String)`
- `parseId(String)`

### Fichier: `src/main/java/controller/AdminServlet.java`

Methodes entrees :
- `doGet(...)`
- `doPost(...)`

Methodes internes :
- `loadDashboard(...)`
- `handleUserAction(...)`
- `handleDocAction(...)`
- `parseId(String)`

### Fichier: `src/main/java/controller/EditorServlet.java`

Methodes :
- `doGet(...)` :
  - resolution doc (id ou token) ;
  - controles d'acces ;
  - controle mdp doc ;
  - calcul `canEdit` ;
  - chargement chat/historique ;
  - forward `editor.jsp`.
- `canView(User, Document, HttpServletRequest)` :
  - logique lecture (public/proprio/admin/permission/lien).
- `canEdit(User, Document)` :
  - logique ecriture (proprio/admin/permission write).

### Fichier: `src/main/java/websocket/HttpSessionConfigurator.java`

Methodes :
- `modifyHandshake(...)` :
  - copie user HTTP -> proprietes session WS.

### Fichier: `src/main/java/websocket/DocumentWebSocket.java`

Attributs importants :
- `ROOMS` : map des sessions par document.
- `documentDAO`, `messageDAO`.

Methodes lifecycle :
- `onOpen(Session, int docId)`
- `onMessage(String, Session, int docId)`
- `onClose(Session, int docId)`
- `onError(Session, Throwable, int docId)`

Methodes utilitaires :
- `broadcastAll(int docId, String message)`
- `broadcastExcept(int docId, Session exclude, String message)`
- `sendTo(Session session, String message)`

Classe interne :
- `SessionWrapper`
  - champs `session`, `username`, `user`
  - `equals/hashCode` bases sur `session.getId()`

---

## 22.2 Frontend / vues / config web

### Fichier: `src/main/webapp/WEB-INF/web.xml`

Contient :
- session-config ;
- filter + mappings ;
- servlet declarations ;
- servlet mappings ;
- error pages ;
- welcome file.

### Fichier: `src/main/webapp/index.jsp`

Contient :
- un forward serveur vers `/`.

### Fichier: `src/main/webapp/WEB-INF/views/layout/header.jsp`

Contient :
- head HTML ;
- import Bulma + CSS projet ;
- navbar ;
- script burger menu :
  - callback `DOMContentLoaded`
  - toggle classes `is-active`.

### Fichier: `src/main/webapp/WEB-INF/views/layout/footer.jsp`

Contient :
- footer visuel global ;
- fermeture du document HTML.

### Fichier: `src/main/webapp/WEB-INF/views/auth/login.jsp`

Fonctions/page :
- formulaire login (username/password) ;
- affichage erreurs via JSTL ;
- liens login/register.

### Fichier: `src/main/webapp/WEB-INF/views/auth/register.jsp`

Fonctions/page :
- formulaire inscription ;
- validations HTML5 (`minlength`, `required`) ;
- affichage erreurs serveur.

### Fichier: `src/main/webapp/WEB-INF/views/home.jsp`

Fonctions/page :
- tableau docs proprietaire ;
- tableau docs partages ;
- boutons ouvrir/partager/supprimer.

### Fichier: `src/main/webapp/WEB-INF/views/document-new.jsp`

Fonctions/page :
- creation document ;
- choix accessType ;
- option mot de passe document.

### Fichier: `src/main/webapp/WEB-INF/views/document-share.jsp`

Fonctions/page :
- affichage URL partage ;
- listing permissions ;
- ajout/retrait collaborateur.

Fonctions JavaScript locales :
- `copyShareLink()`
- `showToast(msg)`

### Fichier: `src/main/webapp/WEB-INF/views/admin.jsp`

Fonctions/page :
- stats globales ;
- gestion utilisateurs (role/suppression) ;
- suppression documents.

### Fichier: `src/main/webapp/WEB-INF/views/error.jsp`

Fonctions/page :
- rendu conditionnel selon code HTTP (403/404/autre) ;
- affichage detail throwable si disponible.

### Fichier: `src/main/webapp/WEB-INF/views/editor.jsp`

Fonctions/page :
- bloc mdp si doc protege ;
- sinon ecran editeur complet.

Injection data JS :
- variable globale `COLLAB_CONFIG`
- variable globale `HISTORY_DATA`

Elements clefs :
- textarea `docContent`
- chat (`chatMessages`, `chatForm`)
- statut connexion `connStatus`
- modal historique

### Fichier: `src/main/webapp/css/style.css`

Organisation du style :
- variables CSS (`:root`) ;
- layout global ;
- navbar/footer ;
- toasts ;
- section editeur ;
- section chat ;
- media query mobile ;
- ajustements home/admin.

### Fichier: `src/main/webapp/js/editor.js`

Fonctions definies (ordre du fichier) :
- `connect()`
- `scheduleReconnect()`
- `handleMessage(msg)`
- `send(obj)`
- listeners `input/click/submit/keydown`
- `appendChatMessage(username, text, time)`
- `appendSystemMessage(text)`
- `scrollChatToBottom()`
- `updateUserCount(count)`
- `updatePresence()`
- `setConnStatus(state)`
- `showSaveStatus(message)`
- `showNotification(message, cssClass)`
- `window.openHistory()`
- `window.closeHistory()`
- `window.restoreVersion(histId, btn)`
- `setTextareaValue(value)`
- `formatTime(ts)`
- `buildWsCandidates()`
- call final `connect()`

---

## 23) Flux HTTP + WS ultra detaille

### 23.1 Flux "ouvrir un doc et commencer a ecrire"

1. navigateur GET `/editor/2`
2. `AuthFilter` verifie user connecte
3. `EditorServlet#doGet` verifie acces
4. servlet injecte `doc`, `canEdit`, `messages`, `history`
5. servlet forward `editor.jsp`
6. JSP injecte `COLLAB_CONFIG.wsUrl`
7. navigateur charge `editor.js`
8. `editor.js` appelle `connect()`
9. `new WebSocket(wsUrl)` handshake
10. serveur `DocumentWebSocket#onOpen`
11. serveur envoie message `init`
12. client `handleMessage('init')` remplit textarea
13. user tape -> event input
14. debounce -> `send({type:'content_update', ...})`
15. serveur `onMessage(content_update)` broadcast aux autres
16. autres clients recoivent et mettent a jour leur textarea

### 23.2 Flux "chat"

1. submit formulaire chat
2. JS envoie `chat_message`
3. serveur sauvegarde `messages`
4. serveur broadcast `chat_message` a tous
5. chaque client ajoute message au DOM

### 23.3 Flux "sauvegarde manuelle"

1. click bouton ou Ctrl+S
2. JS envoie `save_request`
3. serveur met a jour `documents.content`
4. serveur insert `document_history`
5. serveur broadcast `saved` avec timestamp
6. client affiche "Sauvegarde a HH:mm"

---

## 24) Contrats de donnees (formats)

### 24.1 Objet session HTTP

Cle session :
- `"user"` -> instance `User`

### 24.2 Attributs request utilises par JSP

Exemples :
- `doc`, `canEdit`, `permLevel`, `messages`, `history`
- `myDocs`, `sharedDocs`
- `users`, `documents`, `totalUsers`, etc.
- `error`, `username`, `email`

### 24.3 Messages WebSocket JSON

Client -> serveur :
- `{"type":"content_update","content":"..."}`
- `{"type":"chat_message","text":"...","username":"..."}`
- `{"type":"save_request","content":"..."}`
- `{"type":"title_update","title":"..."}`

Serveur -> client :
- `{"type":"init","content":"...","count":N}`
- `{"type":"content_update","content":"...","sender":"..."}`
- `{"type":"chat_message","text":"...","username":"...","time":"HH:mm"}`
- `{"type":"saved","timestamp":"yyyy-MM-dd HH:mm:ss"}`
- `{"type":"user_joined",...}`
- `{"type":"user_left",...}`
- `{"type":"error","message":"..."}`

---

## 25) Explication "pour debutant" des choix de conception

Pourquoi DAO separe ?
- pour eviter SQL dans les servlets ;
- pour pouvoir changer SQL sans toucher vues/controllers.

Pourquoi JSP dans `WEB-INF` ?
- pour empecher acces direct ;
- forcer passage par servlet (controle d'acces, preparation data).

Pourquoi WebSocket en plus de HTTP ?
- HTTP sert pages/actions ponctuelles ;
- WS sert synchro instantanee multi-utilisateurs.

Pourquoi `PreparedStatement` ?
- securite (SQL injection) ;
- typage parametres ;
- lisibilite.

Pourquoi `sendRedirect` vs `forward` ?
- `forward` : rester meme requete, rendre une JSP ;
- `sendRedirect` : demande au navigateur de refaire une requete sur une autre URL.

---

## 26) Annexes de lecture recommandees (ordre d'apprentissage)

Ordre conseille pour comprendre vite :
1. `web.xml`
2. `AuthFilter`
3. `LoginServlet` / `RegisterServlet`
4. `HomeServlet`
5. `DocumentServlet`
6. `EditorServlet`
7. `editor.jsp`
8. `editor.js`
9. `DocumentWebSocket`
10. DAO + SQL schema

---

## 27) Conclusion

Cette documentation couvre le projet au niveau :
- architecture ;
- techno ;
- base ;
- routes ;
- fichiers ;
- methodes/fonctions ;
- flux runtime HTTP et WebSocket.

Si tu veux une version encore plus "cours", je peux ajouter un **chapitre 28** avec :
- pseudo-code de chaque methode,
- diagrammes de sequence texte (etape par etape),
- et mini-exercices corriges pour t'entrainer.

---

Fin du rapport.
