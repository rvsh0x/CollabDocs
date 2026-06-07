<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ page pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${not empty pageTitle ? pageTitle : 'CollabDocs'}</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'></text></svg>">
</head>
<body>

<nav class="navbar is-dark" role="navigation" aria-label="navigation principale">
    <div class="navbar-brand">
        <a class="navbar-item brand-logo" href="${pageContext.request.contextPath}/home">
            <strong>CollabDocs</strong>
        </a>
        <a role="button" class="navbar-burger" aria-label="menu" aria-expanded="false"
           data-target="mainNavbar">
            <span aria-hidden="true"></span>
            <span aria-hidden="true"></span>
            <span aria-hidden="true"></span>
        </a>
    </div>

    <div id="mainNavbar" class="navbar-menu">
        <div class="navbar-start">
            <c:if test="${not empty sessionScope.user}">
                <a class="navbar-item" href="${pageContext.request.contextPath}/home">
                    Mes documents
                </a>
                <a class="navbar-item" href="${pageContext.request.contextPath}/document/new">
                    Nouveau document
                </a>
                <c:if test="${sessionScope.user.admin}">
                    <a class="navbar-item has-text-warning" href="${pageContext.request.contextPath}/admin">
                        Administration
                    </a>
                </c:if>
            </c:if>
        </div>

        <div class="navbar-end">
            <div class="navbar-item">
                <c:choose>
                    <c:when test="${not empty sessionScope.user}">
                        <div class="buttons">
                            <span class="button is-static is-small user-badge">
                                ${sessionScope.user.username}
                                <c:if test="${sessionScope.user.admin}">
                                    &nbsp;<span class="tag is-warning is-light">Admin</span>
                                </c:if>
                            </span>
                            <a class="button is-light is-small"
                               href="${pageContext.request.contextPath}/logout">
                                Déconnexion
                            </a>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <div class="buttons">
                            <a class="button is-primary is-small"
                               href="${pageContext.request.contextPath}/login">
                                Connexion
                            </a>
                            <a class="button is-light is-small"
                               href="${pageContext.request.contextPath}/register">
                                Inscription
                            </a>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>
    </div>
</nav>

<script>
    // Burger menu (Bulma)
    document.addEventListener('DOMContentLoaded', function () {
        var burger = document.querySelector('.navbar-burger');
        var menu = document.getElementById(burger && burger.dataset.target);
        if (burger && menu) {
            burger.addEventListener('click', function () {
                burger.classList.toggle('is-active');
                menu.classList.toggle('is-active');
            });
        }
    });
</script>
