<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html>
<head>
    <title>Manuscript Review Inbox</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css">
    <style>
        /* Professional Light Editorial Review Inbox Styles */
        
        .inbox-container {
            max-width: 1400px;
            margin: 32px auto;
            padding: 0 24px;
        }
        
        .inbox-header {
            margin-bottom: 28px;
        }
        
        .inbox-header h1 {
            margin: 0 0 8px;
            font-size: 32px;
            font-weight: 700;
            color: #111827;
        }
        
        .inbox-header p {
            margin: 0;
            color: #6b7280;
            font-size: 15px;
        }
        
        .inbox-table {
            width: 100%;
            border-collapse: collapse;
            background: #ffffff;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06);
            border-radius: 12px;
            overflow: hidden;
            border: 1px solid #e5e7eb;
        }
        
        .inbox-table th {
            background: #f9fafb;
            padding: 16px 20px;
            text-align: left;
            font-weight: 600;
            color: #374151;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            border-bottom: 2px solid #e5e7eb;
        }
        
        .inbox-table td {
            padding: 18px 20px;
            border-bottom: 1px solid #e5e7eb;
            vertical-align: middle;
        }
        
        .inbox-table tr:last-child td {
            border-bottom: none;
        }
        
        .inbox-table tr:hover {
            background: #f8fafc;
        }
        
        .inbox-table tbody tr {
            transition: background-color 0.15s ease;
        }
        
        /* Status Badges */
        .status-badge {
            display: inline-block;
            padding: 6px 14px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        
        .status-under_review { 
            background: #dbeafe; 
            color: #1d4ed8; 
            border: 1px solid #93c5fd;
        }
        
        /* Buttons */
        .btn {
            padding: 10px 18px;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            text-decoration: none;
            display: inline-block;
            transition: all 0.2s ease;
            background: #ffffff;
            color: #374151;
        }
        
        .btn:hover {
            background: #f9fafb;
            border-color: #9ca3af;
            transform: translateY(-1px);
        }
        
        .btn-primary { 
            background: #2563eb; 
            border-color: #2563eb;
            color: #ffffff;
        }
        
        .btn-primary:hover {
            background: #1d4ed8;
            border-color: #1d4ed8;
            box-shadow: 0 4px 12px rgba(37, 99, 235, 0.25);
        }
        
        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 80px 40px;
            color: #6b7280;
            background: #ffffff;
            border-radius: 12px;
            border: 2px dashed #e5e7eb;
        }
        
        .empty-state h3 {
            margin: 0 0 8px;
            color: #374151;
            font-size: 20px;
            font-weight: 600;
        }
        
        .empty-state p {
            margin: 0;
            font-size: 14px;
        }
        
        /* Chapter Info */
        .chapter-info {
            font-size: 14px;
            font-weight: 500;
            color: #111827;
        }
        
        .chapter-series {
            color: #6b7280;
            font-size: 12px;
            margin-top: 4px;
        }
    </style>
</head>
<body>
    <jsp:include page="/WEB-INF/jsp/common/header.jsp"/>
    
    <div class="inbox-container">
        <div class="inbox-header">
            <h1>Manuscript Review Inbox</h1>
            <p>
                <c:if test="${isAdmin}">
                    All manuscripts waiting for review
                </c:if>
                <c:if test="${not isAdmin}">
                    Manuscripts from your assigned series waiting for review
                </c:if>
            </p>
        </div>

        <c:if test="${empty underReviewVersions}">
            <div class="empty-state">
                <h3>No manuscript submissions waiting for review</h3>
                <p>When manuscripts are submitted for review, they will appear here.</p>
            </div>
        </c:if>

        <c:if test="${not empty underReviewVersions}">
            <table class="inbox-table">
                <thead>
                    <tr>
                        <th>Chapter</th>
                        <th>Version</th>
                        <th>Status</th>
                        <th>Mangaka</th>
                        <th>Submitted At</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="version" items="${underReviewVersions}">
                        <c:set var="chapter" value="${chapterMap[version.id]}"/>
                        <tr>
                            <td>
                                <div class="chapter-info">
                                    <strong>Chapter ${chapter.chapterNumber}</strong>: ${chapter.title}
                                </div>
                                <div class="chapter-series">
                                    Series ID: ${chapter.seriesId}
                                </div>
                            </td>
                            <td>
                                <span style="font-weight: 600; color: #111827;">v${version.version}</span>
                            </td>
                            <td>
                                <span class="status-badge status-under_review">${version.status}</span>
                            </td>
                            <td>
                                <span style="color: #374151; font-weight: 500;">${mangakaNames[version.id]}</span>
                            </td>
                            <td>
                                <span style="color: #6b7280; font-size: 13px;">${submittedAtMap[version.id]}</span>
                            </td>
                            <td>
                                <a href="${pageContext.request.contextPath}/main/manuscript-workspace/${version.id}" class="btn btn-primary">
                                    Review Workspace
                                </a>
                            </td>
                        </tr>
                    </c:forEach>
                </tbody>
            </table>
        </c:if>
    </div>
</body>
</html>
