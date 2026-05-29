-- Performance Optimization Migration
-- Adds indexes and columns to improve Ranking and Decision system performance
-- NO BUSINESS LOGIC CHANGES - ONLY PERFORMANCE IMPROVEMENTS

USE [MangaEditorialDB]
GO

-- Add totalLikes and totalReads columns to RankingRecord for snapshot storage
-- This eliminates runtime aggregation on page load
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('RankingRecord') AND name = 'totalLikes')
BEGIN
    ALTER TABLE RankingRecord ADD totalLikes BIGINT DEFAULT 0;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('RankingRecord') AND name = 'totalReads')
BEGIN
    ALTER TABLE RankingRecord ADD totalReads BIGINT DEFAULT 0;
END
GO

-- Add revenueTrendSnapshot column to DecisionSession for static chart rendering
-- This eliminates runtime revenue aggregation on page load
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('DecisionSession') AND name = 'revenueTrendSnapshot')
BEGIN
    ALTER TABLE DecisionSession ADD revenueTrendSnapshot NVARCHAR(MAX) NULL;
END
GO

-- Create indexes for ranking queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_VoteEntry_periodId_seriesId' AND object_id = OBJECT_ID('VoteEntry'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_VoteEntry_periodId_seriesId 
    ON VoteEntry(periodId, seriesId);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RankingRecord_periodId' AND object_id = OBJECT_ID('RankingRecord'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_RankingRecord_periodId 
    ON RankingRecord(periodId);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RankingRecord_periodId_rankPosition' AND object_id = OBJECT_ID('RankingRecord'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_RankingRecord_periodId_rankPosition 
    ON RankingRecord(periodId, rankPosition);
END
GO

-- Create indexes for mangaka ranking queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_MangakaRankingRecord_periodId' AND object_id = OBJECT_ID('MangakaRankingRecord'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_MangakaRankingRecord_periodId 
    ON MangakaRankingRecord(periodId);
END
GO

-- Create indexes for decision queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DecisionSession_seriesId_status' AND object_id = OBJECT_ID('DecisionSession'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_DecisionSession_seriesId_status 
    ON DecisionSession(seriesId, status);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DecisionSession_openedAt' AND object_id = OBJECT_ID('DecisionSession'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_DecisionSession_openedAt 
    ON DecisionSession(openedAt DESC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DecisionVote_sessionId' AND object_id = OBJECT_ID('DecisionVote'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_DecisionVote_sessionId 
    ON DecisionVote(sessionId);
END
GO

-- Create index for revenue history queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RankingPeriod_status_endDate' AND object_id = OBJECT_ID('RankingPeriod'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_RankingPeriod_status_endDate 
    ON RankingPeriod(status, endDate);
END
GO

-- Create index for VoteEntry periodId queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_VoteEntry_periodId' AND object_id = OBJECT_ID('VoteEntry'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_VoteEntry_periodId 
    ON VoteEntry(periodId);
END
GO

-- Create index for VoteEntry seriesId queries (for revenue history)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_VoteEntry_seriesId' AND object_id = OBJECT_ID('VoteEntry'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_VoteEntry_seriesId 
    ON VoteEntry(seriesId);
END
GO
