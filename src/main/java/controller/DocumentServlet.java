package com.collabdocs.controller;

import com.collabdocs.dao.DocumentDAO;
import com.collabdocs.dao.PermissionDAO;
import com.collabdocs.dao.UserDAO;
import com.collabdocs.model.Document;
import com.collabdocs.model.Permission;
import com.collabdocs.model.User;
import com.collabdocs.util.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;

/**
 * CRUD des documents.
 * GET  /document/new              → formulaire de création
 * POST /document/new              → créer le document
 * POST /document/delete           → supprimer un document
 * GET  /document/share?id=X       → gérer le partage d'un document
 * POST /document/share            → ajouter / supprimer une permission
 * POST /document/unlock           → délégué à DocumentUnlockServlet (mapping exact)
 * *    /document/restore*         → délégué à RestoreServlet (mapping exact)
 */
public class DocumentServlet extends HttpServlet {

    private static final List<String> VALID_ACCESS  = Arrays.asList("public", "link", "private");
    private static final List<String> VALID_TYPES   = Arrays.asList(
        "CODE", "PIXELART", "RICHTEXT", "SPREADSHEET",
        "PRESENTATION", "PLANNING", "MINDMAP", "DIAGRAM"
    );

    private final DocumentDAO   documentDAO   = new DocumentDAO();
    private final PermissionDAO permissionDAO = new PermissionDAO();
    private final UserDAO       userDAO       = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null) pathInfo = "/";

        switch (pathInfo) {
            case "/new":
                req.getRequestDispatcher("/WEB-INF/views/document-new.jsp").forward(req, resp);
                break;
            case "/share":
                handleSharePage(req, resp);
                break;
            default:
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String pathInfo = req.getPathInfo();
        if (pathInfo == null) pathInfo = "/";

        switch (pathInfo) {
            case "/new":
                handleCreate(req, resp);
                break;
            case "/delete":
                handleDelete(req, resp);
                break;
            case "/share":
                handleShareUpdate(req, resp);
                break;
            default:
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    // ------------------------------------------------------------------
    // Création
    // ------------------------------------------------------------------

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("user");

        String title       = trim(req.getParameter("title"));
        String accessType  = trim(req.getParameter("accessType"));
        String docPassword = req.getParameter("docPassword");
        String docType     = trim(req.getParameter("docType"));

        if (title.isEmpty()) {
            req.setAttribute("error", "Le titre ne peut pas être vide.");
            req.getRequestDispatcher("/WEB-INF/views/document-new.jsp").forward(req, resp);
            return;
        }

        if (!VALID_ACCESS.contains(accessType)) accessType = "link";
        if (!VALID_TYPES.contains(docType))     docType = "CODE";

        // Initialiser avec le JSON par défaut pour le type choisi
        String content = DocumentDAO.defaultContent(docType);

        Document doc = new Document(title, content, user.getId(), accessType);
        doc.setDocType(docType);

        if (docPassword != null && !docPassword.trim().isEmpty()) {
            String hash = PasswordUtil.hash(docPassword.trim());
            doc.setPasswordHash(hash);
            doc.setHasPasswordDb(true);
        }

        if (documentDAO.createDocument(doc)) {
            resp.sendRedirect(req.getContextPath() + "/editor/" + doc.getId());
        } else {
            req.setAttribute("error", "Erreur lors de la création du document. Réessayez.");
            req.getRequestDispatcher("/WEB-INF/views/document-new.jsp").forward(req, resp);
        }
    }

    // ------------------------------------------------------------------
    // Suppression
    // ------------------------------------------------------------------

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("user");

        int docId = parseId(req.getParameter("docId"));
        if (docId <= 0) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID de document invalide.");
            return;
        }

        Document doc = documentDAO.findById(docId);
        if (doc == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Document introuvable.");
            return;
        }

        if (doc.getOwnerId() != user.getId() && !user.isAdmin()) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Non autorisé.");
            return;
        }

        documentDAO.deleteDocument(docId);
        resp.sendRedirect(req.getContextPath() + "/home");
    }

    // ------------------------------------------------------------------
    // Page de partage
    // ------------------------------------------------------------------

    private void handleSharePage(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("user");

        int docId = parseId(req.getParameter("id"));
        Document doc = documentDAO.findById(docId);

        if (doc == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Document introuvable.");
            return;
        }

        if (doc.getOwnerId() != user.getId() && !user.isAdmin()) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Non autorisé.");
            return;
        }

        List<Permission> permissions = permissionDAO.getUsersForDocument(docId);

        req.setAttribute("doc", doc);
        req.setAttribute("permissions", permissions);
        req.getRequestDispatcher("/WEB-INF/views/document-share.jsp").forward(req, resp);
    }

    // ------------------------------------------------------------------
    // Modification des permissions
    // ------------------------------------------------------------------

    private void handleShareUpdate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User currentUser = (User) req.getSession().getAttribute("user");

        int    docId          = parseId(req.getParameter("docId"));
        String action         = trim(req.getParameter("action"));
        String targetUsername = trim(req.getParameter("targetUsername"));
        String level          = trim(req.getParameter("level"));

        Document doc = documentDAO.findById(docId);
        if (doc == null || (doc.getOwnerId() != currentUser.getId() && !currentUser.isAdmin())) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        if ("add".equals(action)) {
            if (!List.of("read", "write").contains(level)) level = "read";
            User target = userDAO.findByUsername(targetUsername);
            if (target == null) {
                req.setAttribute("error", "Utilisateur '" + targetUsername + "' introuvable.");
            } else if (target.getId() == doc.getOwnerId()) {
                req.setAttribute("error", "Le propriétaire a déjà tous les droits.");
            } else {
                permissionDAO.addPermission(target.getId(), docId, level);
            }
        } else if ("remove".equals(action)) {
            int targetUserId = parseId(req.getParameter("targetUserId"));
            if (targetUserId > 0) {
                permissionDAO.removePermission(targetUserId, docId);
            }
        }

        resp.sendRedirect(req.getContextPath() + "/document/share?id=" + docId);
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    private String trim(String s) { return (s != null) ? s.trim() : ""; }

    private int parseId(String s) {
        try { return Integer.parseInt(s); }
        catch (NumberFormatException | NullPointerException e) { return -1; }
    }
}
