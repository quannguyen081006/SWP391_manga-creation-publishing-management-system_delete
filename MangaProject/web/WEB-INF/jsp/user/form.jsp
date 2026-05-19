<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>User Form</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">${editing ? 'Edit User' : 'Create User'}</h2>
<p class="page-sub">Admin account management</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-card">
<c:choose>
<c:when test="${editing}">
    <form class="form-grid" method="post" action="${pageContext.request.contextPath}/main/users/${editUser.id}/update">
        <label>Username</label>
        <input type="text" value="${editUser.username}" disabled />
        <label>Full Name</label>
        <input type="text" name="fullName" value="${editUser.fullName}" required />
        <label>Email</label>
        <input type="email" name="email" value="${editUser.email}" required />
        <button class="btn primary" type="submit">Update User</button>
    </form>
</c:when>
<c:otherwise>
    <form class="form-grid" method="post" action="${pageContext.request.contextPath}/main/users/create">
        <label>Username</label>
        <input type="text" name="username" required />
        <label>Password</label>
        <input type="text" name="password" required />
        <label>Full Name</label>
        <input type="text" name="fullName" required />
        <label>Email</label>
        <input type="email" name="email" required />
        <label>Initial Role</label>
        <select name="role">
            <option value="">(none)</option>
            <option value="ADMIN">ADMIN</option>
            <option value="MANGAKA">MANGAKA</option>
            <option value="ASSISTANT">ASSISTANT</option>
            <option value="TANTOU_EDITOR">TANTOU_EDITOR</option>
            <option value="EDITORIAL_BOARD">EDITORIAL_BOARD</option>
        </select>
        <button class="btn primary" type="submit">Create User</button>
    </form>
</c:otherwise>
</c:choose>
</div>

<div style="margin-top:10px;"><a class="btn" href="${pageContext.request.contextPath}/main/users">Back</a></div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
