<%-- Fragment éditeur RICHTEXT (Quill.js) — inclus par editor.jsp --%>
<%-- JS : /js/editor-richtext.js (chargé par editor.jsp après editor.js) --%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%-- Quill.js via CDN --%>
<link rel="stylesheet" href="https://cdn.quilljs.com/1.3.7/quill.snow.css">
<script src="https://cdn.quilljs.com/1.3.7/quill.min.js"></script>

<div class="richtext-editor-wrapper">
    <div id="quillEditor" class="quill-container"></div>
</div>

<script>
var RICHTEXT_READONLY = ${!canEdit};
</script>
