package com.collabdocs.controller;

import com.collabdocs.dao.UserDAO;
import com.collabdocs.model.User;
import com.collabdocs.util.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * Gère l'authentification des utilisateurs.
 * GET  /login → affiche le formulaire de connexion
 * POST /login → traite les identifiants et ouvre la session
 */
public class LoginServlet extends HttpServlet {
    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Si déjà connecté, rediriger vers home
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("user") != null) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String username = req.getParameter("username");
        String password = req.getParameter("password");

        // Validation basique des champs
        if (username == null || username.trim().isEmpty()|| password == null || password.trim().isEmpty()) {
            req.setAttribute("error", "Veuillez remplir tous les champs.");
            req.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(req, resp);
            return;
        }

        User user = userDAO.findByUsername(username.trim());

        if (user != null && PasswordUtil.verify(password, user.getPasswordHash())) {
            // Connexion réussie — création de la session
            HttpSession session = req.getSession(true);
            session.setAttribute("user", user);
            session.setMaxInactiveInterval(30 * 60); // 30 minutes

            // Post/Redirect/Get
            resp.sendRedirect(req.getContextPath() + "/home");
        } else {
            req.setAttribute("error", "Identifiant ou mot de passe incorrect.");
            req.setAttribute("username", username); // pré-remplir le champ
            req.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(req, resp);
        }
    }
}
