<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manga Editorial System - Login</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body class="login-page">
    <div class="login-orb login-orb-a"></div>
    <div class="login-orb login-orb-b"></div>

    <main class="login-wrap" role="main">
        <section class="login-panel" aria-label="Sign in form">
            <div class="login-brand">
                <div class="login-brand-mark">M</div>
                <div>
                    <h1>MangaFlow</h1>
                    <p>Editorial Publishing Hub</p>
                </div>
            </div>

            <h2 class="login-title">Welcome back</h2>
            <p class="login-subtitle">Sign in to continue managing proposals, chapters, and manuscripts.</p>

            <c:if test="${not empty error}">
                <div class="alert error">${error}</div>
            </c:if>

            <form method="post" action="${pageContext.request.contextPath}/main/login" class="login-form" novalidate>
                <label class="login-label" for="username">Username</label>
                <input id="username" class="login-input" type="text" name="username" value="${username}" required autocomplete="username" />

                <label class="login-label" for="password">Password</label>
                <input id="password" class="login-input" type="password" name="password" required autocomplete="current-password" />

                <button type="submit" class="login-submit">Sign In</button>
            </form>

            <div class="login-meta">Role-based access is enforced at API level.</div>
        </section>
    </main>
</body>
</html>


