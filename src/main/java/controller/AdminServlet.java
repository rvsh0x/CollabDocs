package com.collabdocs.controller;

import com.collabdocs.dao.DocumentDAO;
import com.collabdocs.dao.MessageDAO;
import com.collabdocs.dao.UserDAO;
import com.collabdocs.model.Document;
import com.collabdocs.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

/**
 * Panneau d'administration.
 * GET  /admin        → affiche le tableau de bord
 * POST /admin/user   → modifier le rôle ou supprimer un utilisateur
 * POST /admin/doc    → supprimer un document
 */
public class AdminServlet extends HttpServlet {
    private final UserDAO     userDAO     = new UserDAO();
    private final DocumentDAO documentDAO = new DocumentDAO();
    private final MessageDAO  messageDAO  = new MessageDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        loadDashboard(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String pathInfo = req.getPathInfo();
        if (pathInfo == null) pathInfo = "/";

        switch (pathInfo) {
            case "/user":
                handleUserAction(req, resp);
                break;
            case "/doc":
                handleDocAction(req, resp);
                break;
            default:
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    // ------------------------------------------------------------------

    private void loadDashboard(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User sessionUser = (User) req.getSession().getAttribute("user");

        List<User>     users     = userDAO.getAllUsers();
        List<Document> documents = documentDAO.getAllDocuments();

        // Statistiques basiques
        int totalUsers     = users.size();
        int totalDocs      = documents.size();
        int totalAdmins    = (int) users.stream().filter(User::isAdmin).count();
        int totalMsgCount  = documents.stream().mapToInt(d -> messageDAO.countMessages(d.getId()))
                                .sum();

        req.setAttribute("users",          users);
        req.setAttribute("documents",      documents);
        req.setAttribute("totalUsers",     totalUsers);
        req.setAttribute("totalDocs",      totalDocs);
        req.setAttribute("totalAdmins",    totalAdmins);
        req.setAttribute("totalMsgCount",  totalMsgCount);
        req.setAttribute("sessionUser",    sessionUser);

        req.getRequestDispatcher("/WEB-INF/views/admin.jsp").forward(req, resp);
    }

    // ------------------------------------------------------------------

    private void handleUserAction(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User sessionUser = (User) req.getSession().getAttribute("user");

        String action = req.getParameter("action");
        int targetId  = parseId(req.getParameter("userId"));

        if (targetId <= 0) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        // On ne peut pas s'auto-modifier via ce formulaire
        if (targetId == sessionUser.getId()) {
            resp.sendRedirect(req.getContextPath() + "/admin");
            return;
        }

        if ("changeRole".equals(action)) {
            String newRole = req.getParameter("role");
            if (List.of("admin", "registered", "visitor").contains(newRole)) {
                userDAO.updateRole(targetId, newRole);
            }
        } else if ("delete".equals(action)) {
            userDAO.deleteUser(targetId);
        }

        resp.sendRedirect(req.getContextPath() + "/admin");
    }

    // ------------------------------------------------------------------

    private void handleDocAction(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        int docId = parseId(req.getParameter("docId"));

        if ("delete".equals(action) && docId > 0) {
            documentDAO.deleteDocument(docId);
        }

        resp.sendRedirect(req.getContextPath() + "/admin");
    }

    // ------------------------------------------------------------------

    private int parseId(String s) {
        try { return Integer.parseInt(s); }
        catch (NumberFormatException | NullPointerException e) { return -1; }
    }
}
