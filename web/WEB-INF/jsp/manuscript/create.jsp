<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Create Manuscript</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Create Manuscript</h2>
<p class="page-sub">Submit a new manuscript for editorial review</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>
<c:if test="${not empty success}"><div class="alert success">${success}</div></c:if>

<div class="section-card">
    <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/create" class="form-grid">
        <label>Select Chapter</label>
        <select name="chapterId" required>
            <option value="">Select a chapter</option>
            <c:forEach items="${chapters}" var="ch">
                <option value="${ch.id}">
                    #${ch.seriesId} - ${ch.seriesTitle} | Ch. ${ch.chapterNumber} - ${ch.chapterTitle}
                </option>
            </c:forEach>
        </select>

        <label>File URL</label>
        <input type="text" name="fileUrl" placeholder="Enter manuscript file URL" required />

        <button class="btn primary" type="submit">Submit Manuscript</button>
    </form>
</div>

<a class="btn" href="${pageContext.request.contextPath}/main/manuscripts">Cancel</a>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
