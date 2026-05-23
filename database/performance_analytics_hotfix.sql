USE [MangaEditorialDB];
GO

IF OBJECT_ID(N'dbo.PerformancePeriod', N'U') IS NULL
BEGIN
    THROW 50001, 'PerformancePeriod table does not exist. Run database/schema.sql first.', 1;
END;
GO

IF COL_LENGTH('dbo.PerformancePeriod', 'importedAt') IS NULL
BEGIN
    ALTER TABLE dbo.PerformancePeriod
        ADD importedAt DATETIME NULL;
END;
GO

IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_PerformancePeriod_Status'
      AND parent_object_id = OBJECT_ID(N'dbo.PerformancePeriod')
)
BEGIN
    ALTER TABLE dbo.PerformancePeriod
        DROP CONSTRAINT CK_PerformancePeriod_Status;
END;
GO

ALTER TABLE dbo.PerformancePeriod WITH CHECK
    ADD CONSTRAINT CK_PerformancePeriod_Status
    CHECK ([status] IN ('OPEN', 'IMPORTED', 'CALCULATED'));
GO

ALTER TABLE dbo.PerformancePeriod
    CHECK CONSTRAINT CK_PerformancePeriod_Status;
GO

PRINT 'Performance analytics schema hotfix completed.';
GO
