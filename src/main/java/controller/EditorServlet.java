package com.collabdocs.controller;

import com.collabdocs.dao.AccessTokenDAO;
import com.collabdocs.dao.DocumentDAO;
import com.collabdocs.dao.MessageDAO;
import com.collabdocs.dao.PermissionDAO;
import com.collabdocs.dao.RestoreRequestDAO;
import com.collabdocs.model.Document;
import com.collabdocs.model.Message;
import com.collabdocs.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

/**
 * Ouvre la page d'édition collaborative.
 * GET /editor/{docId}   → accès direct par identifiant
 * GET /d/{token}        → accès par lien de partage
 */
public class EditorServlet extends HttpServlet {

    private static final int CHAT_HISTORY_SIZE = 50;

    private final DocumentDAO       documentDAO    = new DocumentDAO();
    private final PermissionDAO     permissionDAO  = new PermissionDAO();
    private final MessageDAO        messageDAO     = new MessageDAO();
    private final AccessTokenDAO    tokenDAO       = new AccessTokenDAO();
    private final RestoreRequestDAO restoreDAO     = new RestoreRequestDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Nettoyer les tokens expirés à chaque accès
        tokenDAO.cleanExpired();

        HttpSession session = req.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;

        String contextPath = req.getContextPath();
        String requestURI  = req.getRequestURI();
        boolean isTokenAccess = requestURI.startsWith(contextPath + "/d/");

        Document doc = null;

        if (isTokenAccess) {
            String token = req.getPathInfo();
            if (token == null || token.equals("/")) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            token = token.substring(1);
            doc = documentDAO.findByShareToken(token);
        } else {
            String pathInfo = req.getPathInfo();
            if (pathInfo == null || pathInfo.equals("/")) {
                resp.sendRedirect(contextPath + "/home");
                return;
            }
            // Ignorer les paramètres éventuels dans le path
            String idPart = pathInfo.substring(1).split("\\?")[0];
            try {
                int docId = Integer.parseInt(idPart);
                doc = documentDAO.findById(docId);
            } catch (NumberFormatException e) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
        }

        if (doc == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Document introuvable.");
            return;
        }

        // --- Vérification de l'accès ---
        if (!canView(user, doc, req)) {
            if (user == null) {
                resp.sendRedirect(contextPath + "/login");
                return;
            }
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Vous n'avez pas accès à ce document.");
            return;
        }

        // --- Protection par mot de passe (V2 : système de token) ---
        if (doc.hasPassword()) {
            boolean ownerOrAdmin = (user != null) &&
                (doc.getOwnerId() == user.getId() || user.isAdmin());

            if (!ownerOrAdmin) {
                String sessionId = (session != null) ? session.getId() : null;
                boolean hasToken = (sessionId != null) && tokenDAO.hasValidToken(sessionId, doc.getId());

                if (!hasToken) {
                    req.setAttribute("doc", doc);
                    if ("1".equals(req.getParameter("pwdError"))) {
                        req.setAttribute("passwordError", "Mot de passe incorrect.");
                    }
                    req.getRequestDispatcher("/WEB-INF/views/password-gate.jsp").forward(req, resp);
                    return;
                }
            }
        }

        // --- Chargement des données pour la vue ---
        boolean canEdit = canEdit(user, doc);
        String permLevel = (user != null)
                ? permissionDAO.getPermission(user.getId(), doc.getId()) : null;

        List<Message> messages = messageDAO.getMessages(doc.getId(), CHAT_HISTORY_SIZE);
        List<Object[]> history = documentDAO.getHistory(doc.getId());

        // Badge restauration (propriétaire seulement)
        Object[] pendingRestore = null;
        if (user != null && doc.getOwnerId() == user.getId()) {
            pendingRestore = restoreDAO.getPendingRequest(doc.getId());
        }

        req.setAttribute("doc",            doc);
        req.setAttribute("canEdit",        canEdit);
        req.setAttribute("permLevel",      permLevel);
        req.setAttribute("messages",       messages);
        req.setAttribute("history",        history);
        req.setAttribute("pendingRestore", pendingRestore);

        req.getRequestDispatcher("/WEB-INF/views/editor.jsp").forward(req, resp);
    }

    // ------------------------------------------------------------------
    // Contrôle d'accès
    // ------------------------------------------------------------------

    private boolean canView(User user, Document doc, HttpServletRequest req) {
        if ("public".equals(doc.getAccessType())) return true;
        if (user == null) return false;
        if (doc.getOwnerId() == user.getId()) return true;
        if (user.isAdmin()) return true;
        String level = permissionDAO.getPermission(user.getId(), doc.getId());
        if (level != null) return true;
        if ("link".equals(doc.getAccessType())) {
            String requestURI  = req.getRequestURI();
            String contextPath = req.getContextPath();
            if (requestURI.startsWith(contextPath + "/d/")) return true;
        }
        return false;
    }

    private boolean canEdit(User user, Document doc) {
        if (user == null) return false;
        if (doc.getOwnerId() == user.getId()) return true;
        if (user.isAdmin()) return true;
        String level = permissionDAO.getPermission(user.getId(), doc.getId());
        return "write".equals(level);
    }
}
