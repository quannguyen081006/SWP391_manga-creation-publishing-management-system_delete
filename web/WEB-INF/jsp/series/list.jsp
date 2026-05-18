<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Series</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Series</h2>
<p class="page-sub">Manage your manga series and chapters</p>

<div class="list-cards">
    <c:forEach items="${seriesList}" var="s">
        <article class="tile">
            <div class="section-head" style="margin-bottom:8px">
                <h3>${s.title}</h3>
                <div class="score ${s.progressPct >= 70 ? 'metric-ok' : (s.progressPct >= 45 ? 'metric-amber' : 'metric-danger')}">${s.progressPct}%</div>
            </div>
            <div class="genre">${s.genre}</div>
            <div class="inline-meta">
                <span>${s.chapterCount} chapters</span>
                <span>${s.inProgressChapters} in progress</span>
            </div>

            <div class="metric-label" style="margin:12px 0 6px;">Current chapter progress</div>
            <div class="progress ${s.progressPct < 40 ? 'red' : ''}"><span style="width:${s.progressPct}%"></span></div>

            <div style="margin-top:12px; display:flex; justify-content:space-between; align-items:center;">
                <span class="status-chip ${s.status == 'CANCELLED' ? 'status-rejected' : 'status-approved'}">${s.status}</span>
                <a class="btn small" href="${pageContext.request.contextPath}/main/chapters">View</a>
            </div>
        </article>
    </c:forEach>
    <c:if test="${empty seriesList}"><div>No series found.</div></c:if>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>


