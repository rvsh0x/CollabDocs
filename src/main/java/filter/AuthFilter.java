package com.collabdocs.filter;

import com.collabdocs.model.User;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Filtre d'authentification.
 * Intercepte les URLs protégées et redirige vers /login si l'utilisateur n'est pas connecté.
 * Pour les routes /admin, vérifie en plus que l'utilisateur est administrateur.
 */
public class AuthFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  req  = (HttpServletRequest)  request;
        HttpServletResponse resp = (HttpServletResponse) response;
        HttpSession session = req.getSession(false);

        User user = (session != null) ? (User) session.getAttribute("user") : null;

        // Pas connecté → redirection vers la page de connexion
        if (user == null) {
            String loginUrl = req.getContextPath() + "/login";
            resp.sendRedirect(loginUrl);
            return;
        }

        // Route admin : seuls les admins peuvent accéder
        String requestUri = req.getRequestURI();
        String adminPath  = req.getContextPath() + "/admin";
        if (requestUri.startsWith(adminPath) && !user.isAdmin()) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Accès refusé : vous n'êtes pas administrateur.");
            return;
        }

        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {}
}
