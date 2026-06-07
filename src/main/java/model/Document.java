package com.collabdocs.model;

import java.sql.Timestamp;

public class Document {

    private int id;
    private String title;
    private String content;
    private int ownerId;
    private String accessType;    // 'public' | 'link' | 'private'
    private String shareToken;
    private boolean hasPasswordDb;
    private String passwordHash;
    private String docType;       // 'CODE' | 'PIXELART' | 'RICHTEXT' | 'SPREADSHEET' | 'PRESENTATION' | 'PLANNING' | 'MINDMAP' | 'DIAGRAM'
    private Timestamp createdAt;
    private Timestamp updatedAt;

    // Champ dénormalisé pour l'affichage (non persisté)
    private String ownerUsername;

    public Document() {}

    public Document(String title, String content, int ownerId, String accessType) {
        this.title      = title;
        this.content    = content;
        this.ownerId    = ownerId;
        this.accessType = accessType;
    }

    // ---- Getters / Setters ----

    public int getId()                          { return id; }
    public void setId(int id)                   { this.id = id; }

    public String getTitle()                    { return title; }
    public void setTitle(String t)              { this.title = t; }

    public String getContent()                  { return content; }
    public void setContent(String c)            { this.content = c; }

    /**
     * Alias de getContent() utilisé dans les vues JSP pour l'injection JSON.
     * Retourne le contenu tel quel (JSON brut) sans transformation.
     * CORRECTION : cette méthode manquait — restore-review.jsp l'utilise
     * via ${doc.contentJson} pour injecter le contenu courant dans le JS de review.
     */
    public String getContentJson() {
        if (content == null || content.isEmpty()) {
            return "null";
        }
        // Échapper </script> pour éviter la fermeture prématurée du bloc script
        return content.replace("</script>", "<\\/script>");
    }

    public int getOwnerId()                     { return ownerId; }
    public void setOwnerId(int o)               { this.ownerId = o; }

    public String getAccessType()               { return accessType; }
    public void setAccessType(String a)         { this.accessType = a; }

    public String getShareToken()               { return shareToken; }
    public void setShareToken(String t)         { this.shareToken = t; }

    public boolean isHasPasswordDb()            { return hasPasswordDb; }
    public void setHasPasswordDb(boolean b)     { this.hasPasswordDb = b; }

    public String getPasswordHash()             { return passwordHash; }
    public void setPasswordHash(String h)       { this.passwordHash = h; }

    public String getDocType()                  { return docType; }
    public void setDocType(String t)            { this.docType = t != null ? t : "CODE"; }

    public Timestamp getCreatedAt()             { return createdAt; }
    public void setCreatedAt(Timestamp t)       { this.createdAt = t; }

    public Timestamp getUpdatedAt()             { return updatedAt; }
    public void setUpdatedAt(Timestamp t)       { this.updatedAt = t; }

    public String getOwnerUsername()            { return ownerUsername; }
    public void setOwnerUsername(String u)      { this.ownerUsername = u; }

    /** Indique si ce document est accessible publiquement. */
    public boolean isPublic() {
        return "public".equals(accessType);
    }

    /** Indique si ce document est protégé par un mot de passe. */
    public boolean hasPassword() {
        return hasPasswordDb || (passwordHash != null && !passwordHash.isEmpty());
    }

    @Override
    public String toString() {
        return "Document{id=" + id + ", title='" + title
                + "', docType='" + docType + "', accessType='" + accessType + "'}";
    }
}
