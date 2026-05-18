<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tasks</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Tasks</h2>
<p class="page-sub">Manage page tasks for your series</p>

<c:if test="${overdueTasks > 0}">
    <div class="alert-box"><strong>${overdueTasks} Overdue Task</strong><br/>These tasks have passed their due date and need immediate attention.</div>
</c:if>

<section class="metric-grid">
    <article class="metric-card"><div class="metric-value">${activeTasks}</div><div class="metric-label">Active</div></article>
    <article class="metric-card"><div class="metric-value metric-violet">${submittedTasks}</div><div class="metric-label">Submitted</div></article>
    <article class="metric-card"><div class="metric-value metric-danger">${overdueTasks}</div><div class="metric-label">Overdue</div></article>
    <article class="metric-card"><div class="metric-value metric-ok">${completedTasks}</div><div class="metric-label">Completed</div></article>
</section>

<div class="section-card">
    <h3 class="section-title">All Tasks</h3>
    <table class="data-table">
        <thead>
            <tr>
                <th>Series</th>
                <th>Pages</th>
                <th>Type</th>
                <th>Assigned To</th>
                <th>Status</th>
                <th>Due Date</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody>
            <c:forEach items="${tasks}" var="t">
                <tr>
                    <td><strong>${t.seriesTitle}</strong><br/>Ch. ${t.chapterNumber} - ${t.chapterTitle}</td>
                    <td>${t.pageRangeStart}-${t.pageRangeEnd}</td>
                    <td>${t.taskType}</td>
                    <td>${t.assistantName}</td>
                    <td>
                        <span class="status-chip ${t.status=='OVERDUE' ? 'status-overdue' : (t.status=='IN_PROGRESS' ? 'status-progress' : (t.status=='PENDING' ? 'status-pending' : (t.status=='APPROVED' ? 'status-approved' : 'status-draft')))}">${t.status}</span>
                    </td>
                    <td>${t.dueDate}</td>
                    <td><a class="btn small" href="${pageContext.request.contextPath}/main/tasks/${t.id}">Detail</a></td>
                </tr>
            </c:forEach>
            <c:if test="${empty tasks}"><tr><td colspan="7">No tasks found.</td></tr></c:if>
        </tbody>
    </table>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
