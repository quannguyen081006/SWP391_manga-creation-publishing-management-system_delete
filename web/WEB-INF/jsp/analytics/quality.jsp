<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Highest Quality Mangaka</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
    <style>
        .score-bar { height: 8px; background: #e0e0e0; border-radius: 4px; overflow: hidden; }
        .score-fill { height: 100%; background: linear-gradient(90deg, #4CAF50, #8BC34A); transition: width 0.3s; }
        .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: bold; }
        .badge-elite { background: #FFD700; color: #333; }
        .badge-high { background: #4CAF50; color: white; }
        .badge-medium { background: #FF9800; color: white; }
        .rank-1 { color: #FFD700; font-weight: bold; }
        .rank-2 { color: #C0C0C0; font-weight: bold; }
        .rank-3 { color: #CD7F32; font-weight: bold; }
    </style>
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Highest Quality Mangaka</h2>
<p class="page-sub">Based on approval rate, low rejection rate, and minimal annotations</p>

<div class="section-card">
    <h3 class="section-title compact-title">Filters</h3>
    <form method="get" action="${pageContext.request.contextPath}/main/analytics/quality" class="form-grid">
        <label>Select Period</label>
        <select name="periodId">
            <c:forEach items="${periods}" var="period">
                <option value="${period.id}" ${currentPeriodId == period.id ? 'selected' : ''}>${period.name}</option>
            </c:forEach>
        </select>
        <label>Show Top</label>
        <select name="limit">
            <option value="5" ${limit == 5 ? 'selected' : ''}>Top 5</option>
            <option value="10" ${limit == 10 ? 'selected' : ''}>Top 10</option>
            <option value="20" ${limit == 20 ? 'selected' : ''}>Top 20</option>
            <option value="50" ${limit == 50 ? 'selected' : ''}>Top 50</option>
        </select>
        <button class="btn primary" type="submit">Apply Filters</button>
    </form>
</div>

<c:if test="${not empty error}">
    <div class="section-card" style="background: #fff3cd; border: 1px solid #ffc107;">
        <p style="color: #856404; margin: 0;">${error}</p>
    </div>
</c:if>

<c:if test="${not empty results}">
    <div class="section-card">
        <h3 class="section-title compact-title">Leaderboard</h3>
        <table class="data-table">
            <thead><tr><th>Rank</th><th>Mangaka</th><th>Quality</th><th>Popularity</th><th>Reliability</th><th>Overall</th><th>Badge</th></tr></thead>
            <tbody>
                <c:forEach items="${results}" var="result" varStatus="status">
                    <c:set var="rank" value="${status.index + 1}" />
                    <c:set var="mangakaName" value="${mangakaNames[result.mangakaId]}" />
                    <c:set var="qualityPercent" value="${result.qualityScore}" />
                    <c:set var="popularityPercent" value="${result.popularityScore}" />
                    <c:set var="reliabilityPercent" value="${result.reliabilityScore}" />
                    <c:set var="overallPercent" value="${result.overallScore}" />
                    <tr>
                        <td class="rank-${rank}">#${rank}</td>
                        <td>
                            <a href="${pageContext.request.contextPath}/main/analytics/mangaka/${result.mangakaId}?periodId=${currentPeriodId}">
                                <strong>${mangakaName}</strong>
                            </a>
                        </td>
                        <td>
                            <div class="score-bar"><div class="score-fill" style="width: ${qualityPercent}%"></div></div>
                            <small>${result.qualityScore}</small>
                        </td>
                        <td>
                            <div class="score-bar"><div class="score-fill" style="width: ${popularityPercent}%"></div></div>
                            <small>${result.popularityScore}</small>
                        </td>
                        <td>
                            <div class="score-bar"><div class="score-fill" style="width: ${reliabilityPercent}%"></div></div>
                            <small>${result.reliabilityScore}</small>
                        </td>
                        <td><strong>${result.overallScore}</strong></td>
                        <td>
                            <c:if test="${rank == 1}"><span class="badge badge-elite">Elite</span></c:if>
                            <c:if test="${rank == 2 || rank == 3}"><span class="badge badge-high">Top Tier</span></c:if>
                            <c:if test="${rank > 3 && rank <= 10}"><span class="badge badge-medium">High</span></c:if>
                        </td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>
    </div>
</c:if>

<c:if test="${empty results && empty error}">
    <div class="section-card">
        <p class="muted">No performance data available for this period.</p>
    </div>
</c:if>

<a class="btn" href="${pageContext.request.contextPath}/main/analytics">Back to Analytics</a>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
