<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manuscript Detail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Manuscript Detail</h2>
<p class="page-sub">Review manuscript and add inline annotations</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-card">
    <h3 class="section-title">Manuscript #${manuscript.id}</h3>
    <div class="inline-meta">
        <span>Chapter ID: ${manuscript.chapterId}</span>
        <span>Version: v${manuscript.version}</span>
        <span>Status: ${manuscript.status}</span>
        <span>Submitted: ${manuscript.submittedAt}</span>
        <span>Review Deadline: ${manuscript.reviewDeadline}</span>
    </div>
    <p style="margin-top:10px;">File URL: <a href="${manuscript.fileUrl}" target="_blank">${manuscript.fileUrl}</a></p>
</div>

<c:if test="${canReview}">
<div class="section-card">
    <h3 class="section-title">Editor Actions</h3>
    <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/approve" style="display:inline-block; margin-right:8px;">
        <button class="btn primary" type="submit">Approve</button>
    </form>
    <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/reject" style="display:inline-block; margin-right:8px;">
        <button class="btn" type="submit">Reject</button>
    </form>
</div>

<div class="section-card">
    <h3 class="section-title">Add Annotation</h3>
    <form class="form-grid" method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/annotate">
        <label>Page Number</label>
        <input type="number" name="pageNumber" min="1" required />
        <label>Content</label>
        <textarea name="content" rows="4" required></textarea>
        <button class="btn primary" type="submit">Add Annotation</button>
    </form>
</div>
</c:if>

<div class="section-card">
    <h3 class="section-title">Annotations</h3>
    <table class="data-table">
        <thead><tr><th>Page</th><th>Content</th><th>Editor</th><th>Created</th></tr></thead>
        <tbody>
            <c:forEach items="${annotations}" var="a">
                <tr>
                    <td>${a.pageNumber}</td>
                    <td>${a.content}</td>
                    <td>${a.editorId}</td>
                    <td>${a.createdAt}</td>
                </tr>
            </c:forEach>
            <c:if test="${empty annotations}"><tr><td colspan="4">No annotations yet.</td></tr></c:if>
        </tbody>
    </table>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
