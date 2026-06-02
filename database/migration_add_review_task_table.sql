-- Migration: Add ReviewTask table for SLA tracking
-- Business Rules: BR-51, BR-52
-- This table was referenced in code but missing from database schema
-- Date: June 3, 2026

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReviewTask]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ReviewTask](
        [id] [bigint] IDENTITY(1,1) NOT NULL,
        [versionId] [bigint] NOT NULL,
        [reviewerId] [bigint] NOT NULL,
        [assignedAt] [datetime] NOT NULL,
        [dueAt] [datetime] NOT NULL,
        [reviewStatus] [varchar](20) NOT NULL,
     CONSTRAINT [PK_ReviewTask] PRIMARY KEY CLUSTERED 
    (
        [id] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
    ) ON [PRIMARY]
    
    PRINT 'ReviewTask table created successfully'
END
ELSE
BEGIN
    PRINT 'ReviewTask table already exists'
END
GO

-- Add foreign key to ManuscriptVersion
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ReviewTask_ManuscriptVersion' AND parent_object_id = OBJECT_ID('ReviewTask'))
BEGIN
    ALTER TABLE [dbo].[ReviewTask]  WITH CHECK ADD  CONSTRAINT [FK_ReviewTask_ManuscriptVersion] FOREIGN KEY([versionId])
    REFERENCES [dbo].[ManuscriptVersion] ([id])
    ON DELETE CASCADE
    
    ALTER TABLE [dbo].[ReviewTask] CHECK CONSTRAINT [FK_ReviewTask_ManuscriptVersion]
    
    PRINT 'FK_ReviewTask_ManuscriptVersion created successfully'
END
ELSE
BEGIN
    PRINT 'FK_ReviewTask_ManuscriptVersion already exists'
END
GO

-- Add foreign key to User (reviewer)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ReviewTask_User' AND parent_object_id = OBJECT_ID('ReviewTask'))
BEGIN
    ALTER TABLE [dbo].[ReviewTask]  WITH CHECK ADD  CONSTRAINT [FK_ReviewTask_User] FOREIGN KEY([reviewerId])
    REFERENCES [dbo].[User] ([id])
    ON DELETE NO ACTION
    
    ALTER TABLE [dbo].[ReviewTask] CHECK CONSTRAINT [FK_ReviewTask_User]
    
    PRINT 'FK_ReviewTask_User created successfully'
END
ELSE
BEGIN
    PRINT 'FK_ReviewTask_User already exists'
END
GO

-- Add index for versionId lookup (improves query performance)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ReviewTask_versionId' AND object_id = OBJECT_ID('ReviewTask'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ReviewTask_versionId] ON [dbo].[ReviewTask]([versionId])
    PRINT 'IX_ReviewTask_versionId created successfully'
END
ELSE
BEGIN
    PRINT 'IX_ReviewTask_versionId already exists'
END
GO

-- Add index for reviewerId lookup (improves query performance)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ReviewTask_reviewerId' AND object_id = OBJECT_ID('ReviewTask'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ReviewTask_reviewerId] ON [dbo].[ReviewTask]([reviewerId])
    PRINT 'IX_ReviewTask_reviewerId created successfully'
END
ELSE
BEGIN
    PRINT 'IX_ReviewTask_reviewerId already exists'
END
GO

-- Add index for dueAt lookup (improves overdue task queries)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ReviewTask_dueAt' AND object_id = OBJECT_ID('ReviewTask'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ReviewTask_dueAt] ON [dbo].[ReviewTask]([dueAt])
    PRINT 'IX_ReviewTask_dueAt created successfully'
END
ELSE
BEGIN
    PRINT 'IX_ReviewTask_dueAt already exists'
END
GO

-- Add check constraint for reviewStatus values
IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_ReviewTask_reviewStatus' AND parent_object_id = OBJECT_ID('ReviewTask'))
BEGIN
    ALTER TABLE [dbo].[ReviewTask]  WITH CHECK ADD  CONSTRAINT [CK_ReviewTask_reviewStatus] CHECK  (([reviewStatus]='ASSIGNED' OR [reviewStatus]='IN_PROGRESS' OR [reviewStatus]='COMPLETED' OR [reviewStatus]='OVERDUE'))
    ALTER TABLE [dbo].[ReviewTask] CHECK CONSTRAINT [CK_ReviewTask_reviewStatus]
    PRINT 'CK_ReviewTask_reviewStatus created successfully'
END
ELSE
BEGIN
    PRINT 'CK_ReviewTask_reviewStatus already exists'
END
GO

PRINT 'ReviewTask table migration completed successfully'
GO
