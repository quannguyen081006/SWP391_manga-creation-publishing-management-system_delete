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

<h2 class="page-title">Task #${task.id}</h2>
<p class="page-sub">${task.seriesTitle} - Ch. ${task.chapterNumber} ${task.chapterTitle}</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-card detail-grid">
    <div><span class="detail-label">Type</span><strong>${task.taskType}</strong></div>
    <div><span class="detail-label">Pages</span><strong>${task.pageRangeStart}-${task.pageRangeEnd}</strong></div>
    <div><span class="detail-label">Assigned To</span><strong>${task.assistantName}</strong></div>
    <div><span class="detail-label">Due Date</span><strong>${task.dueDate}</strong></div>
    <div><span class="detail-label">Status</span><span class="status-chip ${task.status=='APPROVED' ? 'status-approved' : (task.status=='OVERDUE' ? 'status-overdue' : 'status-progress')}">${task.status}</span></div>
</div>

<c:if test="${canAssistantUpdate}">
    <div class="section-card">
        <h3 class="section-title compact-title">Assistant Update</h3>
        <form method="post" action="${pageContext.request.contextPath}/main/tasks/${task.id}/assistant-status" class="inline-form">
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
        <h3 class="section-title compact-title">Mangaka Review</h3>
        <div class="detail-actions">
            <form method="post" action="${pageContext.request.contextPath}/main/tasks/${task.id}/approve">
                <button class="btn success-soft" type="submit">Approve</button>
            </form>
            <form method="post" action="${pageContext.request.contextPath}/main/tasks/${task.id}/reject">
                <button class="btn danger-soft" type="submit" onclick="return confirm('Reject this task?');">Reject</button>
            </form>
        </div>
    </div>
</c:if>

<a class="btn" href="${pageContext.request.contextPath}/main/tasks">Back to Tasks</a>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
