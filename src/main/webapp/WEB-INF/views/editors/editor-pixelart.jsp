<%-- Fragment éditeur PIXELART — inclus par editor.jsp --%>
<%-- JS : /js/editor-pixelart.js (chargé par editor.jsp après editor.js) --%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<div class="pixelart-editor">

    <%-- Barre d'outils pixel art --%>
    <div class="pixelart-toolbar">
        <div class="pixelart-tools">
            <button id="toolPen"    class="button is-small tool-btn is-primary" title="Crayon">✏️</button>
            <button id="toolEraser" class="button is-small tool-btn" title="Gomme">🧹</button>
            <button id="toolFill"   class="button is-small tool-btn" title="Remplissage">🪣</button>
        </div>
        <div class="pixelart-palette" id="palette"></div>
        <div class="pixelart-size-selector ml-3">
            <label class="is-size-7 has-text-grey mr-1">Taille :</label>
            <div class="select is-small">
                <select id="gridSizeSelector" <c:if test="${!canEdit}">disabled</c:if>>
                    <option value="16">16×16</option>
                    <option value="32" selected>32×32</option>
                    <option value="64">64×64</option>
                </select>
            </div>
        </div>
        <c:if test="${canEdit}">
            <button id="clearCanvas" class="button is-small is-danger is-outlined ml-2"
                    onclick="return confirm('Effacer tout le canvas ?')">
                Effacer
            </button>
        </c:if>
    </div>

    <%-- Canvas de dessin --%>
    <div class="pixelart-canvas-wrapper">
        <canvas id="pixelCanvas" class="pixelart-canvas"></canvas>
    </div>

</div>
