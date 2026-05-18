<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Dashboard</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Dashboard</h2>
<p class="page-sub">Role-based control center</p>

<c:choose>
    <c:when test="${sessionScope.AUTH_USER.hasRole('MANGAKA')}">
        <section class="metric-grid">
            <article class="metric-card"><div class="metric-label">Proposals</div><div class="metric-value">${proposalCount}</div><div class="metric-note">${openVotes} active</div></article>
            <article class="metric-card"><div class="metric-label">Series</div><div class="metric-value">${seriesCount}</div><div class="metric-note">${approvedCount} approved</div></article>
            <article class="metric-card"><div class="metric-label">Overdue Tasks</div><div class="metric-value metric-danger">${overdueTasks}</div><div class="metric-note">Need attention</div></article>
            <article class="metric-card"><div class="metric-label">Pending Manuscripts</div><div class="metric-value metric-violet">${pendingManuscripts}</div><div class="metric-note">Awaiting review</div></article>
        </section>

        <div class="section-card">
            <h3 class="section-title">Mangaka Actions</h3>
            <div style="display:flex; gap:10px; flex-wrap:wrap;">
                <a class="btn primary" href="${pageContext.request.contextPath}/main/proposals/create">New Proposal</a>
                <a class="btn" href="${pageContext.request.contextPath}/main/series">Manage Series</a>
                <a class="btn" href="${pageContext.request.contextPath}/main/tasks">Review Tasks</a>
                <a class="btn" href="${pageContext.request.contextPath}/main/manuscripts">Submit/Track Manuscripts</a>
            </div>
        </div>
    </c:when>

    <c:when test="${sessionScope.AUTH_USER.hasRole('ASSISTANT')}">
        <section class="metric-grid">
            <article class="metric-card"><div class="metric-label">Your Active Tasks</div><div class="metric-value">${activeTasks}</div></article>
            <article class="metric-card"><div class="metric-label">Submitted</div><div class="metric-value metric-violet">${submittedTasks}</div></article>
            <article class="metric-card"><div class="metric-label">Overdue</div><div class="metric-value metric-danger">${overdueTasks}</div></article>
            <article class="metric-card"><div class="metric-label">Completed</div><div class="metric-value metric-ok">${completedTasks}</div></article>
        </section>

        <div class="section-card">
            <h3 class="section-title">Assistant Actions</h3>
            <div style="display:flex; gap:10px; flex-wrap:wrap;">
                <a class="btn primary" href="${pageContext.request.contextPath}/main/tasks">Update Task Status</a>
                <a class="btn" href="${pageContext.request.contextPath}/main/series">View Assigned Series</a>
            </div>
        </div>
    </c:when>

    <c:when test="${sessionScope.AUTH_USER.hasRole('TANTOU_EDITOR')}">
        <section class="metric-grid">
            <article class="metric-card"><div class="metric-label">Pending Review</div><div class="metric-value metric-violet">${pendingManuscripts}</div></article>
            <article class="metric-card"><div class="metric-label">Overdue Tasks</div><div class="metric-value metric-danger">${overdueTasks}</div></article>
            <article class="metric-card"><div class="metric-label">Series</div><div class="metric-value">${seriesCount}</div></article>
            <article class="metric-card"><div class="metric-label">Open Proposals</div><div class="metric-value">${openVotes}</div></article>
        </section>

        <div class="section-card">
            <h3 class="section-title">Tantou Actions</h3>
            <div style="display:flex; gap:10px; flex-wrap:wrap;">
                <a class="btn primary" href="${pageContext.request.contextPath}/main/manuscripts">Review Manuscripts</a>
                <a class="btn" href="${pageContext.request.contextPath}/main/tasks">Monitor Tasks</a>
                <a class="btn" href="${pageContext.request.contextPath}/main/proposals">View Proposals</a>
            </div>
        </div>
    </c:when>

    <c:when test="${sessionScope.AUTH_USER.hasRole('EDITORIAL_BOARD')}">
        <section class="metric-grid">
            <article class="metric-card"><div class="metric-label">Open Proposal Votes</div><div class="metric-value">${openVotes}</div></article>
            <article class="metric-card"><div class="metric-label">Series Pool</div><div class="metric-value">${seriesCount}</div></article>
            <article class="metric-card"><div class="metric-label">Pending Decisions</div><div class="metric-value metric-amber">${overdueTasks}</div></article>
            <article class="metric-card"><div class="metric-label">Ranking Modules</div><div class="metric-value metric-ok">Ready</div></article>
        </section>

        <div class="section-card">
            <h3 class="section-title">Editorial Board Actions</h3>
            <div style="display:flex; gap:10px; flex-wrap:wrap;">
                <a class="btn primary" href="${pageContext.request.contextPath}/main/proposals">Vote Proposals</a>
                <a class="btn" href="${pageContext.request.contextPath}/main/ranking/periods">Submit Ranking Entries</a>
                <a class="btn" href="${pageContext.request.contextPath}/main/decisions">Vote Decisions</a>
            </div>
        </div>
    </c:when>

    <c:otherwise>
        <section class="metric-grid">
            <article class="metric-card"><div class="metric-label">Users</div><div class="metric-value">System</div><div class="metric-note">Admin controls</div></article>
            <article class="metric-card"><div class="metric-label">Proposals</div><div class="metric-value">${proposalCount}</div></article>
            <article class="metric-card"><div class="metric-label">Ranking Periods</div><div class="metric-value">Live</div></article>
            <article class="metric-card"><div class="metric-label">Audit</div><div class="metric-value">Enabled</div></article>
        </section>

        <div class="section-card">
            <h3 class="section-title">Admin Actions</h3>
            <div style="display:flex; gap:10px; flex-wrap:wrap;">
                <a class="btn primary" href="${pageContext.request.contextPath}/main/users">Manage Users</a>
                <a class="btn" href="${pageContext.request.contextPath}/main/ranking/periods">Manage Ranking</a>
                <a class="btn" href="${pageContext.request.contextPath}/main/decisions">Review Decisions</a>
                <a class="btn" href="${pageContext.request.contextPath}/api/v1/audit-logs">Audit API</a>
            </div>
        </div>
    </c:otherwise>
</c:choose>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
