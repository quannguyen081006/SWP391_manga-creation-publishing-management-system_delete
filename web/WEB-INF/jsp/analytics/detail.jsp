<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Mangaka Performance Detail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
    <style>
        .score-bar { height: 12px; background: #e0e0e0; border-radius: 6px; overflow: hidden; }
        .score-fill { height: 100%; background: linear-gradient(90deg, #4CAF50, #8BC34A); transition: width 0.3s; }
        .badge { display: inline-block; padding: 4px 12px; border-radius: 16px; font-size: 14px; font-weight: bold; }
        .badge-elite { background: #FFD700; color: #333; }
        .badge-high { background: #4CAF50; color: white; }
        .badge-medium { background: #FF9800; color: white; }
        .badge-low { background: #9E9E9E; color: white; }
        .stat-card { background: #f5f5f5; padding: 16px; border-radius: 8px; text-align: center; }
        .stat-value { font-size: 24px; font-weight: bold; color: #333; }
        .stat-label { font-size: 12px; color: #666; margin-top: 4px; }
    </style>
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Mangaka Performance Detail</h2>
<p class="page-sub">${mangakaName}</p>

<div class="section-card">
    <h3 class="section-title compact-title">Profile Summary</h3>
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 16px; margin: 16px 0;">
        <div class="stat-card">
            <div class="stat-value">#${result.overallRank}</div>
            <div class="stat-label">Overall Rank</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">${result.overallScore}</div>
            <div class="stat-label">Overall Score</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">#${result.popularityRank}</div>
            <div class="stat-label">Popularity Rank</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">#${result.reliabilityRank}</div>
            <div class="stat-label">Reliability Rank</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">#${result.qualityRank}</div>
            <div class="stat-label">Quality Rank</div>
        </div>
    </div>
</div>

<c:if test="${not empty result}">
    <div class="section-card">
        <h3 class="section-title compact-title">Performance Scores</h3>
        <div style="margin: 16px 0;">
            <div style="margin-bottom: 12px;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
                    <strong>Popularity (Rank #${result.popularityRank})</strong>
                    <span>${result.popularityScore}</span>
                </div>
                <div class="score-bar"><div class="score-fill" style="width: ${result.popularityScore}%"></div></div>
            </div>
            <div style="margin-bottom: 12px;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
                    <strong>Reliability (Rank #${result.reliabilityRank})</strong>
                    <span>${result.reliabilityScore}</span>
                </div>
                <div class="score-bar"><div class="score-fill" style="width: ${result.reliabilityScore}%"></div></div>
            </div>
            <div style="margin-bottom: 12px;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
                    <strong>Quality (Rank #${result.qualityRank})</strong>
                    <span>${result.qualityScore}</span>
                </div>
                <div class="score-bar"><div class="score-fill" style="width: ${result.qualityScore}%"></div></div>
            </div>
            <div>
                <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
                    <strong>Overall (Rank #${result.overallRank})</strong>
                    <span>${result.overallScore}</span>
                </div>
                <div class="score-bar"><div class="score-fill" style="width: ${result.overallScore}%"></div></div>
            </div>
        </div>
    </div>

    <div class="section-card">
        <h3 class="section-title compact-title">Achievement Badges</h3>
        <div style="margin: 16px 0;">
            <c:if test="${result.overallRank == 1}"><span class="badge badge-elite">Elite Mangaka</span></c:if>
            <c:if test="${result.overallRank == 2 || result.overallRank == 3}"><span class="badge badge-high">Top Tier Creator</span></c:if>
            <c:if test="${result.overallRank > 3 && result.overallRank <= 10}"><span class="badge badge-medium">High Performer</span></c:if>
            <c:if test="${result.popularityScore >= 80}"><span class="badge badge-high">Popular Creator</span></c:if>
            <c:if test="${result.reliabilityScore >= 80}"><span class="badge badge-high">Reliable Creator</span></c:if>
            <c:if test="${result.qualityScore >= 80}"><span class="badge badge-high">High Quality Drafts</span></c:if>
            <c:if test="${result.overallRank > 10}"><span class="badge badge-low">Developing</span></c:if>
        </div>
    </div>

    <div class="section-card">
        <h3 class="section-title compact-title">Period Information</h3>
        <p>Period: #${currentPeriodId}</p>
        <p>Calculated: ${result.calculatedAt}</p>
    </div>

    <div class="section-card">
        <h3 class="section-title compact-title">Editorial Comments</h3>
        <c:if test="${not empty editorialComments}">
            <div style="margin: 16px 0;">
                <c:forEach items="${editorialComments}" var="comment">
                    <div style="background: #f5f5f5; padding: 12px; border-radius: 8px; margin-bottom: 12px;">
                        <div style="display: flex; justify-content: space-between; margin-bottom: 8px;">
                            <strong>${comment.boardMemberName}</strong>
                            <small style="color: #666;">${comment.createdAt}</small>
                        </div>
                        <p style="margin: 0;">${comment.comment}</p>
                    </div>
                </c:forEach>
            </div>
        </c:if>
        <c:if test="${empty editorialComments}">
            <p class="muted">No editorial comments yet.</p>
        </c:if>
        
        <c:if test="${sessionScope.AUTH_USER.hasRole('EDITORIAL_BOARD') && not empty result}">
            <div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid #e0e0e0;">
                <form method="post" action="${pageContext.request.contextPath}/main/analytics/comments/${currentPeriodId}" class="form-grid">
                    <label>Add Your Comment</label>
                    <textarea name="comment" rows="3" required placeholder="Share your review or recommendations..."></textarea>
                    <input type="hidden" name="mangakaId" value="${mangakaId}" />
                    <button class="btn primary" type="submit">Submit Comment</button>
                </form>
            </div>
        </c:if>
    </div>
</c:if>

<c:if test="${empty result}">
    <div class="section-card">
        <p class="muted">No performance data available for this mangaka in the selected period.</p>
    </div>
</c:if>

<div class="section-card">
    <h3 class="section-title compact-title">View Other Periods</h3>
    <form method="get" action="${pageContext.request.contextPath}/main/analytics/mangaka/${mangakaId}" class="form-grid">
        <label>Select Period</label>
        <select name="periodId">
            <c:forEach items="${periods}" var="period">
                <option value="${period.id}" ${currentPeriodId == period.id ? 'selected' : ''}>${period.name}</option>
            </c:forEach>
        </select>
        <button class="btn primary" type="submit">View Period</button>
    </form>
</div>

<a class="btn" href="${pageContext.request.contextPath}/main/analytics">Back to Analytics</a>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
