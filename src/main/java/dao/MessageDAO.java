package com.collabdocs.dao;

import com.collabdocs.model.Message;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class MessageDAO {

    private static final Logger LOG = Logger.getLogger(MessageDAO.class.getName());

    private Connection getConn() {
        return DBConnection.getInstance().getConnection();
    }

    // ------------------------------------------------------------------
    // CREATE
    // ------------------------------------------------------------------

    /**
     * Insère un message de chat en base.
     *
     * @param message le message à persister
     * @return true si l'insertion a réussi
     */
    public boolean saveMessage(Message message) {
        String sql = "INSERT INTO messages (document_id, user_id, username, content) VALUES (?, ?, ?, ?)";
        try (PreparedStatement ps = getConn().prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, message.getDocumentId());
            if (message.getUserId() != null) {
                ps.setInt(2, message.getUserId());
            } else {
                ps.setNull(2, Types.INTEGER);
            }
            ps.setString(3, message.getUsername());
            ps.setString(4, message.getContent());
            int rows = ps.executeUpdate();
            if (rows > 0) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) message.setId(rs.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "saveMessage() — " + e.getMessage(), e);
        }
        return false;
    }

    // ------------------------------------------------------------------
    // READ
    // ------------------------------------------------------------------

    /**
     * Retourne les N derniers messages d'un document (ordre chronologique).
     *
     * @param docId l'identifiant du document
     * @param limit nombre maximum de messages à retourner
     */
    public List<Message> getMessages(int docId, int limit) {
        List<Message> list = new ArrayList<>();
        String sql = "SELECT * FROM (SELECT * FROM messages WHERE document_id = ? "
                   + "ORDER BY sent_at DESC LIMIT ?) AS sub ORDER BY sent_at ASC";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, docId);
            ps.setInt(2, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "getMessages() — " + e.getMessage(), e);
        }
        return list;
    }

    /** Retourne le nombre total de messages pour un document. */
    public int countMessages(int docId) {
        String sql = "SELECT COUNT(*) FROM messages WHERE document_id = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, docId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "countMessages() — " + e.getMessage(), e);
        }
        return 0;
    }

    // ------------------------------------------------------------------
    // Mapping ResultSet → Message
    // ------------------------------------------------------------------

    private Message map(ResultSet rs) throws SQLException {
        Message m = new Message();
        m.setId(rs.getInt("id"));
        m.setDocumentId(rs.getInt("document_id"));
        int uid = rs.getInt("user_id");
        m.setUserId(rs.wasNull() ? null : uid);
        m.setUsername(rs.getString("username"));
        m.setContent(rs.getString("content"));
        m.setSentAt(rs.getTimestamp("sent_at"));
        return m;
    }
}
