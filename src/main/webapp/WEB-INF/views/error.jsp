<%@ page contentType="text/html;charset=UTF-8" language="java" isErrorPage="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Erreur — CollabDocs" />


<section class="section">
    <div class="container">
        <div class="columns is-centered">
            <div class="column is-6 has-text-centered">

                <c:choose>
                    <c:when test="${pageContext.errorData.statusCode == 404}">
                        <h1 class="title is-1 has-text-grey-light">404</h1>
                        <h2 class="title">Page introuvable</h2>
                        <p class="subtitle">
                            La page que vous cherchez n'existe pas ou a été déplacée.
                        </p>
                    </c:when>
                    <c:when test="${pageContext.errorData.statusCode == 403}">
                        <h1 class="title is-1 has-text-grey-light">403</h1>
                        <h2 class="title">Accès refusé</h2>
                        <p class="subtitle">
                            Vous n'avez pas les droits nécessaires pour accéder à cette ressource.
                        </p>
                    </c:when>
                    <c:otherwise>
                        <h1 class="title is-1 has-text-grey-light">Oops !</h1>
                        <h2 class="title">Une erreur est survenue</h2>
                        <p class="subtitle">
                            Le serveur a rencontré un problème. Veuillez réessayer.
                        </p>
                    </c:otherwise>
                </c:choose>

                <c:if test="${not empty pageContext.errorData.throwable}">
                    <div class="notification is-light is-warning mt-4">
                        <p><strong>Détail :</strong>
                           <c:out value="${pageContext.errorData.throwable.message}" />
                        </p>
                    </div>
                </c:if>

                <div class="mt-5">
                    <a href="${pageContext.request.contextPath}/home"
                       class="button is-primary">
                        Retour à l'accueil
                    </a>
                </div>

            </div>
        </div>
    </div>
</section>

<%@ include file="layout/footer.jsp" %>
