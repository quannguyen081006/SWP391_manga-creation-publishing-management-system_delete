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

<h2 class="page-title">Manuscript #${manuscript.id}</h2>
<p class="page-sub">${manuscript.seriesTitle} - Ch. ${manuscript.chapterNumber} ${manuscript.chapterTitle}</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-card detail-grid">
    <div><span class="detail-label">Version</span><strong>v${manuscript.version}</strong></div>
    <div><span class="detail-label">Submitted</span><strong>${manuscript.submittedAt}</strong></div>
    <div><span class="detail-label">SLA Deadline</span><strong>${manuscript.reviewDeadline}</strong></div>
    <div><span class="detail-label">Status</span><span class="status-chip ${manuscript.status=='APPROVED' ? 'status-approved' : (manuscript.status=='REJECTED' ? 'status-rejected' : 'status-voting')}">${manuscript.status}</span></div>
</div>

<c:if test="${canReview}">
    <div class="section-card">
        <h3 class="section-title compact-title">Tantou Review</h3>
        <div class="detail-actions">
            <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/approve">
                <button class="btn success-soft" type="submit">Approve</button>
            </form>
            <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/reject">
                <button class="btn danger-soft" type="submit" onclick="return confirm('Reject this manuscript?');">Reject</button>
            </form>
        </div>
    </div>

    <div class="section-card">
        <h3 class="section-title compact-title">Add Annotation</h3>
        <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/annotate" class="form-grid">
            <label>Page Number</label>
            <input type="number" name="pageNumber" min="1" required />
            <label>Content</label>
            <textarea name="content" rows="4" required></textarea>
            <button class="btn primary" type="submit">Add Annotation</button>
        </form>
    </div>
</c:if>

<div class="section-card">
    <h3 class="section-title compact-title">Annotations</h3>
    <table class="data-table">
        <thead><tr><th>Page</th><th>Content</th><th>Created</th></tr></thead>
        <tbody>
            <c:forEach items="${annotations}" var="a">
                <tr><td>${a.pageNumber}</td><td>${a.content}</td><td>${a.createdAt}</td></tr>
            </c:forEach>
            <c:if test="${empty annotations}"><tr><td colspan="3" class="muted">No annotations yet.</td></tr></c:if>
        </tbody>
    </table>
</div>

<a class="btn" href="${pageContext.request.contextPath}/main/manuscripts">Back to Manuscripts</a>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
