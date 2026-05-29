<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Mangaka Ranking</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Mangaka Ranking</h2>
<p class="page-sub">Period: ${period.name} (${period.status}) - Read-only snapshot</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-card">
    <h3 class="section-title">Mangaka Ranking Snapshot</h3>
    <table class="data-table">
        <thead>
            <tr>
                <th>Rank</th>
                <th>Mangaka ID</th>
                <th>Mangaka Name</th>
                <th>Total Reads</th>
                <th>Total Likes</th>
                <th>Total Revenue</th>
                <th>Calculated At</th>
            </tr>
        </thead>
        <tbody>
            <c:forEach items="${mangakaRanking}" var="m">
                <tr>
                    <td>${m.rankPosition}</td>
                    <td>${m.mangakaId}</td>
                    <td>${m.mangakaName}</td>
                    <td>${m.totalReads}</td>
                    <td>${m.totalLikes}</td>
                    <td>${m.totalRevenue}</td>
                    <td>${m.calculatedAt}</td>
                </tr>
            </c:forEach>
            <c:if test="${empty mangakaRanking}">
                <tr><td colspan="7">No mangaka ranking data yet. Close a period to generate snapshot.</td></tr>
            </c:if>
        </tbody>
    </table>
</div>

<div style="margin-top:10px;">
    <a class="btn" href="${pageContext.request.contextPath}/main/ranking/periods/${period.id}/results">Back to Series Ranking</a>
    <a class="btn" href="${pageContext.request.contextPath}/main/ranking/periods">Back to Periods</a>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
