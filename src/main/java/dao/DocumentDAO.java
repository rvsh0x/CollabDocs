package com.collabdocs.dao;

import com.collabdocs.model.Document;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

public class DocumentDAO {

    private static final Logger LOG = Logger.getLogger(DocumentDAO.class.getName());

    private static final List<String> VALID_TYPES = java.util.Arrays.asList(
        "CODE", "PIXELART", "RICHTEXT", "SPREADSHEET",
        "PRESENTATION", "PLANNING", "MINDMAP", "DIAGRAM"
    );

    private Connection getConn() {
        return DBConnection.getInstance().getConnection();
    }

    // ------------------------------------------------------------------
    // CREATE
    // ------------------------------------------------------------------

    public boolean createDocument(Document doc) {
        if (doc.getShareToken() == null || doc.getShareToken().isEmpty()) {
            doc.setShareToken(UUID.randomUUID().toString().replace("-", ""));
        }
        if (doc.getDocType() == null || !VALID_TYPES.contains(doc.getDocType())) {
            doc.setDocType("CODE");
        }
        boolean hasPwd = doc.getPasswordHash() != null && !doc.getPasswordHash().isEmpty();

        String sql = "INSERT INTO documents "
                   + "(title, content, owner_id, access_type, share_token, has_password, password_hash, doc_type) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement ps = getConn().prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, doc.getTitle());
            ps.setString(2, doc.getContent() != null ? doc.getContent() : "");
            ps.setInt(3, doc.getOwnerId());
            ps.setString(4, doc.getAccessType() != null ? doc.getAccessType() : "link");
            ps.setString(5, doc.getShareToken());
            ps.setBoolean(6, hasPwd);
            ps.setString(7, doc.getPasswordHash());
            ps.setString(8, doc.getDocType());
            int rows = ps.executeUpdate();
            if (rows > 0) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) doc.setId(rs.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "createDocument() — " + e.getMessage(), e);
        }
        return false;
    }

    // ------------------------------------------------------------------
    // READ
    // ------------------------------------------------------------------

    public Document findById(int id) {
        String sql = "SELECT d.*, u.username AS owner_username FROM documents d "
                   + "JOIN users u ON d.owner_id = u.id WHERE d.id = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return map(rs);
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "findById() — " + e.getMessage(), e);
        }
        return null;
    }

    public Document findByShareToken(String token) {
        String sql = "SELECT d.*, u.username AS owner_username FROM documents d "
                   + "JOIN users u ON d.owner_id = u.id WHERE d.share_token = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setString(1, token);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return map(rs);
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "findByShareToken() — " + e.getMessage(), e);
        }
        return null;
    }

    public List<Document> findByOwner(int userId) {
        List<Document> list = new ArrayList<>();
        String sql = "SELECT d.*, u.username AS owner_username FROM documents d "
                   + "JOIN users u ON d.owner_id = u.id "
                   + "WHERE d.owner_id = ? ORDER BY d.updated_at DESC";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "findByOwner() — " + e.getMessage(), e);
        }
        return list;
    }

    public List<Document> findAccessibleByUser(int userId) {
        List<Document> list = new ArrayList<>();
        String sql = "SELECT DISTINCT d.*, u.username AS owner_username FROM documents d "
                   + "JOIN users u ON d.owner_id = u.id "
                   + "WHERE d.owner_id = ? "
                   + "UNION "
                   + "SELECT DISTINCT d.*, u.username AS owner_username FROM documents d "
                   + "JOIN users u ON d.owner_id = u.id "
                   + "JOIN permissions p ON p.document_id = d.id "
                   + "WHERE p.user_id = ? "
                   + "ORDER BY updated_at DESC";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "findAccessibleByUser() — " + e.getMessage(), e);
        }
        return list;
    }

    public List<Document> findSharedWithUser(int userId) {
        List<Document> list = new ArrayList<>();
        String sql = "SELECT d.*, u.username AS owner_username FROM documents d "
                   + "JOIN users u ON d.owner_id = u.id "
                   + "JOIN permissions p ON p.document_id = d.id "
                   + "WHERE p.user_id = ? AND d.owner_id != ? "
                   + "ORDER BY d.updated_at DESC";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "findSharedWithUser() — " + e.getMessage(), e);
        }
        return list;
    }

    public List<Document> getAllDocuments() {
        List<Document> list = new ArrayList<>();
        String sql = "SELECT d.*, u.username AS owner_username FROM documents d "
                   + "JOIN users u ON d.owner_id = u.id ORDER BY d.updated_at DESC";
        try (PreparedStatement ps = getConn().prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(map(rs));
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "getAllDocuments() — " + e.getMessage(), e);
        }
        return list;
    }

    // ------------------------------------------------------------------
    // UPDATE
    // ------------------------------------------------------------------

    public boolean updateContent(int docId, String content) {
        String sql = "UPDATE documents SET content = ? WHERE id = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setString(1, content);
            ps.setInt(2, docId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "updateContent() — " + e.getMessage(), e);
        }
        return false;
    }

    public boolean updateTitle(int docId, String title) {
        String sql = "UPDATE documents SET title = ? WHERE id = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setString(1, title);
            ps.setInt(2, docId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "updateTitle() — " + e.getMessage(), e);
        }
        return false;
    }

    // ------------------------------------------------------------------
    // DELETE
    // ------------------------------------------------------------------

    public boolean deleteDocument(int docId) {
        String sql = "DELETE FROM documents WHERE id = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, docId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "deleteDocument() — " + e.getMessage(), e);
        }
        return false;
    }

    // ------------------------------------------------------------------
    // HISTORIQUE
    // ------------------------------------------------------------------

    public boolean saveHistory(int docId, String content, Integer savedBy) {
        String sql = "INSERT INTO document_history (document_id, content, saved_by) VALUES (?, ?, ?)";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, docId);
            ps.setString(2, content);
            if (savedBy != null) ps.setInt(3, savedBy); else ps.setNull(3, Types.INTEGER);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "saveHistory() — " + e.getMessage(), e);
        }
        return false;
    }

    /** Retourne l'historique d'un document. Chaque entrée : [id, savedAt, username, content]. */
    public List<Object[]> getHistory(int docId) {
        List<Object[]> list = new ArrayList<>();
        String sql = "SELECT dh.id, dh.saved_at, COALESCE(u.username, 'Système') AS username, dh.content "
                   + "FROM document_history dh "
                   + "LEFT JOIN users u ON dh.saved_by = u.id "
                   + "WHERE dh.document_id = ? ORDER BY dh.saved_at DESC";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, docId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new Object[]{
                        rs.getInt("id"),
                        rs.getTimestamp("saved_at"),
                        rs.getString("username"),
                        rs.getString("content")
                    });
                }
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "getHistory() — " + e.getMessage(), e);
        }
        return list;
    }

    /** Retourne le contenu d'une version de l'historique. */
    public String getHistoryContent(int historyId) {
        String sql = "SELECT content FROM document_history WHERE id = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, historyId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("content");
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "getHistoryContent() — " + e.getMessage(), e);
        }
        return null;
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    /** Retourne un JSON d'initialisation par défaut selon le type. */
    public static String defaultContent(String docType) {
        switch (docType == null ? "CODE" : docType) {
            case "PIXELART": {
                StringBuilder sb = new StringBuilder();
                sb.append("{\"width\":32,\"height\":32,");
                sb.append("\"palette\":[\"#ffffff\",\"#000000\",\"#ff0000\",\"#00cc00\",\"#0000ff\",");
                sb.append("\"#ffff00\",\"#ff8800\",\"#ff00ff\",\"#00ffff\",\"#aaaaaa\"],");
                sb.append("\"pixels\":[");
                for (int r = 0; r < 32; r++) {
                    if (r > 0) sb.append(",");
                    sb.append("[");
                    for (int c = 0; c < 32; c++) {
                        if (c > 0) sb.append(",");
                        sb.append("0");
                    }
                    sb.append("]");
                }
                sb.append("]}");
                return sb.toString();
            }
            case "RICHTEXT":
                return "{\"delta\":{\"ops\":[{\"insert\":\"\\n\"}]}}";
            case "SPREADSHEET":
                return "{\"rows\":20,\"cols\":10,\"cells\":{}}";
            case "PRESENTATION":
                return "{\"slides\":[{\"id\":1,\"title\":\"Nouvelle diapositive\",\"content\":\"\",\"bg\":\"#ffffff\"}]}";
            case "PLANNING":
                return "{\"tasks\":[]}";
            case "MINDMAP":
                return "{\"nodes\":[{\"id\":\"root\",\"label\":\"Idée centrale\",\"x\":400,\"y\":300,\"parent\":null}],\"edges\":[]}";
            case "DIAGRAM":
                return "{\"nodes\":[],\"edges\":[]}";
            default: // CODE
                return "{\"language\":\"java\",\"text\":\"\"}";
        }
    }

    // ------------------------------------------------------------------
    // Mapping ResultSet → Document
    // ------------------------------------------------------------------

    private Document map(ResultSet rs) throws SQLException {
        Document d = new Document();
        d.setId(rs.getInt("id"));
        d.setTitle(rs.getString("title"));
        d.setContent(rs.getString("content"));
        d.setOwnerId(rs.getInt("owner_id"));
        d.setAccessType(rs.getString("access_type"));
        d.setShareToken(rs.getString("share_token"));
        d.setHasPasswordDb(rs.getBoolean("has_password"));
        d.setPasswordHash(rs.getString("password_hash"));
        d.setDocType(rs.getString("doc_type"));
        d.setCreatedAt(rs.getTimestamp("created_at"));
        d.setUpdatedAt(rs.getTimestamp("updated_at"));
        try { d.setOwnerUsername(rs.getString("owner_username")); } catch (SQLException ignored) {}
        return d;
    }
}
