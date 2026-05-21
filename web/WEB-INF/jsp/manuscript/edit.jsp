<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit Manuscript</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Edit Manuscript #${manuscript.id}</h2>
<p class="page-sub">Version v${manuscript.version}</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-card">
    <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/edit" class="form-grid">
        <label>File URL</label>
        <input type="text" name="fileUrl" value="${manuscript.fileUrl}" required />

        <button class="btn primary" type="submit">Update Manuscript</button>
    </form>
</div>

<a class="btn" href="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}">Cancel</a>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
