<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chapters</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Chapters</h2>
<p class="page-sub">Track each chapter and current chapter progress</p>

<div class="section-card">
    <div class="section-head">
        <div>
            <h3 class="section-title">Chapter Tracker</h3>
            <p class="section-desc">Current chapter progress across your series</p>
        </div>
    </div>

    <table class="data-table">
        <thead>
            <tr>
                <th>ID</th>
                <th>Series</th>
                <th>No.</th>
                <th>Title</th>
                <th>Status</th>
                <th>Current Chapter Progress</th>
                <th>At Risk</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody>
            <c:forEach items="${chapters}" var="c">
                <tr>
                    <td>${c.id}</td>
                    <td>${c.seriesId}</td>
                    <td>${c.chapterNumber}</td>
                    <td>${c.title}</td>
                    <td>${c.status}</td>
                    <td style="min-width: 220px;">
                        <div class="inline-meta" style="justify-content:space-between; margin-bottom:6px;">
                            <span>${c.completionPct}%</span>
                        </div>
                        <div class="progress ${c.completionPct lt 40 ? 'red' : ''}" style="margin-top:0;">
                            <span style="width:${c.completionPct}%;"></span>
                        </div>
                    </td>
                    <td>
                        <span class="status-chip ${c.atRisk ? 'status-rejected' : 'status-approved'}">${c.atRisk ? 'AT RISK' : 'NORMAL'}</span>
                    </td>
                    <td><a class="btn small" href="${pageContext.request.contextPath}/main/chapters/${c.id}">Detail</a></td>
                </tr>
            </c:forEach>
            <c:if test="${empty chapters}">
                <tr>
                    <td colspan="8">No chapters found.</td>
                </tr>
            </c:if>
        </tbody>
    </table>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
