package com.collabdocs.controller;

import com.collabdocs.dao.AccessTokenDAO;
import com.collabdocs.dao.DocumentDAO;
import com.collabdocs.model.Document;
import com.collabdocs.util.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * Vérifie le mot de passe d'un document et crée un token d'accès en session.
 * POST /document/unlock
 *
 * Flux :
 *  1. Récupère document_id + password depuis le formulaire POST
 *  2. Vérifie le mot de passe par rapport au hash en DB
 *  3. Si OK  → INSERT dans document_access_tokens → redirect vers /editor/{docId}
 *  4. Si KO  → redirect vers /editor/{docId}?pwdError=1
 *
 * Le mot de passe n'apparaît jamais dans une URL (GET params).
 */
public class DocumentUnlockServlet extends HttpServlet {

    private final DocumentDAO    documentDAO = new DocumentDAO();
    private final AccessTokenDAO tokenDAO    = new AccessTokenDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String ctx = req.getContextPath();

        int docId;
        try {
            docId = Integer.parseInt(req.getParameter("document_id"));
        } catch (NumberFormatException | NullPointerException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Paramètre document_id invalide.");
            return;
        }

        String password = req.getParameter("password");
        if (password == null) password = "";

        Document doc = documentDAO.findById(docId);
        if (doc == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Document introuvable.");
            return;
        }

        if (doc.hasPassword() && PasswordUtil.verify(password, doc.getPasswordHash())) {
            String sessionId = req.getSession(true).getId();
            tokenDAO.grantToken(sessionId, docId);
            resp.sendRedirect(ctx + "/editor/" + docId);
        } else {
            resp.sendRedirect(ctx + "/editor/" + docId + "?pwdError=1");
        }
    }
}
