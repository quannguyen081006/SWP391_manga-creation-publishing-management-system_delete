USE [MangaEditorialDB];
GO

IF OBJECT_ID(N'dbo.Notification', N'U') IS NULL
BEGIN
    THROW 50002, 'Notification table does not exist. Run database/schema.sql first.', 1;
END;
GO

IF COL_LENGTH('dbo.Notification', 'title') IS NULL
BEGIN
    ALTER TABLE dbo.Notification
        ADD title NVARCHAR(200) NULL;
END;
GO

IF COL_LENGTH('dbo.Notification', 'viewUrl') IS NULL
BEGIN
    ALTER TABLE dbo.Notification
        ADD viewUrl NVARCHAR(500) NULL;
END;
GO

IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_Notification_refType'
      AND parent_object_id = OBJECT_ID(N'dbo.Notification')
)
BEGIN
    ALTER TABLE dbo.Notification
        DROP CONSTRAINT CK_Notification_refType;
END;
GO

ALTER TABLE dbo.Notification WITH CHECK
    ADD CONSTRAINT CK_Notification_refType
    CHECK ([referenceType] IS NULL OR [referenceType] IN ('TASK', 'CHAPTER', 'MANUSCRIPT', 'PROPOSAL', 'DECISION', 'SERIES'));
GO

ALTER TABLE dbo.Notification
    CHECK CONSTRAINT CK_Notification_refType;
GO

UPDATE dbo.Notification
SET title = CASE
        WHEN type LIKE 'TASK%' THEN 'Task update'
        WHEN type LIKE 'CHAPTER%' THEN 'Chapter update'
        WHEN type LIKE 'MANUSCRIPT%' THEN 'Manuscript update'
        WHEN type LIKE 'DECISION%' THEN 'Decision update'
        WHEN type LIKE 'PROPOSAL%' THEN 'Proposal update'
        WHEN type LIKE 'SERIES%' THEN 'Series update'
        ELSE 'Notification'
    END
WHERE title IS NULL;
GO

UPDATE dbo.Notification
SET viewUrl = CASE
        WHEN referenceType = 'TASK' AND type = 'TASK_ESCALATED' THEN '/main/tasks/' + CAST(referenceId AS VARCHAR(30)) + '?tab=history'
        WHEN referenceType = 'TASK' THEN '/main/tasks/' + CAST(referenceId AS VARCHAR(30))
        WHEN referenceType = 'CHAPTER' THEN '/main/chapters/' + CAST(referenceId AS VARCHAR(30))
        WHEN referenceType = 'MANUSCRIPT' AND type = 'MANUSCRIPT_REVIEW_REMINDER' THEN '/main/manuscripts/' + CAST(referenceId AS VARCHAR(30)) + '/review'
        WHEN referenceType = 'MANUSCRIPT' AND type = 'MANUSCRIPT_REJECTED' THEN '/main/manuscripts/' + CAST(referenceId AS VARCHAR(30)) + '?tab=feedback'
        WHEN referenceType = 'MANUSCRIPT' THEN '/main/manuscripts/' + CAST(referenceId AS VARCHAR(30))
        WHEN referenceType = 'PROPOSAL' AND type LIKE '%VOTE%' THEN '/main/proposals/' + CAST(referenceId AS VARCHAR(30)) + '/vote'
        WHEN referenceType = 'PROPOSAL' THEN '/main/proposals/' + CAST(referenceId AS VARCHAR(30))
        WHEN referenceType IN ('DECISION', 'DECISION_SESSION') THEN '/main/decisions/' + CAST(referenceId AS VARCHAR(30))
        WHEN referenceType = 'SERIES' THEN '/main/series/' + CAST(referenceId AS VARCHAR(30))
        ELSE NULL
    END
WHERE viewUrl IS NULL
  AND referenceId IS NOT NULL;
GO

PRINT 'Notification viewUrl schema hotfix completed.';
GO
