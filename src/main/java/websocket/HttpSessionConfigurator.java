package com.collabdocs.websocket;

import com.collabdocs.model.User;

import jakarta.servlet.http.HttpSession;
import jakarta.websocket.HandshakeResponse;
import jakarta.websocket.server.HandshakeRequest;
import jakarta.websocket.server.ServerEndpointConfig;

/**
 * Configurateur WebSocket qui transfère l'utilisateur de la session HTTP
 * vers les propriétés de la session WebSocket.
 * Cela permet au DocumentWebSocket d'identifier l'utilisateur connecté.
 */
public class HttpSessionConfigurator extends ServerEndpointConfig.Configurator {

    @Override
    public void modifyHandshake(ServerEndpointConfig config,
                                HandshakeRequest request,
                                HandshakeResponse response) {
        HttpSession httpSession = (HttpSession) request.getHttpSession();
        if (httpSession != null) {
            User user = (User) httpSession.getAttribute("user");
            if (user != null) {
                config.getUserProperties().put("user", user);
            }
        }
    }
}
