package com.collabdocs.controller;

import com.collabdocs.dao.DocumentDAO;
import com.collabdocs.model.Document;
import com.collabdocs.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

/**
 * Page d'accueil — liste les documents de l'utilisateur connecté.
 * GET /home
 */
public class HomeServlet extends HttpServlet {
    private final DocumentDAO documentDAO = new DocumentDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("user");

        // Documents dont l'utilisateur est propriétaire
        List<Document> myDocs = documentDAO.findByOwner(user.getId());

        // Documents partagés avec l'utilisateur
        List<Document> sharedDocs = documentDAO.findSharedWithUser(user.getId());

        req.setAttribute("myDocs",     myDocs);
        req.setAttribute("sharedDocs", sharedDocs);

        req.getRequestDispatcher("/WEB-INF/views/home.jsp").forward(req, resp);
    }
}
