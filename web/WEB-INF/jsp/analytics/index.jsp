<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Mangaka Performance Analytics</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
    <style>
        .analytics-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 24px; border-radius: 12px; margin-bottom: 16px; }
        .analytics-card h3 { margin: 0 0 8px 0; font-size: 18px; }
        .analytics-card p { margin: 0; opacity: 0.9; }
        .card-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 16px; margin: 24px 0; }
        .metric-card { background: #f5f5f5; padding: 20px; border-radius: 8px; text-align: center; }
        .metric-value { font-size: 32px; font-weight: bold; color: #333; }
        .metric-label { font-size: 14px; color: #666; margin-top: 8px; }
    </style>
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Mangaka Performance Analytics</h2>
<p class="page-sub">Internal publisher analytics for editorial board</p>

<div class="analytics-card">
    <h3>Performance Dashboard</h3>
    <p>Track mangaka performance across popularity, reliability, and quality metrics</p>
</div>

<div class="section-card">
    <h3 class="section-title compact-title">Quick Analytics</h3>
    <div class="card-grid">
        <a href="${pageContext.request.contextPath}/main/analytics/popular" class="metric-card">
            <div class="metric-value">🏆</div>
            <div class="metric-label">Top Popular Mangaka</div>
        </a>
        <a href="${pageContext.request.contextPath}/main/analytics/reliable" class="metric-card">
            <div class="metric-value">⏰</div>
            <div class="metric-label">Most Reliable Mangaka</div>
        </a>
        <a href="${pageContext.request.contextPath}/main/analytics/quality" class="metric-card">
            <div class="metric-value">⭐</div>
            <div class="metric-label">Highest Quality Mangaka</div>
        </a>
    </div>
</div>

<c:if test="${sessionScope.AUTH_USER.hasRole('ADMIN')}">
<div class="section-card">
    <h3 class="section-title compact-title">Create Performance Period (Admin)</h3>
    <form method="post" action="${pageContext.request.contextPath}/main/analytics/periods/create" class="form-grid">
        <div><label>Period Name</label><input type="text" name="name" required placeholder="e.g., Q1 2024" /></div>
        <div><label>Start Date</label><input type="date" name="startDate" required /></div>
        <div><label>End Date</label><input type="date" name="endDate" required /></div>
        <div><button class="btn primary" type="submit">Create Period</button></div>
    </form>
</div>
</c:if>

<c:if test="${not empty periods}">
    <div class="section-card">
        <h3 class="section-title compact-title">Available Periods</h3>
        <p class="muted" style="margin-bottom: 16px;">Select a period to view detailed analytics</p>
        <table class="data-table">
            <thead><tr><th>ID</th><th>Name</th><th>Window</th><th>Status</th><th>Actions</th></tr></thead>
            <tbody>
                <c:forEach items="${periods}" var="p">
                    <tr>
                        <td>${p.id}</td>
                        <td>${p.name}</td>
                        <td>${p.startDate} - ${p.endDate}</td>
                        <td>${p.status}</td>
                        <td>
                            <a class="btn small" href="${pageContext.request.contextPath}/main/analytics/period/${p.id}">View Details</a>
                            <c:if test="${sessionScope.AUTH_USER.hasRole('EDITORIAL_BOARD') && p.status == 'OPEN'}">
                                <a class="btn small" href="${pageContext.request.contextPath}/main/analytics/vote/${p.id}">Vote</a>
                            </c:if>
                            <c:if test="${sessionScope.AUTH_USER.hasRole('ADMIN') && p.status == 'OPEN'}">
                                <form method="post" action="${pageContext.request.contextPath}/main/analytics/periods/${p.id}/close" style="display:inline-block;">
                                    <button class="btn small" type="submit">Close</button>
                                </form>
                            </c:if>
                            <c:if test="${sessionScope.AUTH_USER.hasRole('ADMIN') && p.status == 'CLOSED'}">
                                <form method="post" action="${pageContext.request.contextPath}/main/analytics/periods/${p.id}/calculate" style="display:inline-block;">
                                    <button class="btn small" type="submit">Calculate Performance</button>
                                </form>
                            </c:if>
                        </td>
                </c:forEach>
            </tbody>
        </table>
    </div>
</c:if>

<c:if test="${empty periods}">
    <div class="section-card">
        <p class="muted">No performance data available. Calculate performance for a ranking period to see analytics.</p>
    </div>
</c:if>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
