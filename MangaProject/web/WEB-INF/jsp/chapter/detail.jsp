<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chapter Detail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Chapter Detail</h2>
<p class="page-sub">Review chapter progress, tasks, and manuscripts</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-card">
    <h3 class="section-title">Ch. ${chapter.chapterNumber} - ${chapter.title}</h3>
    <div class="inline-meta">
        <span>Status: ${chapter.status}</span>
        <span>Completion: ${chapter.completionPct}%</span>
        <span>Submission Deadline: ${chapter.submissionDeadline}</span>
        <span>Publication: ${chapter.publicationDate}</span>
        <span>At Risk: ${chapter.atRisk}</span>
    </div>
    <c:if test="${canSubmitReview}">
        <form method="post" action="${pageContext.request.contextPath}/main/chapters/${chapter.id}/submit-review" style="margin-top:12px;">
            <button class="btn primary" type="submit">Submit For Editorial Review</button>
        </form>
    </c:if>
</div>

<div class="section-card">
    <h3 class="section-title">Page Tasks</h3>
    <table class="data-table">
        <thead><tr><th>ID</th><th>Pages</th><th>Type</th><th>Status</th><th>Due</th><th></th></tr></thead>
        <tbody>
        <c:forEach items="${tasks}" var="t">
            <tr>
                <td>${t.id}</td>
                <td>${t.pageRangeStart}-${t.pageRangeEnd}</td>
                <td>${t.taskType}</td>
                <td>${t.status}</td>
                <td>${t.dueDate}</td>
                <td><a class="btn small" href="${pageContext.request.contextPath}/main/tasks/${t.id}">Detail</a></td>
            </tr>
        </c:forEach>
        <c:if test="${empty tasks}"><tr><td colspan="6">No tasks.</td></tr></c:if>
        </tbody>
    </table>
</div>

<div class="section-card">
    <h3 class="section-title">Manuscripts</h3>
    <table class="data-table">
        <thead><tr><th>ID</th><th>Version</th><th>Status</th><th>Submitted</th><th></th></tr></thead>
        <tbody>
        <c:forEach items="${manuscripts}" var="m">
            <tr>
                <td>${m.id}</td>
                <td>v${m.version}</td>
                <td>${m.status}</td>
                <td>${m.submittedAt}</td>
                <td><a class="btn small" href="${pageContext.request.contextPath}/main/manuscripts/${m.id}">Detail</a></td>
            </tr>
        </c:forEach>
        <c:if test="${empty manuscripts}"><tr><td colspan="5">No manuscript yet.</td></tr></c:if>
        </tbody>
    </table>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
