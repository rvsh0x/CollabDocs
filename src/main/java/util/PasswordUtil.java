package com.collabdocs.util;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Utilitaire de hashage de mots de passe en SHA-256.
 * Produit une chaîne hexadécimale de 64 caractères en minuscules.
 */
public final class PasswordUtil {

    private PasswordUtil() {}

    /**
     * Hash un mot de passe en clair avec SHA-256.
     *
     * @param plainPassword le mot de passe en clair
     * @return le hash SHA-256 en représentation hexadécimale (64 chars)
     * @throws RuntimeException si SHA-256 n'est pas disponible (impossible en pratique)
     */
    public static String hash(String plainPassword) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(plainPassword.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            return bytesToHex(hashBytes);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 non disponible", e);
        }
    }

    /**
     * Vérifie qu'un mot de passe en clair correspond à un hash stocké.
     *
     * @param plainPassword le mot de passe saisi par l'utilisateur
     * @param storedHash    le hash SHA-256 stocké en base de données
     * @return true si le mot de passe correspond
     */
    public static boolean verify(String plainPassword, String storedHash) {
        return hash(plainPassword).equalsIgnoreCase(storedHash);
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
}
