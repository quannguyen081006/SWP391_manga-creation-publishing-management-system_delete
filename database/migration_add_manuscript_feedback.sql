-- Migration script to add feedback column to Manuscript table
-- Run this on existing databases to add the feedback field

USE MangaEditorialDB;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID('Manuscript') 
    AND name = 'feedback'
)
BEGIN
    ALTER TABLE Manuscript ADD feedback NVARCHAR(MAX) NULL;
    PRINT 'Added feedback column to Manuscript table.';
END
ELSE
BEGIN
    PRINT 'Feedback column already exists in Manuscript table.';
END
GO
