<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ page pageEncoding="UTF-8" %>
<c:set var="pageTitle" value="Connexion — CollabDocs" />
<%@ include file="../layout/header.jsp" %>

<section class="section">
    <div class="container">
        <div class="columns is-centered">
            <div class="column is-5-tablet is-4-desktop is-4-widescreen">

                <h1 class="title has-text-centered">Connexion</h1>
                <h2 class="subtitle has-text-centered">Accédez à vos documents</h2>

                <c:if test="${not empty error}">
                    <div class="notification is-danger is-light">
                        <c:out value="${error}" />
                    </div>
                </c:if>

                <form method="post" action="${pageContext.request.contextPath}/login"
                      class="box">

                    <div class="field">
                        <label class="label" for="username">Nom d'utilisateur</label>
                        <div class="control">
                            <input class="input" type="text" id="username" name="username"
                                   value="<c:out value='${username}'/>"
                                   placeholder="Votre identifiant"
                                   autofocus required>
                        </div>
                    </div>

                    <div class="field">
                        <label class="label" for="password">Mot de passe</label>
                        <div class="control">
                            <input class="input" type="password" id="password" name="password"
                                   placeholder="Votre mot de passe" required>
                        </div>
                    </div>

                    <div class="field">
                        <div class="control">
                            <button class="button is-primary is-fullwidth" type="submit">
                                Se connecter
                            </button>
                        </div>
                    </div>

                    <div class="has-text-centered mt-4">
                        <p>Pas encore de compte ?
                            <a href="${pageContext.request.contextPath}/register">S'inscrire</a>
                        </p>
                    </div>
                </form>

                <div class="box has-background-light">
                    <p class="is-size-7 has-text-grey-dark">
                        <strong>Comptes de démonstration :</strong><br>
                        admin / admin123 &mdash; alice / alice123<br>
                        bob / bob123 &mdash; charlie / charlie123
                    </p>
                </div>

            </div>
        </div>
    </div>
</section>

<%@ include file="../layout/footer.jsp" %>
