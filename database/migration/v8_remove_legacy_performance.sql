-- Migration v8: Remove Legacy Performance Analysis Subsystem
-- This migration drops the legacy PerformancePeriod, PerformanceResult, PerformanceImportRecord, and EditorialComment tables
-- These tables are no longer needed as the new snapshot-based ranking pipeline (MangakaRankingRecord) is now the primary architecture

-- Drop foreign key constraints first
ALTER TABLE [dbo].[EditorialComment] DROP CONSTRAINT [FK_EditorialComment_Period];
ALTER TABLE [dbo].[EditorialComment] DROP CONSTRAINT [FK_EditorialComment_Mangaka];
ALTER TABLE [dbo].[EditorialComment] DROP CONSTRAINT [FK_EditorialComment_BoardMember];

ALTER TABLE [dbo].[PerformanceImportRecord] DROP CONSTRAINT [FK_PerformanceImportRecord_Period];
ALTER TABLE [dbo].[PerformanceImportRecord] DROP CONSTRAINT [FK_PerformanceImportRecord_Mangaka];

ALTER TABLE [dbo].[PerformanceResult] DROP CONSTRAINT [FK_PerformanceResult_Period];
ALTER TABLE [dbo].[PerformanceResult] DROP CONSTRAINT [FK_PerformanceResult_Mangaka];

-- Drop indexes
DROP INDEX IF EXISTS [IX_EditorialComment_Period] ON [dbo].[EditorialComment];
DROP INDEX IF EXISTS [IX_EditorialComment_Mangaka] ON [dbo].[EditorialComment];
DROP INDEX IF EXISTS [IX_EditorialComment_BoardMember] ON [dbo].[EditorialComment];
DROP INDEX IF EXISTS [IX_EditorialComment_Series] ON [dbo].[EditorialComment];

DROP INDEX IF EXISTS [IX_PerformanceResult_OverallRank] ON [dbo].[PerformanceResult];
DROP INDEX IF EXISTS [IX_PerformanceResult_Period] ON [dbo].[PerformanceResult];
DROP INDEX IF EXISTS [IX_PerformanceResult_PopularityRank] ON [dbo].[PerformanceResult];
DROP INDEX IF EXISTS [IX_PerformanceResult_QualityRank] ON [dbo].[PerformanceResult];
DROP INDEX IF EXISTS [IX_PerformanceResult_ReliabilityRank] ON [dbo].[PerformanceResult];

DROP INDEX IF EXISTS [IX_PerformancePeriod_Status] ON [dbo].[PerformancePeriod];

-- Drop tables
DROP TABLE IF EXISTS [dbo].[EditorialComment];
DROP TABLE IF EXISTS [dbo].[PerformanceImportRecord];
DROP TABLE IF EXISTS [dbo].[PerformanceResult];
DROP TABLE IF EXISTS [dbo].[PerformancePeriod];
