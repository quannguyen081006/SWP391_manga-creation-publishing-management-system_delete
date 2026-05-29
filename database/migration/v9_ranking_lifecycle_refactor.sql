-- Migration v9: Ranking Lifecycle Refactor
-- Add new lifecycle states for automated monthly ranking workflow

-- Drop existing check constraint on status
ALTER TABLE [dbo].[RankingPeriod] DROP CONSTRAINT [CK_RankingPeriod_status];
GO

-- Add new check constraint with additional states
ALTER TABLE [dbo].[RankingPeriod]  WITH CHECK ADD  CONSTRAINT [CK_RankingPeriod_status] CHECK  (([status]='CALCULATED' OR [status]='CALCULATING' OR [status]='CLOSED' OR [status]='OPEN' OR [status]='UPCOMING'));
GO
ALTER TABLE [dbo].[RankingPeriod] CHECK CONSTRAINT [CK_RankingPeriod_status];
GO

-- Update default status to UPCOMING for new periods
ALTER TABLE [dbo].[RankingPeriod] DROP CONSTRAINT [DF_RankingPeriod_status];
GO
ALTER TABLE [dbo].[RankingPeriod] ADD  CONSTRAINT [DF_RankingPeriod_status]  DEFAULT ('UPCOMING') FOR [status];
GO
