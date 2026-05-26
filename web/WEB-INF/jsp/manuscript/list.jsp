<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manuscripts</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Manuscripts</h2>
<p class="page-sub">Track your manuscript submissions</p>

<c:if test="${isMangaka}">
<div class="section-head">
    <div></div>
    <a class="btn primary" href="${pageContext.request.contextPath}/main/manuscripts/create">+ New Manuscript</a>
</div>
</c:if>

<section class="metric-grid">
    <article class="metric-card"><div class="metric-value metric-violet">${pendingReview}</div><div class="metric-label">Pending Review</div></article>
    <article class="metric-card"><div class="metric-value metric-amber">${urgentManuscripts}</div><div class="metric-label">Urgent (&lt; 12h)</div></article>
    <article class="metric-card"><div class="metric-value metric-danger">${slaBreached}</div><div class="metric-label">SLA Breached</div></article>
    <article class="metric-card"><div class="metric-value">${fn:length(manuscripts)}</div><div class="metric-label">Total Versions</div></article>
</section>

<div class="section-card">
    <h3 class="section-title">Pending Review</h3>
    <form method="get" action="${pageContext.request.contextPath}/main/manuscripts" class="form-grid" style="margin-bottom: 16px;">
        <label>Filter by Series</label>
        <select name="seriesId">
            <option value="">All series</option>
            <c:forEach items="${seriesList}" var="s">
                <option value="${s.id}" ${selectedSeriesId == s.id ? 'selected' : ''}>${s.title}</option>
            </c:forEach>
        </select>
        <button class="btn small primary" type="submit">Filter</button>
    </form>
    <table class="data-table">
        <thead>
            <tr>
                <th>Manuscript</th>
                <th>Series</th>
                <th>Mangaka</th>
                <th>Version</th>
                <th>Submitted</th>
                <th>Status</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody>
            <c:forEach items="${manuscripts}" var="m">
                <tr>
                    <td>Ch. ${m.chapterNumber} - ${m.chapterTitle}</td>
                    <td>${m.seriesTitle}</td>
                    <td>${m.mangakaName}</td>
                    <td>v${m.version}</td>
                    <td>${m.submittedAt}</td>
                    <td><span class="status-chip ${m.status=='APPROVED' ? 'status-approved' : (m.status=='REJECTED' ? 'status-rejected' : 'status-voting')}">${m.status}</span></td>
                    <td><a class="btn small" href="${pageContext.request.contextPath}/main/manuscripts/${m.id}">View</a></td>
                </tr>
            </c:forEach>
            <c:if test="${empty manuscripts}"><tr><td colspan="7">No manuscripts found.</td></tr></c:if>
        </tbody>
    </table>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>

