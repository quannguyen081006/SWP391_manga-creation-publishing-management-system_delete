-- Migration: Add FK constraint to ManuscriptVersion.chapterId
-- Business Rules: Prevents orphaned manuscript versions with invalid chapterId
-- This migration must be run AFTER cleanup_invalid_data.sql to ensure data integrity
-- Date: June 3, 2026

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Check if ManuscriptVersion table exists
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ManuscriptVersion]') AND type in (N'U'))
BEGIN
    PRINT 'ERROR: ManuscriptVersion table does not exist. Cannot add FK constraint.'
    RETURN
END
GO

-- Check if Chapter table exists
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Chapter]') AND type in (N'U'))
BEGIN
    PRINT 'ERROR: Chapter table does not exist. Cannot add FK constraint.'
    RETURN
END
GO

-- Add foreign key constraint to ManuscriptVersion.chapterId
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ManuscriptVersion_Chapter' AND parent_object_id = OBJECT_ID('ManuscriptVersion'))
BEGIN
    ALTER TABLE [dbo].[ManuscriptVersion]  WITH CHECK ADD  CONSTRAINT [FK_ManuscriptVersion_Chapter] FOREIGN KEY([chapterId])
    REFERENCES [dbo].[Chapter] ([id])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    
    ALTER TABLE [dbo].[ManuscriptVersion] CHECK CONSTRAINT [FK_ManuscriptVersion_Chapter]
    
    PRINT 'FK_ManuscriptVersion_Chapter created successfully'
END
ELSE
BEGIN
    PRINT 'FK_ManuscriptVersion_Chapter already exists'
END
GO

-- Verify the constraint was created
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ManuscriptVersion_Chapter' AND parent_object_id = OBJECT_ID('ManuscriptVersion'))
BEGIN
    PRINT 'Verification: FK_ManuscriptVersion_Chapter exists and is active'
END
ELSE
BEGIN
    PRINT 'ERROR: FK_ManuscriptVersion_Chapter was not created successfully'
END
GO

PRINT 'ManuscriptVersion.chapterId FK constraint migration completed successfully'
GO
