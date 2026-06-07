package com.collabdocs.dao;

import com.collabdocs.model.Permission;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class PermissionDAO {

    private static final Logger LOG = Logger.getLogger(PermissionDAO.class.getName());

    private Connection getConn() {
        return DBConnection.getInstance().getConnection();
    }

    // ------------------------------------------------------------------
    // CREATE / UPDATE
    // ------------------------------------------------------------------

    /**
     * Ajoute ou met à jour une permission (UPSERT).
     * Si la paire (userId, documentId) existe déjà, le niveau est mis à jour.
     */
    public boolean addPermission(int userId, int docId, String level) {
        String sql = "INSERT INTO permissions (user_id, document_id, level) VALUES (?, ?, ?) "
                   + "ON DUPLICATE KEY UPDATE level = VALUES(level)";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setInt(2, docId);
            ps.setString(3, level);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "addPermission() — " + e.getMessage(), e);
        }
        return false;
    }

    // ------------------------------------------------------------------
    // READ
    // ------------------------------------------------------------------

    /**
     * Retourne le niveau de permission d'un utilisateur sur un document,
     * ou null s'il n'en a pas.
     */
    public String getPermission(int userId, int docId) {
        String sql = "SELECT level FROM permissions WHERE user_id = ? AND document_id = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setInt(2, docId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("level");
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "getPermission() — " + e.getMessage(), e);
        }
        return null;
    }

    /**
     * Retourne la liste des utilisateurs qui ont une permission sur un document,
     * avec leur niveau.
     */
    public List<Permission> getUsersForDocument(int docId) {
        List<Permission> list = new ArrayList<>();
        String sql = "SELECT p.*, u.username FROM permissions p "
                   + "JOIN users u ON p.user_id = u.id "
                   + "WHERE p.document_id = ? ORDER BY u.username";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, docId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Permission perm = new Permission();
                    perm.setId(rs.getInt("id"));
                    perm.setUserId(rs.getInt("user_id"));
                    perm.setDocumentId(rs.getInt("document_id"));
                    perm.setLevel(rs.getString("level"));
                    perm.setUsername(rs.getString("username"));
                    list.add(perm);
                }
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "getUsersForDocument() — " + e.getMessage(), e);
        }
        return list;
    }

    // ------------------------------------------------------------------
    // DELETE
    // ------------------------------------------------------------------

    /** Supprime la permission d'un utilisateur sur un document. */
    public boolean removePermission(int userId, int docId) {
        String sql = "DELETE FROM permissions WHERE user_id = ? AND document_id = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setInt(2, docId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "removePermission() — " + e.getMessage(), e);
        }
        return false;
    }
}
