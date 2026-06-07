package com.collabdocs.dao;

import java.sql.*;
import java.util.logging.*;

public class AccessTokenDAO {

    private static final Logger LOG = Logger.getLogger(AccessTokenDAO.class.getName());

    private Connection getConn() {
        return DBConnection.getInstance().getConnection();
    }

    /** Crée un token d'accès pour 8h. Remplace tout token existant pour cette session/doc. */
    public boolean grantToken(String sessionId, int docId) {
        String del = "DELETE FROM document_access_tokens WHERE session_id=? AND document_id=?";
        String ins = "INSERT INTO document_access_tokens (session_id, document_id, expires_at) "
                   + "VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 8 HOUR))";
        try {
            try (PreparedStatement ps = getConn().prepareStatement(del)) {
                ps.setString(1, sessionId);
                ps.setInt(2, docId);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = getConn().prepareStatement(ins)) {
                ps.setString(1, sessionId);
                ps.setInt(2, docId);
                return ps.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "grantToken() — " + e.getMessage(), e);
        }
        return false;
    }

    /** Retourne true si un token valide (non expiré) existe pour cette session/doc. */
    public boolean hasValidToken(String sessionId, int docId) {
        String sql = "SELECT id FROM document_access_tokens "
                   + "WHERE session_id=? AND document_id=? AND expires_at > NOW() LIMIT 1";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setString(1, sessionId);
            ps.setInt(2, docId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "hasValidToken() — " + e.getMessage(), e);
        }
        return false;
    }

    /** Supprime les tokens expirés. Appelé à chaque accès à l'éditeur. */
    public void cleanExpired() {
        String sql = "DELETE FROM document_access_tokens WHERE expires_at < NOW()";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.executeUpdate();
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "cleanExpired() — " + e.getMessage(), e);
        }
    }
}
