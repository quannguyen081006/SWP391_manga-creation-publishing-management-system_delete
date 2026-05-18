<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Series Detail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Series Detail</h2>
<p class="page-sub">Track one series and its chapters</p>

<div class="section-card">
    <h3 class="section-title">${series.title}</h3>
    <div class="inline-meta">
        <span>Genre: ${series.genre}</span>
        <span>Status: ${series.status}</span>
        <span>Progress: ${series.progressPct}%</span>
    </div>
</div>

<div class="section-card">
    <div class="section-head">
        <h3 class="section-title">Chapters</h3>
        <a class="btn" href="${pageContext.request.contextPath}/main/chapters">View All</a>
    </div>
    <table class="data-table">
        <thead>
            <tr>
                <th>#</th>
                <th>Title</th>
                <th>Status</th>
                <th>Completion</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody>
            <c:forEach items="${chapters}" var="ch">
                <tr>
                    <td>${ch.chapterNumber}</td>
                    <td>${ch.title}</td>
                    <td>${ch.status}</td>
                    <td>${ch.completionPct}%</td>
                    <td><a class="btn small" href="${pageContext.request.contextPath}/main/chapters/${ch.id}">Detail</a></td>
                </tr>
            </c:forEach>
            <c:if test="${empty chapters}"><tr><td colspan="5">No chapters yet.</td></tr></c:if>
        </tbody>
    </table>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
