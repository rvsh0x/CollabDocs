package com.collabdocs.websocket;

import com.collabdocs.dao.DocumentDAO;
import com.collabdocs.dao.MessageDAO;
import com.collabdocs.dao.RestoreRequestDAO;
import com.collabdocs.model.Document;
import com.collabdocs.model.Message;
import com.collabdocs.model.User;
import org.json.JSONObject;

import jakarta.websocket.*;
import jakarta.websocket.server.PathParam;
import jakarta.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * WebSocket endpoint pour l'édition collaborative.
 * URL : ws://{host}/CollabDocs/ws/doc/{docId}
 *
 * Types de messages client → serveur :
 *   content_update  : { type, content }          → diffuse le contenu à tous sauf sender
 *   pixel_update    : { type, x, y, colorIndex }  → diffuse 1 pixel (PIXELART)
 *   slide_change    : { type, slideIndex }         → synchronise la slide active (PRESENTATION)
 *   cursor_cell     : { type, row, col }           → curseur collaboratif (SPREADSHEET)
 *   chat_message    : { type, text }
 *   save_request    : { type, content }
 *   cursor_move     : { type, position }
 *   title_update    : { type, title }
 *
 * Types de messages serveur → clients :
 *   init            : { type, content, count }
 *   content_update  : { type, content, sender }
 *   pixel_update    : { type, x, y, colorIndex, sender }
 *   slide_change    : { type, slideIndex, sender }
 *   cursor_cell     : { type, row, col, username }
 *   chat_message    : { type, text, username, time }
 *   user_joined     : { type, username, count }
 *   user_left       : { type, username, count }
 *   saved           : { type, timestamp }
 *   title_update    : { type, title, sender }
 *   force_restore   : { type, content, restoredBy, timestamp }
 *   restore_request : { type, requestId, requestedBy, historyLabel }
 *   restore_approved: { type, requestId }
 *   restore_rejected: { type, requestId, message }
 *   error           : { type, message }
 */
@ServerEndpoint(value = "/ws/doc/{docId}",
                configurator = HttpSessionConfigurator.class)
public class DocumentWebSocket {

    private static final Logger LOG = Logger.getLogger(DocumentWebSocket.class.getName());

    private static final Map<Integer, Set<SessionWrapper>> ROOMS = new ConcurrentHashMap<>();

    private final DocumentDAO       documentDAO = new DocumentDAO();
    private final MessageDAO        messageDAO  = new MessageDAO();
    private final RestoreRequestDAO restoreDAO  = new RestoreRequestDAO();

    // ------------------------------------------------------------------
    // @OnOpen
    // ------------------------------------------------------------------

    @OnOpen
    public void onOpen(Session session, @PathParam("docId") int docId) {
        User user = (User) session.getUserProperties().get("user");
        String username = (user != null) ? user.getUsername() : "Visiteur-" + session.getId().substring(0, 4);

        SessionWrapper wrapper = new SessionWrapper(session, username, user);
        ROOMS.computeIfAbsent(docId, k -> Collections.synchronizedSet(new HashSet<>()))
             .add(wrapper);

        Document doc = documentDAO.findById(docId);
        if (doc != null) {
            JSONObject init = new JSONObject();
            init.put("type",    "init");
            init.put("content", doc.getContent() != null ? doc.getContent() : "");
            init.put("count",   ROOMS.get(docId).size());
            sendTo(session, init.toString());

            // Si le user est propriétaire, envoyer les demandes de restauration en attente
            if (user != null && doc.getOwnerId() == user.getId()) {
                Object[] pending = restoreDAO.getPendingRequest(docId);
                if (pending != null) {
                    JSONObject notif = new JSONObject();
                    notif.put("type",         "restore_request");
                    notif.put("requestId",    (int) pending[0]);
                    notif.put("requestedBy",  (String) pending[6]);
                    notif.put("historyLabel", "Version du " +
                        new SimpleDateFormat("dd/MM à HH:mm").format(pending[5]));
                    sendTo(session, notif.toString());
                }
            }
        } else {
            JSONObject err = new JSONObject();
            err.put("type",    "error");
            err.put("message", "Document introuvable.");
            sendTo(session, err.toString());
            return;
        }

        JSONObject joined = new JSONObject();
        joined.put("type",     "user_joined");
        joined.put("username", username);
        joined.put("count",    ROOMS.get(docId).size());
        broadcastExcept(docId, session, joined.toString());

        LOG.info(username + " a rejoint le document " + docId
                 + " (" + ROOMS.get(docId).size() + " connecté(s))");
    }

    // ------------------------------------------------------------------
    // @OnMessage
    // ------------------------------------------------------------------

    @OnMessage
    public void onMessage(String rawMessage, Session sender, @PathParam("docId") int docId) {
        JSONObject msg;
        try {
            msg = new JSONObject(rawMessage);
        } catch (Exception e) {
            LOG.warning("JSON invalide reçu : " + rawMessage);
            return;
        }

        String type = msg.optString("type", "");
        User senderUser = (User) sender.getUserProperties().get("user");
        String senderName = (senderUser != null) ? senderUser.getUsername()
                : "Visiteur-" + sender.getId().substring(0, 4);

        switch (type) {

            case "content_update": {
                String content = msg.optString("content", "");
                JSONObject broadcast = new JSONObject();
                broadcast.put("type",    "content_update");
                broadcast.put("content", content);
                broadcast.put("sender",  senderName);
                broadcastExcept(docId, sender, broadcast.toString());
                break;
            }

            case "pixel_update": {
                // Optimisation pixel art : diffuser sans sauvegarder en DB
                int x          = msg.optInt("x", 0);
                int y          = msg.optInt("y", 0);
                int colorIndex = msg.optInt("colorIndex", 0);
                JSONObject broadcast = new JSONObject();
                broadcast.put("type",       "pixel_update");
                broadcast.put("x",          x);
                broadcast.put("y",          y);
                broadcast.put("colorIndex", colorIndex);
                broadcast.put("sender",     senderName);
                broadcastExcept(docId, sender, broadcast.toString());
                break;
            }

            case "slide_change": {
                int slideIndex = msg.optInt("slideIndex", 0);
                JSONObject broadcast = new JSONObject();
                broadcast.put("type",       "slide_change");
                broadcast.put("slideIndex", slideIndex);
                broadcast.put("sender",     senderName);
                broadcastExcept(docId, sender, broadcast.toString());
                break;
            }

            case "cursor_cell": {
                int row = msg.optInt("row", 0);
                int col = msg.optInt("col", 0);
                JSONObject broadcast = new JSONObject();
                broadcast.put("type",     "cursor_cell");
                broadcast.put("row",      row);
                broadcast.put("col",      col);
                broadcast.put("username", senderName);
                broadcastExcept(docId, sender, broadcast.toString());
                break;
            }

            case "chat_message": {
                String text = msg.optString("text", "").trim();
                if (text.isEmpty()) break;
                String time = new SimpleDateFormat("HH:mm").format(new Date());
                Message chatMsg = new Message(
                    docId,
                    senderUser != null ? senderUser.getId() : null,
                    senderName,
                    text
                );
                messageDAO.saveMessage(chatMsg);
                JSONObject broadcast = new JSONObject();
                broadcast.put("type",     "chat_message");
                broadcast.put("text",     text);
                broadcast.put("username", senderName);
                broadcast.put("time",     time);
                broadcastAll(docId, broadcast.toString());
                break;
            }

            case "save_request": {
                String content = msg.optString("content", null);
                if (content == null) break;
                documentDAO.updateContent(docId, content);
                documentDAO.saveHistory(docId, content,
                        senderUser != null ? senderUser.getId() : null);
                String timestamp = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
                JSONObject saved = new JSONObject();
                saved.put("type",      "saved");
                saved.put("timestamp", timestamp);
                broadcastAll(docId, saved.toString());
                break;
            }

            case "cursor_move": {
                int position = msg.optInt("position", 0);
                JSONObject broadcast = new JSONObject();
                broadcast.put("type",     "cursor_move");
                broadcast.put("username", senderName);
                broadcast.put("position", position);
                broadcastExcept(docId, sender, broadcast.toString());
                break;
            }

            case "title_update": {
                String title = msg.optString("title", "").trim();
                if (title.isEmpty()) break;
                documentDAO.updateTitle(docId, title);
                JSONObject broadcast = new JSONObject();
                broadcast.put("type",   "title_update");
                broadcast.put("title",  title);
                broadcast.put("sender", senderName);
                broadcastExcept(docId, sender, broadcast.toString());
                break;
            }

            default:
                LOG.warning("Type de message inconnu : " + type);
        }
    }

    // ------------------------------------------------------------------
    // @OnClose
    // ------------------------------------------------------------------

    @OnClose
    public void onClose(Session session, @PathParam("docId") int docId) {
        Set<SessionWrapper> room = ROOMS.get(docId);
        if (room == null) return;

        SessionWrapper found = null;
        for (SessionWrapper sw : room) {
            if (sw.session.getId().equals(session.getId())) {
                found = sw;
                break;
            }
        }

        if (found != null) {
            room.remove(found);
            String username = found.username;
            if (room.isEmpty()) {
                ROOMS.remove(docId);
            } else {
                JSONObject left = new JSONObject();
                left.put("type",     "user_left");
                left.put("username", username);
                left.put("count",    room.size());
                broadcastAll(docId, left.toString());
            }
            LOG.info(username + " a quitté le document " + docId);
        }
    }

    // ------------------------------------------------------------------
    // @OnError
    // ------------------------------------------------------------------

    @OnError
    public void onError(Session session, Throwable throwable, @PathParam("docId") int docId) {
        LOG.log(Level.WARNING,
                "Erreur WebSocket sur document " + docId + " / session " + session.getId(),
                throwable);
    }

    // ------------------------------------------------------------------
    // API publique statique — utilisée par RestoreServlet
    // ------------------------------------------------------------------

    /** Envoie un message à l'utilisateur identifié par userId dans le document docId. */
    public static void sendToUserById(int docId, int userId, String message) {
        Set<SessionWrapper> room = ROOMS.get(docId);
        if (room == null) return;
        for (SessionWrapper sw : room) {
            if (sw.user != null && sw.user.getId() == userId) {
                sendToStatic(sw.session, message);
            }
        }
    }

    /** Broadcast à tous les clients d'un document. */
    public static void broadcastToRoom(int docId, String message) {
        Set<SessionWrapper> room = ROOMS.get(docId);
        if (room == null) return;
        for (SessionWrapper sw : room) {
            sendToStatic(sw.session, message);
        }
    }

    // ------------------------------------------------------------------
    // Helpers de diffusion (privés / instance)
    // ------------------------------------------------------------------

    private void broadcastAll(int docId, String message) {
        broadcastToRoom(docId, message);
    }

    private void broadcastExcept(int docId, Session exclude, String message) {
        Set<SessionWrapper> room = ROOMS.get(docId);
        if (room == null) return;
        for (SessionWrapper sw : room) {
            if (!sw.session.getId().equals(exclude.getId())) {
                sendTo(sw.session, message);
            }
        }
    }

    private void sendTo(Session session, String message) {
        sendToStatic(session, message);
    }

    private static void sendToStatic(Session session, String message) {
        if (!session.isOpen()) return;
        try {
            session.getBasicRemote().sendText(message);
        } catch (IOException e) {
            LOG.log(Level.WARNING, "Impossible d'envoyer le message à " + session.getId(), e);
        }
    }

    // ------------------------------------------------------------------
    // SessionWrapper
    // ------------------------------------------------------------------

    private static class SessionWrapper {
        final Session session;
        final String  username;
        final User    user;

        SessionWrapper(Session session, String username, User user) {
            this.session  = session;
            this.username = username;
            this.user     = user;
        }

        @Override
        public boolean equals(Object o) {
            if (!(o instanceof SessionWrapper)) return false;
            return session.getId().equals(((SessionWrapper) o).session.getId());
        }

        @Override
        public int hashCode() {
            return session.getId().hashCode();
        }
    }
}
