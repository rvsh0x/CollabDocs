package com.collabdocs.model;

import java.sql.Timestamp;

public class Message {

    private int id;
    private int documentId;
    private Integer userId;       // peut être null (visiteur anonyme)
    private String username;      // dénormalisé pour affichage rapide
    private String content;
    private Timestamp sentAt;

    public Message() {}

    public Message(int documentId, Integer userId, String username, String content) {
        this.documentId = documentId;
        this.userId     = userId;
        this.username   = username;
        this.content    = content;
    }

    // ---- Getters / Setters ----

    public int getId()                      { return id; }
    public void setId(int id)               { this.id = id; }

    public int getDocumentId()              { return documentId; }
    public void setDocumentId(int d)        { this.documentId = d; }

    public Integer getUserId()              { return userId; }
    public void setUserId(Integer u)        { this.userId = u; }

    public String getUsername()             { return username; }
    public void setUsername(String u)       { this.username = u; }

    public String getContent()              { return content; }
    public void setContent(String c)        { this.content = c; }

    public Timestamp getSentAt()            { return sentAt; }
    public void setSentAt(Timestamp t)      { this.sentAt = t; }

    @Override
    public String toString() {
        return "Message{id=" + id + ", username='" + username + "', documentId=" + documentId + "}";
    }
}
