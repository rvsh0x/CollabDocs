package com.collabdocs.dao;

import com.collabdocs.model.User;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class UserDAO {

    private static final Logger LOG = Logger.getLogger(UserDAO.class.getName());

    private Connection getConn() {
        return DBConnection.getInstance().getConnection();
    }

    // ------------------------------------------------------------------
    // CREATE
    // ------------------------------------------------------------------

    /**
     * Insère un nouvel utilisateur en base.
     *
     * @param user l'utilisateur à créer (passwordHash déjà hashé)
     * @return true si l'insertion a réussi
     */
    public boolean createUser(User user) {
        String sql = "INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, ?)";
        try (PreparedStatement ps = getConn().prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, user.getUsername());
            ps.setString(2, user.getEmail());
            ps.setString(3, user.getPasswordHash());
            ps.setString(4, user.getRole() != null ? user.getRole() : "registered");
            int rows = ps.executeUpdate();
            if (rows > 0) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) user.setId(rs.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "createUser() — " + e.getMessage(), e);
        }
        return false;
    }

    // ------------------------------------------------------------------
    // READ
    // ------------------------------------------------------------------

    /** Recherche un utilisateur par son identifiant. */
    public User findById(int id) {
        String sql = "SELECT * FROM users WHERE id = ?";
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

    /** Recherche un utilisateur par son nom d'utilisateur. */
    public User findByUsername(String username) {
        String sql = "SELECT * FROM users WHERE username = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return map(rs);
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "findByUsername() — " + e.getMessage(), e);
        }
        return null;
    }

    /** Vérifie si un username est déjà pris. */
    public boolean usernameExists(String username) {
        String sql = "SELECT 1 FROM users WHERE username = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "usernameExists() — " + e.getMessage(), e);
        }
        return false;
    }

    /** Vérifie si un email est déjà enregistré. */
    public boolean emailExists(String email) {
        String sql = "SELECT 1 FROM users WHERE email = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "emailExists() — " + e.getMessage(), e);
        }
        return false;
    }

    /** Retourne la liste de tous les utilisateurs (pour admin). */
    public List<User> getAllUsers() {
        List<User> list = new ArrayList<>();
        String sql = "SELECT * FROM users ORDER BY created_at DESC";
        try (PreparedStatement ps = getConn().prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(map(rs));
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "getAllUsers() — " + e.getMessage(), e);
        }
        return list;
    }

    // ------------------------------------------------------------------
    // UPDATE
    // ------------------------------------------------------------------

    /** Modifie le rôle d'un utilisateur (admin seulement). */
    public boolean updateRole(int userId, String role) {
        String sql = "UPDATE users SET role = ? WHERE id = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setString(1, role);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "updateRole() — " + e.getMessage(), e);
        }
        return false;
    }

    // ------------------------------------------------------------------
    // DELETE
    // ------------------------------------------------------------------

    /** Supprime un utilisateur et ses données associées (CASCADE). */
    public boolean deleteUser(int id) {
        String sql = "DELETE FROM users WHERE id = ?";
        try (PreparedStatement ps = getConn().prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "deleteUser() — " + e.getMessage(), e);
        }
        return false;
    }

    // ------------------------------------------------------------------
    // Mapping ResultSet → User
    // ------------------------------------------------------------------

    private User map(ResultSet rs) throws SQLException {
        User u = new User();
        u.setId(rs.getInt("id"));
        u.setUsername(rs.getString("username"));
        u.setEmail(rs.getString("email"));
        u.setPasswordHash(rs.getString("password_hash"));
        u.setRole(rs.getString("role"));
        u.setCreatedAt(rs.getTimestamp("created_at"));
        return u;
    }
}
