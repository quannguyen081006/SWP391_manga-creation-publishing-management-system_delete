<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Decision Sessions</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Decision Sessions</h2>
<p class="page-sub">Review sessions and cast board decisions</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<c:if test="${not empty sessions}">
<div class="section-card">
    <h3 class="section-title">All Sessions</h3>
    <table class="data-table">
        <thead><tr><th>ID</th><th>Series</th><th>Status</th><th>Result</th><th>Opened</th><th></th></tr></thead>
        <tbody>
            <c:forEach items="${sessions}" var="s">
                <tr>
                    <td>${s.id}</td>
                    <td>${s.seriesId}</td>
                    <td>${s.status}</td>
                    <td>${s.result}</td>
                    <td>${s.openedAt}</td>
                    <td><a class="btn small" href="${pageContext.request.contextPath}/main/decisions/${s.id}">Detail</a></td>
                </tr>
            </c:forEach>
        </tbody>
    </table>
</div>
</c:if>

<c:if test="${not empty sessionDetail}">
<div class="section-card">
    <h3 class="section-title">Session #${sessionDetail.id}</h3>
    <div class="inline-meta">
        <span>Series: ${sessionDetail.seriesId}</span>
        <span>Status: ${sessionDetail.status}</span>
        <span>Result: ${sessionDetail.result}</span>
        <span>System Suggestion: ${sessionDetail.systemSuggestion}</span>
    </div>

    <c:if test="${not empty revenueHistory}">
    <div class="section-card" style="margin-top: 15px;">
        <h4 class="section-title">Revenue Trend (Last 3 Periods)</h4>
        <div id="revenueChart" style="height: 300px; width: 100%;"></div>
        <script>
            var revenueData = JSON.parse('${revenueHistory}');
            if (revenueData && revenueData.length > 0) {
                var labels = revenueData.map(function(d) { return d.periodName; });
                var revenues = revenueData.map(function(d) { return d.revenue; });
                
                // Calculate SVG dimensions and scales
                var width = 600;
                var height = 300;
                var padding = 50;
                var maxRevenue = Math.max.apply(Math, revenues);
                var minRevenue = Math.min.apply(Math, revenues);
                var yRange = maxRevenue - minRevenue || 1;
                
                // Generate SVG points
                var points = [];
                for (var i = 0; i < revenues.length; i++) {
                    var x = padding + (i * (width - 2 * padding) / (revenues.length - 1 || 1));
                    var y = height - padding - ((revenues[i] - minRevenue) / yRange) * (height - 2 * padding);
                    points.push(x + ',' + y);
                }
                
                // Generate SVG
                var svg = '<svg width="100%" height="100%" viewBox="0 0 ' + width + ' ' + height + '" preserveAspectRatio="none">';
                
                // Draw axes
                svg += '<line x1="' + padding + '" y1="' + padding + '" x2="' + padding + '" y2="' + (height - padding) + '" stroke="#333" stroke-width="1"/>';
                svg += '<line x1="' + padding + '" y1="' + (height - padding) + '" x2="' + (width - padding) + '" y2="' + (height - padding) + '" stroke="#333" stroke-width="1"/>';
                
                // Draw line
                if (points.length > 1) {
                    svg += '<polyline points="' + points.join(' ') + '" fill="none" stroke="rgb(75, 192, 192)" stroke-width="2"/>';
                }
                
                // Draw points
                for (var i = 0; i < revenues.length; i++) {
                    var x = padding + (i * (width - 2 * padding) / (revenues.length - 1 || 1));
                    var y = height - padding - ((revenues[i] - minRevenue) / yRange) * (height - 2 * padding);
                    svg += '<circle cx="' + x + '" cy="' + y + '" r="4" fill="rgb(75, 192, 192)"/>';
                    
                    // Add labels
                    svg += '<text x="' + x + '" y="' + (height - padding + 20) + '" text-anchor="middle" font-size="12">' + labels[i] + '</text>';
                    svg += '<text x="' + (padding - 10) + '" y="' + (y + 4) + '" text-anchor="end" font-size="12">' + revenues[i] + '</text>';
                }
                
                // Add axis labels
                svg += '<text x="' + (width / 2) + '" y="' + (height - 10) + '" text-anchor="middle" font-size="14" font-weight="bold">Period</text>';
                svg += '<text x="15" y="' + (height / 2) + '" text-anchor="middle" font-size="14" font-weight="bold" transform="rotate(-90, 15, ' + (height / 2) + ')">Revenue</text>';
                
                svg += '</svg>';
                document.getElementById('revenueChart').innerHTML = svg;
            } else {
                document.getElementById('revenueChart').innerHTML = '<p style="text-align:center; padding: 50px;">No revenue data available</p>';
            }
        </script>
    </div>
    </c:if>

    <c:if test="${sessionScope.AUTH_USER.hasRole('EDITORIAL_BOARD')}">
        <form method="post" action="${pageContext.request.contextPath}/main/decisions/${sessionDetail.id}/votes" class="decision-vote-form">
            <div>
                <label>Decision</label>
                <select name="decision">
                    <option value="CONTINUE">CONTINUE</option>
                    <option value="CANCEL">CANCEL</option>
                    <option value="CHANGE_TYPE">CHANGE_TYPE</option>
                </select>
            </div>
            <div>
                <label>Justification (required for CANCEL)</label>
                <input type="text" name="justification" />
            </div>
            <div><button class="btn primary" type="submit">Cast Vote</button></div>
        </form>
    </c:if>
</div>

<div class="section-card">
    <h3 class="section-title">Votes</h3>
    <table class="data-table">
        <thead><tr><th>Voter</th><th>Decision</th><th>Justification</th><th>At</th></tr></thead>
        <tbody>
            <c:forEach items="${sessionDetail.votes}" var="v">
                <tr>
                    <td>${v.voterId}</td>
                    <td>${v.decision}</td>
                    <td>${v.justification}</td>
                    <td>${v.votedAt}</td>
                </tr>
            </c:forEach>
            <c:if test="${empty sessionDetail.votes}"><tr><td colspan="4">No votes yet.</td></tr></c:if>
        </tbody>
    </table>
</div>
</c:if>

<jsp:include page="../common/footer.jsp" />
</body>
</html>

