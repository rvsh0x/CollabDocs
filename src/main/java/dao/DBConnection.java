package com.collabdocs.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Singleton JDBC pour la connexion à la base MySQL.
 * Modifiez les constantes DB_URL, DB_USER et DB_PASSWORD pour votre environnement.
 */
public class DBConnection {

    private static final Logger LOG = Logger.getLogger(DBConnection.class.getName());

    // ---- Paramètres de connexion — à adapter ----
    private static final String DB_URL      = "jdbc:mysql://localhost:3306/collabdocs"
                                             + "?useSSL=false&serverTimezone=UTC&characterEncoding=UTF-8";
    private static final String DB_USER     = "root";
    private static final String DB_PASSWORD = "root";
    private static final String DRIVER_CLASS = "com.mysql.cj.jdbc.Driver";

    // Singleton (instance unique)
    private static DBConnection instance;
    private Connection connection;

    private DBConnection() {
        try {
            Class.forName(DRIVER_CLASS);
            connection = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            LOG.info("Connexion MySQL établie avec succès.");
        } catch (ClassNotFoundException e) {
            LOG.log(Level.SEVERE, "Driver MySQL introuvable : " + DRIVER_CLASS, e);
            throw new RuntimeException("Driver MySQL introuvable", e);
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Impossible de se connecter à la base de données", e);
            throw new RuntimeException("Connexion DB échouée", e);
        }
    }

    /**
     * Retourne l'instance unique de DBConnection.
     * Reconnexion automatique si la connexion est fermée ou invalide.
     */
    public static synchronized DBConnection getInstance() {
        if (instance == null) {
            instance = new DBConnection();
        }
        return instance;
    }

    /**
     * Retourne une connexion JDBC valide.
     * Tente une reconnexion si la connexion actuelle est fermée.
     */
    public synchronized Connection getConnection() {
        try {
            if (connection == null || connection.isClosed() || !connection.isValid(2)) {
                LOG.info("Reconnexion à la base de données...");
                connection = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Échec de reconnexion", e);
            throw new RuntimeException("Reconnexion DB échouée", e);
        }
        return connection;
    }

    /**
     * Ferme proprement la connexion (à appeler à l'arrêt de l'application).
     */
    public synchronized void close() {
        if (connection != null) {
            try {
                connection.close();
                LOG.info("Connexion MySQL fermée.");
            } catch (SQLException e) {
                LOG.log(Level.WARNING, "Erreur lors de la fermeture de la connexion", e);
            } finally {
                connection = null;
                instance = null;
            }
        }
    }
}
