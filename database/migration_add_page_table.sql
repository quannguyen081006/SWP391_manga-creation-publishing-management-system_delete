-- Run on MangaEditorialDB before using chapter page workspace features.
USE MangaEditorialDB;
GO

IF OBJECT_ID(N'dbo.Page', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Page (
        id BIGINT IDENTITY(1,1) NOT NULL,
        chapterId BIGINT NOT NULL,
        pageNumber INT NOT NULL,
        imageUrl NVARCHAR(512) NULL,
        uploadedBy BIGINT NULL,
        uploadedAt DATETIME NULL,
        status VARCHAR(20) NOT NULL CONSTRAINT DF_Page_status DEFAULT ('EMPTY'),
        createdAt DATETIME NOT NULL CONSTRAINT DF_Page_createdAt DEFAULT (GETDATE()),
        CONSTRAINT PK_Page PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_Page_Chapter FOREIGN KEY (chapterId) REFERENCES dbo.Chapter(id),
        CONSTRAINT UQ_Page_chapter_page UNIQUE (chapterId, pageNumber)
    );
    CREATE INDEX IX_Page_chapterId ON dbo.Page(chapterId);
END
GO

IF COL_LENGTH('dbo.Chapter', 'totalPages') IS NULL
    ALTER TABLE dbo.Chapter ADD totalPages INT NULL;
GO

IF COL_LENGTH('dbo.ChapterImage', 'pageId') IS NULL
    ALTER TABLE dbo.ChapterImage ADD pageId BIGINT NULL;
GO

IF COL_LENGTH('dbo.PageTask', 'pageId') IS NULL
    ALTER TABLE dbo.PageTask ADD pageId BIGINT NULL;
GO

IF COL_LENGTH('dbo.PageTask', 'rejectionReason') IS NULL
    ALTER TABLE dbo.PageTask ADD rejectionReason NVARCHAR(300) NULL;
GO

IF COL_LENGTH('dbo.PageTask', 'approvalComment') IS NULL
    ALTER TABLE dbo.PageTask ADD approvalComment NVARCHAR(300) NULL;
GO

IF COL_LENGTH('dbo.PageTask', 'priority') IS NULL
    ALTER TABLE dbo.PageTask ADD priority VARCHAR(20) NULL CONSTRAINT DF_PageTask_priority DEFAULT ('NORMAL');
GO

IF COL_LENGTH('dbo.PageTask', 'notes') IS NULL
    ALTER TABLE dbo.PageTask ADD notes NVARCHAR(500) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ChapterImage_Page')
BEGIN
    ALTER TABLE dbo.ChapterImage WITH CHECK
        ADD CONSTRAINT FK_ChapterImage_Page FOREIGN KEY (pageId) REFERENCES dbo.Page(id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PageTask_Page')
BEGIN
    ALTER TABLE dbo.PageTask WITH CHECK
        ADD CONSTRAINT FK_PageTask_Page FOREIGN KEY (pageId) REFERENCES dbo.Page(id);
END
GO

PRINT 'migration_add_page_table.sql completed.';
GO
