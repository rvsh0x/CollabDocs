package com.collabdocs.controller;

import com.collabdocs.dao.UserDAO;
import com.collabdocs.model.User;
import com.collabdocs.util.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.regex.Pattern;

/**
 * Gère l'inscription des nouveaux utilisateurs.
 * GET  /register → affiche le formulaire d'inscription
 * POST /register → valide et crée le compte
 */
public class RegisterServlet extends HttpServlet {
    private static final Pattern EMAIL_PATTERN =
        Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("user") != null) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/views/auth/register.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String username  = trim(req.getParameter("username"));
        String email     = trim(req.getParameter("email"));
        String password  = req.getParameter("password");
        String password2 = req.getParameter("password2");

        // ---- Validations ----

        if (username.isEmpty() || email.isEmpty()|| password == null || password.isEmpty()) {
            setErrorAndForward(req, resp, "Tous les champs sont obligatoires.",
                    username, email);
            return;
        }

        if (username.length() < 3 || username.length() > 50) {
            setErrorAndForward(req, resp,
                    "Le nom d'utilisateur doit contenir entre 3 et 50 caractères.",
                    username, email);
            return;
        }

        if (!EMAIL_PATTERN.matcher(email).matches()) {
            setErrorAndForward(req, resp, "L'adresse e-mail n'est pas valide.",
                    username, email);
            return;
        }

        if (password.length() < 6) {
            setErrorAndForward(req, resp,
                    "Le mot de passe doit contenir au moins 6 caractères.",
                    username, email);
            return;
        }

        if (!password.equals(password2)) {
            setErrorAndForward(req, resp, "Les mots de passe ne correspondent pas.",
                    username, email);
            return;
        }

        if (userDAO.usernameExists(username)) {
            setErrorAndForward(req, resp,
                    "Ce nom d'utilisateur est déjà pris.", username, email);
            return;
        }

        if (userDAO.emailExists(email)) {
            setErrorAndForward(req, resp,
                    "Cette adresse e-mail est déjà enregistrée.", username, email);
            return;
        }

        // ---- Création du compte ----
        User newUser = new User(username, email, PasswordUtil.hash(password), "registered");
        if (userDAO.createUser(newUser)) {
            // Connexion automatique après inscription
            HttpSession session = req.getSession(true);
            session.setAttribute("user", newUser);
            session.setMaxInactiveInterval(30 * 60);
            resp.sendRedirect(req.getContextPath() + "/home");
        } else {
            setErrorAndForward(req, resp,
                    "Une erreur s'est produite lors de la création du compte. Réessayez.",
                    username, email);
        }
    }

    private void setErrorAndForward(HttpServletRequest req, HttpServletResponse resp,
                                    String error, String username, String email)
            throws ServletException, IOException {
        req.setAttribute("error", error);
        req.setAttribute("username", username);
        req.setAttribute("email", email);
        req.getRequestDispatcher("/WEB-INF/views/auth/register.jsp").forward(req, resp);
    }

    private String trim(String s) {
        return (s != null) ? s.trim() : "";
    }
}
