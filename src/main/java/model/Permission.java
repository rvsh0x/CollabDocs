package com.collabdocs.model;

public class Permission {

    private int id;
    private int userId;
    private int documentId;
    private String level;          // 'read' | 'write'

    // Champs dénormalisés pour l'affichage
    private String username;
    private String documentTitle;

    public Permission() {}

    public Permission(int userId, int documentId, String level) {
        this.userId     = userId;
        this.documentId = documentId;
        this.level      = level;
    }

    // ---- Getters / Setters ----

    public int getId()                          { return id; }
    public void setId(int id)                   { this.id = id; }

    public int getUserId()                      { return userId; }
    public void setUserId(int u)                { this.userId = u; }

    public int getDocumentId()                  { return documentId; }
    public void setDocumentId(int d)            { this.documentId = d; }

    public String getLevel()                    { return level; }
    public void setLevel(String l)              { this.level = l; }

    public String getUsername()                 { return username; }
    public void setUsername(String u)           { this.username = u; }

    public String getDocumentTitle()            { return documentTitle; }
    public void setDocumentTitle(String t)      { this.documentTitle = t; }

    public boolean canWrite() {
        return "write".equals(level);
    }

    @Override
    public String toString() {
        return "Permission{userId=" + userId + ", documentId=" + documentId + ", level='" + level + "'}";
    }
}
