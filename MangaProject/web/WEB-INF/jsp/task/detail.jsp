<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Task Detail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Task Detail</h2>
<p class="page-sub">Update task status or review assistant submission</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-card">
    <h3 class="section-title">Task #${task.id}</h3>
    <div class="inline-meta">
        <span>Chapter ID: ${task.chapterId}</span>
        <span>Assistant ID: ${task.assistantId}</span>
        <span>Pages: ${task.pageRangeStart}-${task.pageRangeEnd}</span>
        <span>Type: ${task.taskType}</span>
        <span>Status: ${task.status}</span>
        <span>Due: ${task.dueDate}</span>
        <span>Rejections: ${task.rejectionCount}</span>
    </div>
</div>

<c:if test="${canAssistantUpdate}">
<div class="section-card">
    <h3 class="section-title">Assistant Update</h3>
    <form method="post" action="${pageContext.request.contextPath}/main/tasks/${task.id}/assistant-status" style="display:flex;gap:10px;align-items:center;">
        <select name="status">
            <option value="IN_PROGRESS">IN_PROGRESS</option>
            <option value="SUBMITTED">SUBMITTED</option>
        </select>
        <button class="btn primary" type="submit">Update Status</button>
    </form>
</div>
</c:if>

<c:if test="${canMangakaReview}">
<div class="section-card">
    <h3 class="section-title">Mangaka Review</h3>
    <form method="post" action="${pageContext.request.contextPath}/main/tasks/${task.id}/approve" style="display:inline-block; margin-right:8px;">
        <button class="btn primary" type="submit">Approve</button>
    </form>
    <form method="post" action="${pageContext.request.contextPath}/main/tasks/${task.id}/reject" style="display:inline-block;">
        <button class="btn" type="submit">Reject</button>
    </form>
</div>
</c:if>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
