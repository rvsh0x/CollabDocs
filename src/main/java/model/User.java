package com.collabdocs.model;

import java.sql.Timestamp;

public class User {

    private int id;
    private String username;
    private String email;
    private String passwordHash;
    private String role;          // 'admin' | 'registered' | 'visitor'
    private Timestamp createdAt;

    public User() {}

    public User(String username, String email, String passwordHash, String role) {
        this.username     = username;
        this.email        = email;
        this.passwordHash = passwordHash;
        this.role         = role;
    }

    // ---- Getters / Setters ----

    public int getId()                      { return id; }
    public void setId(int id)               { this.id = id; }

    public String getUsername()             { return username; }
    public void setUsername(String u)       { this.username = u; }

    public String getEmail()                { return email; }
    public void setEmail(String e)          { this.email = e; }

    public String getPasswordHash()         { return passwordHash; }
    public void setPasswordHash(String h)   { this.passwordHash = h; }

    public String getRole()                 { return role; }
    public void setRole(String r)           { this.role = r; }

    public Timestamp getCreatedAt()         { return createdAt; }
    public void setCreatedAt(Timestamp t)   { this.createdAt = t; }

    /** Retourne true si l'utilisateur possède le rôle admin. */
    public boolean isAdmin() {
        return "admin".equals(role);
    }

    @Override
    public String toString() {
        return "User{id=" + id + ", username='" + username + "', role='" + role + "'}";
    }
}
