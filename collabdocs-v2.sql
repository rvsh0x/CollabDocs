-- =============================================================
--  CollabDocs V2 — Script SQL complet (DROP + CREATE + DATA)
--  Compatible MySQL 8 / MariaDB 10.5+
-- =============================================================

DROP DATABASE IF EXISTS collabdocs;
CREATE DATABASE collabdocs CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE collabdocs;

-- -------------------------------------------------------------
-- TABLE : users
-- -------------------------------------------------------------
CREATE TABLE users (
    id            INT PRIMARY KEY AUTO_INCREMENT,
    username      VARCHAR(50)  UNIQUE NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(64)  NOT NULL,
    role          ENUM('admin','registered','visitor') DEFAULT 'registered',
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -------------------------------------------------------------
-- TABLE : documents (V2 — ajout doc_type + has_password)
-- -------------------------------------------------------------
CREATE TABLE documents (
    id            INT PRIMARY KEY AUTO_INCREMENT,
    title         VARCHAR(200) NOT NULL,
    content       LONGTEXT     DEFAULT '',
    owner_id      INT          NOT NULL,
    access_type   ENUM('public','link','private') DEFAULT 'link',
    share_token   VARCHAR(64)  UNIQUE,
    has_password  BOOLEAN      DEFAULT FALSE,
    password_hash VARCHAR(64)  DEFAULT NULL,
    doc_type      ENUM('CODE','PIXELART','RICHTEXT','SPREADSHEET',
                       'PRESENTATION','PLANNING','MINDMAP','DIAGRAM')
                  NOT NULL DEFAULT 'CODE',
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- -------------------------------------------------------------
-- TABLE : permissions
-- -------------------------------------------------------------
CREATE TABLE permissions (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    user_id     INT NOT NULL,
    document_id INT NOT NULL,
    level       ENUM('read','write') NOT NULL,
    UNIQUE KEY uq_user_doc (user_id, document_id),
    FOREIGN KEY (user_id)     REFERENCES users(id)     ON DELETE CASCADE,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
);

-- -------------------------------------------------------------
-- TABLE : messages
-- -------------------------------------------------------------
CREATE TABLE messages (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    document_id INT         NOT NULL,
    user_id     INT         DEFAULT NULL,
    username    VARCHAR(50) NOT NULL,
    content     TEXT        NOT NULL,
    sent_at     TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)     REFERENCES users(id)     ON DELETE SET NULL
);

-- -------------------------------------------------------------
-- TABLE : document_history
-- -------------------------------------------------------------
CREATE TABLE document_history (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    document_id INT      NOT NULL,
    content     LONGTEXT NOT NULL,
    saved_by    INT      DEFAULT NULL,
    saved_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
    FOREIGN KEY (saved_by)    REFERENCES users(id)     ON DELETE SET NULL
);

-- -------------------------------------------------------------
-- TABLE : document_access_tokens (V2 — remplace le mdp en URL)
-- -------------------------------------------------------------
CREATE TABLE document_access_tokens (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    session_id  VARCHAR(128) NOT NULL,
    document_id INT          NOT NULL,
    granted_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at  TIMESTAMP NOT NULL,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
    INDEX idx_session_doc (session_id, document_id)
);

-- -------------------------------------------------------------
-- TABLE : restore_requests (V2 — demandes de restauration)
-- -------------------------------------------------------------
CREATE TABLE restore_requests (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    document_id  INT NOT NULL,
    requested_by INT NOT NULL,
    history_id   INT NOT NULL,
    status       ENUM('pending','approved','rejected') DEFAULT 'pending',
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at  TIMESTAMP DEFAULT NULL,
    FOREIGN KEY (document_id)  REFERENCES documents(id)        ON DELETE CASCADE,
    FOREIGN KEY (requested_by) REFERENCES users(id)            ON DELETE CASCADE,
    FOREIGN KEY (history_id)   REFERENCES document_history(id) ON DELETE CASCADE
);

-- =============================================================
-- DONNÉES DE TEST
-- SHA-256 pré-calculés (lowercase hex, 64 chars) :
--   admin123   → 240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9
--   alice123   → 4e40e8ffe0ee32fa53e139147ed559229a5930f89c2204706fc174beb36210b3
--   bob123     → 8d059c3640b97180dd2ee453e20d34ab0cb0f2eccbe87d01915a8e578a202b11
--   charlie123 → 1afda89737a745f15d42807d54f67c803727d75ce443b0f3a659531b38ae660f
-- =============================================================

INSERT INTO users (username, email, password_hash, role) VALUES
('admin',   'admin@collabdocs.local',   '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'admin'),
('alice',   'alice@collabdocs.local',   '4e40e8ffe0ee32fa53e139147ed559229a5930f89c2204706fc174beb36210b3', 'registered'),
('bob',     'bob@collabdocs.local',     '8d059c3640b97180dd2ee453e20d34ab0cb0f2eccbe87d01915a8e578a202b11', 'registered'),
('charlie', 'charlie@collabdocs.local', '1afda89737a745f15d42807d54f67c803727d75ce443b0f3a659531b38ae660f', 'registered');

-- Documents V2 — un par type avec contenu JSON pré-rempli
INSERT INTO documents (title, content, owner_id, access_type, share_token, doc_type) VALUES

-- 1. CODE (type par défaut, contenu Java)
(
  'Hello World — Java',
  '{"language":"java","text":"public class Hello {\n    public static void main(String[] args) {\n        System.out.println(\"Hello, CollabDocs!\");\n    }\n}"}',
  2, 'public', 'share-code-abc123', 'CODE'
),

-- 2. PIXELART (grille 16x16, palette réduite pour la démo)
(
  'Mon premier Pixel Art',
  '{"width":16,"height":16,"palette":["#ffffff","#000000","#ff0000","#00cc00","#0000ff","#ffff00","#ff8800","#ff00ff","#00ffff","#aaaaaa"],"pixels":[[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0],[0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0],[0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0],[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]}',
  2, 'public', 'share-pixelart-def456', 'PIXELART'
),

-- 3. RICHTEXT (format Delta Quill.js)
(
  'Guide de démarrage — CollabDocs',
  '{"delta":{"ops":[{"attributes":{"bold":true,"size":"large"},"insert":"Bienvenue dans CollabDocs V2"},{"insert":"\n\n"},{"insert":"CollabDocs est une plateforme d''édition collaborative en temps réel. Plusieurs utilisateurs peuvent travailler simultanément sur le même document.\n\n"},{"attributes":{"bold":true},"insert":"Fonctionnalités principales"},{"insert":"\n"},{"insert":"Édition collaborative en temps réel","attributes":{"list":"bullet"}},{"insert":"\n"},{"insert":"8 types d''éditeurs spécialisés","attributes":{"list":"bullet"}},{"insert":"\n"},{"insert":"Chat intégré","attributes":{"list":"bullet"}},{"insert":"\n"},{"insert":"Historique des versions avec restauration","attributes":{"list":"bullet"}},{"insert":"\n"},{"insert":"Gestion des accès et mots de passe","attributes":{"list":"bullet"}},{"insert":"\n\n"},{"insert":"Bonne collaboration !\n"}]}}',
  1, 'public', 'share-richtext-ghi789', 'RICHTEXT'
),

-- 4. SPREADSHEET (tableau budgétaire simple)
(
  'Budget Équipe — Avril 2026',
  '{"rows":10,"cols":5,"cells":{"0:0":{"value":"Poste","bold":true},"0:1":{"value":"Prévu","bold":true},"0:2":{"value":"Réalisé","bold":true},"0:3":{"value":"Écart","bold":true},"0:4":{"value":"Statut","bold":true},"1:0":{"value":"Infrastructure"},"1:1":{"value":"5000"},"1:2":{"value":"4800"},"1:3":{"value":"200"},"1:4":{"value":"OK"},"2:0":{"value":"Développement"},"2:1":{"value":"12000"},"2:2":{"value":"11500"},"2:3":{"value":"500"},"2:4":{"value":"OK"},"3:0":{"value":"Marketing"},"3:1":{"value":"3000"},"3:2":{"value":"3200"},"3:3":{"value":"-200"},"3:4":{"value":"Dépassé"},"4:0":{"value":"Formation"},"4:1":{"value":"2000"},"4:2":{"value":"1800"},"4:3":{"value":"200"},"4:4":{"value":"OK"},"5:0":{"value":"TOTAL","bold":true},"5:1":{"value":"22000","bold":true},"5:2":{"value":"21300","bold":true},"5:3":{"value":"700","bold":true},"5:4":{"value":"OK","bold":true}}}',
  3, 'link', 'share-spreadsheet-jkl012', 'SPREADSHEET'
),

-- 5. PRESENTATION (3 slides)
(
  'Présentation Projet CollabDocs',
  '{"slides":[{"id":1,"title":"CollabDocs V2","content":"<p>La plateforme d''édition collaborative de nouvelle génération</p><p>8 types de documents • Temps réel • Sécurisé</p>","bg":"#1e1e2e"},{"id":2,"title":"Architecture Technique","content":"<ul><li>Backend : Java 11 + Jakarta EE (Tomcat 10)</li><li>Base de données : MariaDB + JDBC</li><li>Temps réel : WebSocket</li><li>Frontend : HTML5 + CSS3 + JavaScript ES6</li></ul>","bg":"#ffffff"},{"id":3,"title":"Types d''éditeurs","content":"<p>CODE • PIXELART • RICHTEXT • SPREADSHEET</p><p>PRESENTATION • PLANNING • MINDMAP • DIAGRAM</p>","bg":"#f0f4ff"}]}',
  1, 'public', 'share-presentation-mno345', 'PRESENTATION'
),

-- 6. PLANNING (Gantt avec tâches)
(
  'Planning Sprint 3 — Mai 2026',
  '{"tasks":[{"id":1,"label":"Analyse des besoins","start":"2026-05-01","end":"2026-05-05","color":"#4CAF50","done":true},{"id":2,"label":"Design UI/UX","start":"2026-05-03","end":"2026-05-10","color":"#2196F3","done":true},{"id":3,"label":"Développement Backend","start":"2026-05-06","end":"2026-05-20","color":"#FF9800","done":false},{"id":4,"label":"Développement Frontend","start":"2026-05-11","end":"2026-05-22","color":"#9C27B0","done":false},{"id":5,"label":"Tests d''intégration","start":"2026-05-20","end":"2026-05-27","color":"#F44336","done":false},{"id":6,"label":"Déploiement","start":"2026-05-28","end":"2026-05-31","color":"#607D8B","done":false}]}',
  2, 'link', 'share-planning-pqr678', 'PLANNING'
),

-- 7. MINDMAP (carte mentale CollabDocs)
(
  'Architecture CollabDocs — Mind Map',
  '{"nodes":[{"id":"root","label":"CollabDocs","x":500,"y":300,"parent":null},{"id":"n1","label":"Backend","x":250,"y":150,"parent":"root"},{"id":"n2","label":"Frontend","x":750,"y":150,"parent":"root"},{"id":"n3","label":"Base de données","x":250,"y":450,"parent":"root"},{"id":"n4","label":"Sécurité","x":750,"y":450,"parent":"root"},{"id":"n1a","label":"Servlets","x":100,"y":80,"parent":"n1"},{"id":"n1b","label":"WebSocket","x":180,"y":200,"parent":"n1"},{"id":"n1c","label":"DAOs","x":320,"y":80,"parent":"n1"},{"id":"n2a","label":"JSP / JSTL","x":650,"y":80,"parent":"n2"},{"id":"n2b","label":"JavaScript","x":800,"y":80,"parent":"n2"},{"id":"n2c","label":"Bulma CSS","x":900,"y":200,"parent":"n2"},{"id":"n3a","label":"MariaDB","x":150,"y":520,"parent":"n3"},{"id":"n3b","label":"JDBC","x":320,"y":520,"parent":"n3"},{"id":"n4a","label":"SHA-256","x":680,"y":520,"parent":"n4"},{"id":"n4b","label":"Tokens","x":820,"y":520,"parent":"n4"}],"edges":[{"from":"root","to":"n1"},{"from":"root","to":"n2"},{"from":"root","to":"n3"},{"from":"root","to":"n4"},{"from":"n1","to":"n1a"},{"from":"n1","to":"n1b"},{"from":"n1","to":"n1c"},{"from":"n2","to":"n2a"},{"from":"n2","to":"n2b"},{"from":"n2","to":"n2c"},{"from":"n3","to":"n3a"},{"from":"n3","to":"n3b"},{"from":"n4","to":"n4a"},{"from":"n4","to":"n4b"}]}',
  1, 'public', 'share-mindmap-stu901', 'MINDMAP'
),

-- 8. DIAGRAM (diagramme de flux authentification)
(
  'Flux Authentification — Diagramme',
  '{"nodes":[{"id":"start","label":"Début","x":300,"y":50,"shape":"circle"},{"id":"login","label":"Formulaire\nde connexion","x":300,"y":150,"shape":"rect"},{"id":"check","label":"Identifiants\ncorrects ?","x":300,"y":270,"shape":"diamond"},{"id":"session","label":"Créer\nla session","x":500,"y":270,"shape":"rect"},{"id":"home","label":"Page d''accueil","x":500,"y":380,"shape":"rect"},{"id":"error","label":"Afficher\nl''erreur","x":100,"y":270,"shape":"rect"},{"id":"end","label":"Fin","x":500,"y":470,"shape":"circle"}],"edges":[{"id":"e1","from":"start","to":"login","label":""},{"id":"e2","from":"login","to":"check","label":"Soumettre"},{"id":"e3","from":"check","to":"session","label":"Oui"},{"id":"e4","from":"check","to":"error","label":"Non"},{"id":"e5","from":"error","to":"login","label":"Réessayer"},{"id":"e6","from":"session","to":"home","label":"Redirect"},{"id":"e7","from":"home","to":"end","label":""}]}',
  3, 'public', 'share-diagram-vwx234', 'DIAGRAM'
);

-- Permissions croisées
INSERT INTO permissions (user_id, document_id, level) VALUES
(3, 4, 'write'),  -- bob peut écrire sur Budget
(4, 4, 'read'),   -- charlie peut lire Budget
(1, 4, 'write'),  -- admin peut écrire sur Budget
(3, 6, 'write'),  -- bob peut écrire sur Planning
(4, 6, 'read'),   -- charlie peut lire Planning
(2, 5, 'write');  -- alice peut écrire sur Présentation

-- Messages de chat
INSERT INTO messages (document_id, user_id, username, content) VALUES
(1, 1, 'admin',   'Premier commit du code Java !'),
(1, 2, 'alice',   'Bel exemple, merci.'),
(3, 1, 'admin',   'Bienvenue dans le guide CollabDocs V2 !'),
(3, 2, 'alice',   'Super éditeur WYSIWYG !'),
(4, 2, 'alice',   'Budget mis à jour pour avril.'),
(4, 3, 'bob',     'OK, je vais vérifier les chiffres.'),
(5, 1, 'admin',   'Présentation prête pour la démo.'),
(6, 2, 'alice',   'Planning en cours, MAJ cette semaine.');

-- Historique initial
INSERT INTO document_history (document_id, content, saved_by) VALUES
(1, '{"language":"java","text":"// Hello World initial\nclass Hello {}"}', 2),
(3, '{"delta":{"ops":[{"insert":"Guide initial\\n"}]}}', 1),
(4, '{"rows":10,"cols":5,"cells":{}}', 3),
(6, '{"tasks":[{"id":1,"label":"Kick-off","start":"2026-05-01","end":"2026-05-02","color":"#4CAF50","done":true}]}', 2);
