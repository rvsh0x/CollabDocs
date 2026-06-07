package com.collabdocs.controller;

import com.collabdocs.dao.DocumentDAO;
import com.collabdocs.dao.PermissionDAO;
import com.collabdocs.dao.RestoreRequestDAO;
import com.collabdocs.model.Document;
import com.collabdocs.model.User;
import com.collabdocs.websocket.DocumentWebSocket;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.List;

/**
 * Gestion des restaurations de versions.
 *
 * POST /document/restore          -> proprietaire restaure OU collaborateur demande
 * GET  /document/restore/review   -> page de comparaison pour le proprietaire
 * POST /document/restore/approve  -> proprietaire approuve
 * POST /document/restore/reject   -> proprietaire rejette
 */
public class RestoreServlet extends HttpServlet {

    private final DocumentDAO       documentDAO   = new DocumentDAO();
    private final PermissionDAO     permissionDAO = new PermissionDAO();
    private final RestoreRequestDAO restoreDAO    = new RestoreRequestDAO();

    // ------------------------------------------------------------------
    // GET
    // ------------------------------------------------------------------

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        User user = requireUser(req, resp);
        if (user == null) return;

        String pathInfo = req.getPathInfo();
        if (pathInfo == null) pathInfo = "/";

        if ("/review".equals(pathInfo)) {
            handleReviewPage(req, resp, user);
        } else {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    // ------------------------------------------------------------------
    // POST
    // ------------------------------------------------------------------

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        User user = requireUser(req, resp);
        if (user == null) return;

        String pathInfo = req.getPathInfo();
        if (pathInfo == null) pathInfo = "/";

        switch (pathInfo) {
            case "/":
            case "":
                handleRestore(req, resp, user);
                break;
            case "/approve":
                handleApprove(req, resp, user);
                break;
            case "/reject":
                handleReject(req, resp, user);
                break;
            default:
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    // ------------------------------------------------------------------
    // Cas 1 : proprietaire restaure directement / collaborateur demande
    // ------------------------------------------------------------------

    private void handleRestore(HttpServletRequest req, HttpServletResponse resp, User user)
            throws ServletException, IOException {

        String ctx    = req.getContextPath();
        int docId     = parseId(req.getParameter("documentId"));
        int historyId = parseId(req.getParameter("historyId"));

        if (docId <= 0 || historyId <= 0) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parametres manquants.");
            return;
        }

        Document doc = documentDAO.findById(docId);
        if (doc == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Document introuvable.");
            return;
        }

        boolean isOwner  = (doc.getOwnerId() == user.getId()) || user.isAdmin();
        boolean canWrite = isOwner
                || "write".equals(permissionDAO.getPermission(user.getId(), docId));

        if (!canWrite) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        if (isOwner) {
            String err = performRestore(doc, historyId, user.getUsername());
            if (err != null) {
                req.setAttribute("error", err);
                req.getRequestDispatcher("/WEB-INF/views/error.jsp").forward(req, resp);
                return;
            }
            resp.sendRedirect(ctx + "/editor/" + docId + "?restored=1");

        } else {
            Object[] existing = restoreDAO.getPendingRequest(docId);
            if (existing != null) {
                resp.sendRedirect(ctx + "/editor/" + docId + "?restoreError=pending");
                return;
            }

            int requestId = restoreDAO.createRequest(docId, user.getId(), historyId);
            if (requestId > 0) {
                String histLabel = buildHistLabel(docId, historyId);

                org.json.JSONObject notif = new org.json.JSONObject()
                        .put("type",         "restore_request")
                        .put("requestId",    requestId)
                        .put("requestedBy",  user.getUsername())
                        .put("historyLabel", histLabel);
                DocumentWebSocket.sendToUserById(docId, doc.getOwnerId(), notif.toString());

                resp.sendRedirect(ctx + "/editor/" + docId + "?restoreRequested=1");
            } else {
                resp.sendRedirect(ctx + "/editor/" + docId + "?restoreError=1");
            }
        }
    }

    // ------------------------------------------------------------------
    // Cas 2 : le proprietaire approuve
    // ------------------------------------------------------------------

    private void handleApprove(HttpServletRequest req, HttpServletResponse resp, User user)
            throws ServletException, IOException {

        String ctx       = req.getContextPath();
        int requestId    = parseId(req.getParameter("requestId"));

        if (requestId <= 0) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        Object[] reqData = restoreDAO.getRequestWithHistory(requestId);
        if (reqData == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Demande introuvable.");
            return;
        }

        int docId = toInt(reqData[1]);
        Document doc = documentDAO.findById(docId);

        if (doc == null || (doc.getOwnerId() != user.getId() && !user.isAdmin())) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        int historyId     = toInt(reqData[3]);
        int requestedById = toInt(reqData[2]);

        restoreDAO.approve(requestId);

        String err = performRestore(doc, historyId, user.getUsername());
        if (err != null) {
            req.setAttribute("error", err);
            req.getRequestDispatcher("/WEB-INF/views/error.jsp").forward(req, resp);
            return;
        }

        org.json.JSONObject approvedMsg = new org.json.JSONObject()
                .put("type",      "restore_approved")
                .put("requestId", requestId);
        DocumentWebSocket.sendToUserById(docId, requestedById, approvedMsg.toString());

        resp.sendRedirect(ctx + "/editor/" + docId);
    }

    // ------------------------------------------------------------------
    // Cas 3 : le proprietaire rejette
    // ------------------------------------------------------------------

    private void handleReject(HttpServletRequest req, HttpServletResponse resp, User user)
            throws ServletException, IOException {

        String ctx    = req.getContextPath();
        int requestId = parseId(req.getParameter("requestId"));

        if (requestId <= 0) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        Object[] reqData = restoreDAO.getRequestWithHistory(requestId);
        if (reqData == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Demande introuvable.");
            return;
        }

        int docId         = toInt(reqData[1]);
        Document doc      = documentDAO.findById(docId);

        if (doc == null || (doc.getOwnerId() != user.getId() && !user.isAdmin())) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        int requestedById = toInt(reqData[2]);
        restoreDAO.reject(requestId);

        org.json.JSONObject rejMsg = new org.json.JSONObject()
                .put("type",      "restore_rejected")
                .put("requestId", requestId)
                .put("message",   "Le proprietaire a refuse la restauration.");
        DocumentWebSocket.sendToUserById(docId, requestedById, rejMsg.toString());

        resp.sendRedirect(ctx + "/editor/" + docId);
    }

    // ------------------------------------------------------------------
    // Page de comparaison (GET /review)
    // ------------------------------------------------------------------

    private void handleReviewPage(HttpServletRequest req, HttpServletResponse resp, User user)
            throws ServletException, IOException {

        int requestId = parseId(req.getParameter("requestId"));
        if (requestId <= 0) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        Object[] reqData = restoreDAO.getRequestWithHistory(requestId);
        if (reqData == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Demande introuvable ou expiree.");
            return;
        }

        int docId    = toInt(reqData[1]);
        Document doc = documentDAO.findById(docId);

        if (doc == null || (doc.getOwnerId() != user.getId() && !user.isAdmin())) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        req.setAttribute("doc",        doc);
        req.setAttribute("restoreReq", reqData);
        req.getRequestDispatcher("/WEB-INF/views/restore-review.jsp").forward(req, resp);
    }

    // ------------------------------------------------------------------
    // Helper : effectuer la restauration
    // ------------------------------------------------------------------

    /**
     * Restaure le document a une version historique.
     * @return null si succes, message d'erreur sinon.
     */
    private String performRestore(Document doc, int historyId, String restoredBy) {
        String histContent = documentDAO.getHistoryContent(historyId);
        if (histContent == null) {
            return "Version historique introuvable (id=" + historyId + ").";
        }

        Document current = documentDAO.findById(doc.getId());
        String currentContent = (current != null) ? current.getContent() : doc.getContent();

        // Archiver l'etat courant avant ecrasement (null = archive automatique)
        documentDAO.saveHistory(doc.getId(), currentContent, null);

        // Appliquer le contenu restaure
        documentDAO.updateContent(doc.getId(), histContent);

        // Broadcaster force_restore a tous les clients connectes
        org.json.JSONObject broadcast = new org.json.JSONObject()
                .put("type",       "force_restore")
                .put("content",    histContent)
                .put("restoredBy", restoredBy)
                .put("timestamp",  new SimpleDateFormat("HH:mm").format(new java.util.Date()));
        DocumentWebSocket.broadcastToRoom(doc.getId(), broadcast.toString());

        return null;
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    /** Recupere l'utilisateur en session ; redirige vers /login si absent. */
    private User requireUser(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return null;
        }
        return user;
    }

    /**
     * Convertit un Object JDBC (Integer ou Long) en int sans ClassCastException.
     * Le driver MySQL peut retourner les colonnes INT comme Long selon la version.
     */
    private int toInt(Object o) {
        if (o == null)            return -1;
        if (o instanceof Integer) return (Integer) o;
        if (o instanceof Long)    return ((Long) o).intValue();
        if (o instanceof Number)  return ((Number) o).intValue();
        try { return Integer.parseInt(o.toString()); }
        catch (NumberFormatException e) { return -1; }
    }

    /** Parse un parametre String en int ; retourne -1 si invalide. */
    private int parseId(String s) {
        try { return Integer.parseInt(s); }
        catch (NumberFormatException | NullPointerException e) { return -1; }
    }

    /** Construit un label lisible pour une version (ex: "Version 12/05 a 14:30"). */
    private String buildHistLabel(int docId, int historyId) {
        List<Object[]> history = documentDAO.getHistory(docId);
        if (history != null) {
            for (Object[] h : history) {
                if (toInt(h[0]) == historyId && h[1] instanceof java.util.Date) {
                    return "Version " + new SimpleDateFormat("dd/MM a HH:mm").format(h[1]);
                }
            }
        }
        return "Version #" + historyId;
    }
}
