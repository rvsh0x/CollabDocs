
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Accès protégé — ${doc.title}" />
<%@ include file="layout/header.jsp" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<section class="section">
    <div class="container">
        <div class="columns is-centered">
            <div class="column is-5 is-4-widescreen">

                <div class="box" style="margin-top:3rem;">
                    <div class="has-text-centered mb-4">
                        <h2 class="title is-4 mt-2">Document protégé</h2>
                        <p class="subtitle is-6 has-text-grey">
                            <strong><c:out value="${doc.title}"/></strong>
                            requiert un mot de passe pour y accéder.
                        </p>
                    </div>

                    <c:if test="${not empty passwordError}">
                        <div class="notification is-danger is-light">
                            <strong>Erreur :</strong> <c:out value="${passwordError}"/>
                        </div>
                    </c:if>

                    <%-- Formulaire POST — le mot de passe ne passe jamais dans l'URL --%>
                    <form method="post"
                          action="${pageContext.request.contextPath}/document/unlock"
                          autocomplete="off">

                        <input type="hidden" name="document_id" value="${doc.id}">

                        <div class="field">
                            <label class="label" for="password">Mot de passe</label>
                            <div class="control has-icons-left">
                                <input class="input ${not empty passwordError ? 'is-danger' : ''}"
                                       type="password"
                                       id="password"
                                       name="password"
                                       placeholder="Entrez le mot de passe"
                                       autofocus
                                       required
                                       autocomplete="current-password">
                                
                            </div>
                        </div>

                        <div class="field is-grouped mt-4">
                            <div class="control is-expanded">
                                <button class="button is-primary is-fullwidth" type="submit">
                                    Accéder au document
                                </button>
                            </div>
                        </div>
                    </form>

                    <hr>
                    <p class="has-text-centered">
                        <a href="${pageContext.request.contextPath}/home">
                            ← Retour à mes documents
                        </a>
                    </p>
                </div>

            </div>
        </div>
    </div>
</section>

<%@ include file="layout/footer.jsp" %>
