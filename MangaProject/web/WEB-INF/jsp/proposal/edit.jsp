<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit Proposal</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Edit Draft Proposal</h2>
<p class="page-sub">Update your draft before submitting for voting</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-card">
    <form class="form-grid" method="post" action="${pageContext.request.contextPath}/main/proposals/${proposal.id}/edit">
        <label>Title</label>
        <input type="text" name="title" value="${proposal.title}" required />

        <label>Genre</label>
        <input type="text" name="genre" value="${proposal.genre}" required />

        <label>Synopsis</label>
        <textarea name="synopsis" rows="8" required>${proposal.synopsis}</textarea>

        <div style="display:flex; gap:10px; margin-top:8px;">
            <button class="btn primary" type="submit">Save Draft</button>
            <a class="btn" href="${pageContext.request.contextPath}/main/proposals/${proposal.id}">Cancel</a>
        </div>
    </form>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
