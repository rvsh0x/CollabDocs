package com.collabdocs.dao;

import java.sql.*;
import java.util.logging.*;

public class RestoreRequestDAO {

    private static final Logger LOG = Logger.getLogger(RestoreRequestDAO.class.getName());

    private Connection getConn() {
        return DBConnection.getInstance().getConnection();
    }

    /**
     * Crée une demande de restauration.
     * @return l'id généré, ou -1 en cas d'erreur.
     */
    public int createRequest(int docId, int requestedBy, int historyId) {
        String sql = "INSERT INTO restore_requests (document_id, requested_by, history_id) VALUES (?,?,?)";
        try (PreparedStatement ps = getConn().prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, docId);
            ps.setInt(2, requestedBy);
            ps.setInt(3, historyId);
            if (ps.executeUpdate() > 0) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) return rs.getInt(1);
                }
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "createRequest() — " + e.getMessage(), e);
        }
        return -1;
    }

    /**
     * Retourne la demande pending pour un document, ou null.
     * Object[]: {id, document_id, requested_by, history_id, status, requested_at, requester_username}
     */
    public Object[] getPendingRequest(int docId) {
        String sql = "SELECT rr.id, rr.document_id, rr.requested_by, rr.history_id, "
                   + "rr.status, rr.requested_at, u.username AS requester_username "
                   + "FROM restore_requests rr "
                   + "JOIN users u ON rr.requested_by = u.id "
                   + "WHERE rr.document_id=? AND rr.status='pending' "
                   + "ORDER BY rr.requested_at DESC LIMIT 1";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, docId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Object[]{
                        rs.getInt("id"),
                        rs.getInt("document_id"),
                        rs.getInt("requested_by"),
                        rs.getInt("history_id"),
                        rs.getString("status"),
                        rs.getTimestamp("requested_at"),
                        rs.getString("requester_username")
                    };
                }
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "getPendingRequest() — " + e.getMessage(), e);
        }
        return null;
    }

    /**
     * Retourne une demande par son id, avec le contenu de la version historique.
     * Object[]: {id, document_id, requested_by, history_id, status, requested_at,
     *            requester_username, history_content, history_saved_at}
     */
    public Object[] getRequestWithHistory(int requestId) {
        String sql = "SELECT rr.id, rr.document_id, rr.requested_by, rr.history_id, "
                   + "rr.status, rr.requested_at, u.username AS requester_username, "
                   + "dh.content AS history_content, dh.saved_at AS history_saved_at "
                   + "FROM restore_requests rr "
                   + "JOIN users u ON rr.requested_by = u.id "
                   + "JOIN document_history dh ON rr.history_id = dh.id "
                   + "WHERE rr.id=?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, requestId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Object[]{
                        rs.getInt("id"),
                        rs.getInt("document_id"),
                        rs.getInt("requested_by"),
                        rs.getInt("history_id"),
                        rs.getString("status"),
                        rs.getTimestamp("requested_at"),
                        rs.getString("requester_username"),
                        rs.getString("history_content"),
                        rs.getTimestamp("history_saved_at")
                    };
                }
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "getRequestWithHistory() — " + e.getMessage(), e);
        }
        return null;
    }

    public boolean approve(int requestId) {
        String sql = "UPDATE restore_requests SET status='approved', resolved_at=NOW() WHERE id=?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, requestId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "approve() — " + e.getMessage(), e);
        }
        return false;
    }

    public boolean reject(int requestId) {
        String sql = "UPDATE restore_requests SET status='rejected', resolved_at=NOW() WHERE id=?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, requestId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "reject() — " + e.getMessage(), e);
        }
        return false;
    }
}
