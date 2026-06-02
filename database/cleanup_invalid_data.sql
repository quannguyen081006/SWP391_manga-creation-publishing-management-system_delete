-- Cleanup Script: Remove invalid data before adding FK constraints
-- This script MUST be run BEFORE migration_add_fk_manuscriptversion_chapter.sql
-- Date: June 3, 2026

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Starting cleanup of invalid data...'
GO

-- Step 1: Identify and report invalid ManuscriptVersion records with invalid chapterId
PRINT 'Step 1: Checking for ManuscriptVersion records with invalid chapterId...'
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ManuscriptVersion]') AND type in (N'U'))
BEGIN
    -- Count records with NULL chapterId
    DECLARE @nullChapterIdCount INT
    SELECT @nullChapterIdCount = COUNT(*) FROM ManuscriptVersion WHERE chapterId IS NULL
    
    IF @nullChapterIdCount > 0
    BEGIN
        PRINT 'WARNING: Found ' + CAST(@nullChapterIdCount AS VARCHAR) + ' ManuscriptVersion records with NULL chapterId'
        PRINT 'These records will be deleted to prevent FK constraint violation'
        
        -- Display the records before deletion
        SELECT id, chapterId, version, status, createdAt 
        FROM ManuscriptVersion 
        WHERE chapterId IS NULL
        PRINT 'Displaying records with NULL chapterId above for review'
    END
    ELSE
    BEGIN
        PRINT 'No ManuscriptVersion records with NULL chapterId found'
    END
    
    -- Count records with chapterId = 0
    DECLARE @zeroChapterIdCount INT
    SELECT @zeroChapterIdCount = COUNT(*) FROM ManuscriptVersion WHERE chapterId = 0
    
    IF @zeroChapterIdCount > 0
    BEGIN
        PRINT 'WARNING: Found ' + CAST(@zeroChapterIdCount AS VARCHAR) + ' ManuscriptVersion records with chapterId = 0'
        PRINT 'These records will be deleted to prevent FK constraint violation'
        
        -- Display the records before deletion
        SELECT id, chapterId, version, status, createdAt 
        FROM ManuscriptVersion 
        WHERE chapterId = 0
        PRINT 'Displaying records with chapterId = 0 above for review'
    END
    ELSE
    BEGIN
        PRINT 'No ManuscriptVersion records with chapterId = 0 found'
    END
    
    -- Count records with chapterId that doesn't exist in Chapter table
    DECLARE @orphanedChapterIdCount INT
    SELECT @orphanedChapterIdCount = COUNT(*) 
    FROM ManuscriptVersion mv
    WHERE mv.chapterId IS NOT NULL 
      AND mv.chapterId != 0
      AND NOT EXISTS (SELECT 1 FROM Chapter c WHERE c.id = mv.chapterId)
    
    IF @orphanedChapterIdCount > 0
    BEGIN
        PRINT 'WARNING: Found ' + CAST(@orphanedChapterIdCount AS VARCHAR) + ' ManuscriptVersion records with orphaned chapterId'
        PRINT 'These records reference chapters that do not exist and will be deleted'
        
        -- Display the records before deletion
        SELECT mv.id, mv.chapterId, mv.version, mv.status, mv.createdAt
        FROM ManuscriptVersion mv
        WHERE mv.chapterId IS NOT NULL 
          AND mv.chapterId != 0
          AND NOT EXISTS (SELECT 1 FROM Chapter c WHERE c.id = mv.chapterId)
        PRINT 'Displaying records with orphaned chapterId above for review'
    END
    ELSE
    BEGIN
        PRINT 'No ManuscriptVersion records with orphaned chapterId found'
    END
END
ELSE
BEGIN
    PRINT 'ManuscriptVersion table does not exist - skipping cleanup'
END
GO

-- Step 2: Identify and report invalid ManuscriptProductionLock records
PRINT 'Step 2: Checking for ManuscriptProductionLock records with invalid chapterId...'
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ManuscriptProductionLock]') AND type in (N'U'))
BEGIN
    -- Count records with NULL chapterId
    DECLARE @nullLockChapterIdCount INT
    SELECT @nullLockChapterIdCount = COUNT(*) FROM ManuscriptProductionLock WHERE chapterId IS NULL
    
    IF @nullLockChapterIdCount > 0
    BEGIN
        PRINT 'WARNING: Found ' + CAST(@nullLockChapterIdCount AS VARCHAR) + ' ManuscriptProductionLock records with NULL chapterId'
        PRINT 'These orphaned locks will be deleted'
        
        -- Display the records before deletion
        SELECT id, chapterId, manuscriptVersionId, lockedAt, lockedBy
        FROM ManuscriptProductionLock 
        WHERE chapterId IS NULL
        PRINT 'Displaying orphaned locks with NULL chapterId above for review'
    END
    
    -- Count records with chapterId = 0
    DECLARE @zeroLockChapterIdCount INT
    SELECT @zeroLockChapterIdCount = COUNT(*) FROM ManuscriptProductionLock WHERE chapterId = 0
    
    IF @zeroLockChapterIdCount > 0
    BEGIN
        PRINT 'WARNING: Found ' + CAST(@zeroLockChapterIdCount AS VARCHAR) + ' ManuscriptProductionLock records with chapterId = 0'
        PRINT 'These orphaned locks will be deleted'
        
        -- Display the records before deletion
        SELECT id, chapterId, manuscriptVersionId, lockedAt, lockedBy
        FROM ManuscriptProductionLock 
        WHERE chapterId = 0
        PRINT 'Displaying orphaned locks with chapterId = 0 above for review'
    END
    
    -- Count records with chapterId that doesn't exist in Chapter table
    DECLARE @orphanedLockChapterIdCount INT
    SELECT @orphanedLockChapterIdCount = COUNT(*) 
    FROM ManuscriptProductionLock mpl
    WHERE mpl.chapterId IS NOT NULL 
      AND mpl.chapterId != 0
      AND NOT EXISTS (SELECT 1 FROM Chapter c WHERE c.id = mpl.chapterId)
    
    IF @orphanedLockChapterIdCount > 0
    BEGIN
        PRINT 'WARNING: Found ' + CAST(@orphanedLockChapterIdCount AS VARCHAR) + ' ManuscriptProductionLock records with orphaned chapterId'
        PRINT 'These orphaned locks will be deleted'
        
        -- Display the records before deletion
        SELECT mpl.id, mpl.chapterId, mpl.manuscriptVersionId, mpl.lockedAt, mpl.lockedBy
        FROM ManuscriptProductionLock mpl
        WHERE mpl.chapterId IS NOT NULL 
          AND mpl.chapterId != 0
          AND NOT EXISTS (SELECT 1 FROM Chapter c WHERE c.id = mpl.chapterId)
        PRINT 'Displaying orphaned locks with orphaned chapterId above for review'
    END
END
ELSE
BEGIN
    PRINT 'ManuscriptProductionLock table does not exist - skipping cleanup'
END
GO

-- Step 3: Delete invalid ManuscriptVersion records
PRINT 'Step 3: Deleting invalid ManuscriptVersion records...'
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ManuscriptVersion]') AND type in (N'U'))
BEGIN
    BEGIN TRANSACTION
    
    -- Delete records with NULL chapterId
    DELETE FROM ManuscriptVersion WHERE chapterId IS NULL
    DECLARE @deletedNullCount INT = @@ROWCOUNT
    IF @deletedNullCount > 0
        PRINT 'Deleted ' + CAST(@deletedNullCount AS VARCHAR) + ' ManuscriptVersion records with NULL chapterId'
    
    -- Delete records with chapterId = 0
    DELETE FROM ManuscriptVersion WHERE chapterId = 0
    DECLARE @deletedZeroCount INT = @@ROWCOUNT
    IF @deletedZeroCount > 0
        PRINT 'Deleted ' + CAST(@deletedZeroCount AS VARCHAR) + ' ManuscriptVersion records with chapterId = 0'
    
    -- Delete records with orphaned chapterId
    DELETE FROM ManuscriptVersion 
    WHERE chapterId IS NOT NULL 
      AND chapterId != 0
      AND NOT EXISTS (SELECT 1 FROM Chapter c WHERE c.id = ManuscriptVersion.chapterId)
    DECLARE @deletedOrphanedCount INT = @@ROWCOUNT
    IF @deletedOrphanedCount > 0
        PRINT 'Deleted ' + CAST(@deletedOrphanedCount AS VARCHAR) + ' ManuscriptVersion records with orphaned chapterId'
    
    COMMIT TRANSACTION
    PRINT 'ManuscriptVersion cleanup completed successfully'
END
GO

-- Step 4: Delete invalid ManuscriptProductionLock records
PRINT 'Step 4: Deleting invalid ManuscriptProductionLock records...'
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ManuscriptProductionLock]') AND type in (N'U'))
BEGIN
    BEGIN TRANSACTION
    
    -- Delete records with NULL chapterId
    DELETE FROM ManuscriptProductionLock WHERE chapterId IS NULL
    DECLARE @deletedLockNullCount INT = @@ROWCOUNT
    IF @deletedLockNullCount > 0
        PRINT 'Deleted ' + CAST(@deletedLockNullCount AS VARCHAR) + ' ManuscriptProductionLock records with NULL chapterId'
    
    -- Delete records with chapterId = 0
    DELETE FROM ManuscriptProductionLock WHERE chapterId = 0
    DECLARE @deletedLockZeroCount INT = @@ROWCOUNT
    IF @deletedLockZeroCount > 0
        PRINT 'Deleted ' + CAST(@deletedLockZeroCount AS VARCHAR) + ' ManuscriptProductionLock records with chapterId = 0'
    
    -- Delete records with orphaned chapterId
    DELETE FROM ManuscriptProductionLock 
    WHERE chapterId IS NOT NULL 
      AND chapterId != 0
      AND NOT EXISTS (SELECT 1 FROM Chapter c WHERE c.id = ManuscriptProductionLock.chapterId)
    DECLARE @deletedLockOrphanedCount INT = @@ROWCOUNT
    IF @deletedLockOrphanedCount > 0
        PRINT 'Deleted ' + CAST(@deletedLockOrphanedCount AS VARCHAR) + ' ManuscriptProductionLock records with orphaned chapterId'
    
    COMMIT TRANSACTION
    PRINT 'ManuscriptProductionLock cleanup completed successfully'
END
GO

-- Step 5: Verify cleanup
PRINT 'Step 5: Verifying cleanup results...'
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ManuscriptVersion]') AND type in (N'U'))
BEGIN
    DECLARE @remainingInvalidCount INT
    SELECT @remainingInvalidCount = COUNT(*) 
    FROM ManuscriptVersion mv
    WHERE mv.chapterId IS NULL 
       OR mv.chapterId = 0
       OR (mv.chapterId IS NOT NULL AND mv.chapterId != 0 AND NOT EXISTS (SELECT 1 FROM Chapter c WHERE c.id = mv.chapterId))
    
    IF @remainingInvalidCount = 0
        PRINT 'SUCCESS: All invalid ManuscriptVersion records have been cleaned up'
    ELSE
        PRINT 'ERROR: Still found ' + CAST(@remainingInvalidCount AS VARCHAR) + ' invalid ManuscriptVersion records after cleanup'
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ManuscriptProductionLock]') AND type in (N'U'))
BEGIN
    DECLARE @remainingInvalidLockCount INT
    SELECT @remainingInvalidLockCount = COUNT(*) 
    FROM ManuscriptProductionLock mpl
    WHERE mpl.chapterId IS NULL 
       OR mpl.chapterId = 0
       OR (mpl.chapterId IS NOT NULL AND mpl.chapterId != 0 AND NOT EXISTS (SELECT 1 FROM Chapter c WHERE c.id = mpl.chapterId))
    
    IF @remainingInvalidLockCount = 0
        PRINT 'SUCCESS: All invalid ManuscriptProductionLock records have been cleaned up'
    ELSE
        PRINT 'ERROR: Still found ' + CAST(@remainingInvalidLockCount AS VARCHAR) + ' invalid ManuscriptProductionLock records after cleanup'
END
GO

PRINT 'Cleanup script completed successfully'
PRINT 'You can now run migration_add_fk_manuscriptversion_chapter.sql'
GO
