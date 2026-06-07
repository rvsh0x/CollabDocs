<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Administration — CollabDocs" />
<%@ include file="layout/header.jsp" %>

<section class="section">
    <div class="container">

        <h1 class="title">Panneau d'administration</h1>

        <!-- =========================================================
             Statistiques
        ========================================================= -->
        <div class="columns mb-5">
            <div class="column">
                <div class="box has-text-centered">
                    <p class="heading">Utilisateurs</p>
                    <p class="title">${totalUsers}</p>
                </div>
            </div>
            <div class="column">
                <div class="box has-text-centered">
                    <p class="heading">Administrateurs</p>
                    <p class="title">${totalAdmins}</p>
                </div>
            </div>
            <div class="column">
                <div class="box has-text-centered">
                    <p class="heading">Documents</p>
                    <p class="title">${totalDocs}</p>
                </div>
            </div>
            <div class="column">
                <div class="box has-text-centered">
                    <p class="heading">Messages de chat</p>
                    <p class="title">${totalMsgCount}</p>
                </div>
            </div>
        </div>

        <!-- =========================================================
             Gestion des utilisateurs
        ========================================================= -->
        <h2 class="title is-4">Utilisateurs</h2>
        <div class="table-container mb-6">
            <table class="table is-fullwidth is-striped is-hoverable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nom d'utilisateur</th>
                        <th>E-mail</th>
                        <th>Rôle</th>
                        <th>Inscrit le</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="u" items="${users}">
                        <tr class="${u.id == sessionUser.id ? 'is-selected' : ''}">
                            <td>${u.id}</td>
                            <td>
                                <c:out value="${u.username}" />
                                <c:if test="${u.id == sessionUser.id}">
                                    <span class="tag is-light ml-1">Vous</span>
                                </c:if>
                            </td>
                            <td><c:out value="${u.email}" /></td>
                            <td>
                                <c:choose>
                                    <c:when test="${u.role == 'admin'}">
                                        <span class="tag is-danger">admin</span>
                                    </c:when>
                                    <c:when test="${u.role == 'registered'}">
                                        <span class="tag is-info">registered</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="tag is-light">visitor</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td>
                                <fmt:formatDate value="${u.createdAt}" pattern="dd/MM/yyyy"/>
                            </td>
                            <td>
                                <c:if test="${u.id != sessionUser.id}">
                                    <div class="buttons are-small">
                                        <!-- Changer le rôle -->
                                        <form method="post"
                                              action="${pageContext.request.contextPath}/admin/user"
                                              style="display:inline;">
                                            <input type="hidden" name="action" value="changeRole">
                                            <input type="hidden" name="userId" value="${u.id}">
                                            <div class="field has-addons mb-0">
                                                <div class="control">
                                                    <div class="select is-small">
                                                        <select name="role">
                                                            <option value="admin"      ${u.role == 'admin'      ? 'selected' : ''}>admin</option>
                                                            <option value="registered" ${u.role == 'registered' ? 'selected' : ''}>registered</option>
                                                            <option value="visitor"    ${u.role == 'visitor'    ? 'selected' : ''}>visitor</option>
                                                        </select>
                                                    </div>
                                                </div>
                                                <div class="control">
                                                    <button type="submit"
                                                            class="button is-info is-small">
                                                        Appliquer
                                                    </button>
                                                </div>
                                            </div>
                                        </form>
                                        <!-- Supprimer l'utilisateur -->
                                        <form method="post"
                                              action="${pageContext.request.contextPath}/admin/user"
                                              onsubmit="return confirm('Supprimer définitivement ${u.username} ?');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="userId" value="${u.id}">
                                            <button type="submit"
                                                    class="button is-danger is-small is-outlined">
                                                Supprimer
                                            </button>
                                        </form>
                                    </div>
                                </c:if>
                            </td>
                        </tr>
                    </c:forEach>
                </tbody>
            </table>
        </div>

        <!-- =========================================================
             Gestion des documents
        ========================================================= -->
        <h2 class="title is-4">Documents</h2>
        <div class="table-container">
            <table class="table is-fullwidth is-striped is-hoverable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Titre</th>
                        <th>Propriétaire</th>
                        <th>Accès</th>
                        <th>Dernière modif.</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="doc" items="${documents}">
                        <tr>
                            <td>${doc.id}</td>
                            <td>
                                <a href="${pageContext.request.contextPath}/editor/${doc.id}"
                                   target="_blank">
                                    <c:out value="${doc.title}" />
                                </a>
                            </td>
                            <td><c:out value="${doc.ownerUsername}" /></td>
                            <td>
                                <c:choose>
                                    <c:when test="${doc.accessType == 'public'}">
                                        <span class="tag is-success is-light">public</span>
                                    </c:when>
                                    <c:when test="${doc.accessType == 'link'}">
                                        <span class="tag is-info is-light">lien</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="tag is-danger is-light">privé</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td>
                                <fmt:formatDate value="${doc.updatedAt}" pattern="dd/MM/yyyy HH:mm"/>
                            </td>
                            <td>
                                <form method="post"
                                      action="${pageContext.request.contextPath}/admin/doc"
                                      onsubmit="return confirm('Supprimer définitivement ce document ?');">
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="docId" value="${doc.id}">
                                    <button type="submit"
                                            class="button is-danger is-small is-outlined">
                                        Supprimer
                                    </button>
                                </form>
                            </td>
                        </tr>
                    </c:forEach>
                </tbody>
            </table>
        </div>

    </div>
</section>

<%@ include file="layout/footer.jsp" %>
