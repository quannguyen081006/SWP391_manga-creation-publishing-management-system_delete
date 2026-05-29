-- Keeps older local databases compatible with the current DecisionSession model.
IF COL_LENGTH('DecisionSession', 'systemSuggestion') IS NULL
BEGIN
    ALTER TABLE DecisionSession
    ADD systemSuggestion VARCHAR(20) NULL;
END
GO

IF COL_LENGTH('VoteEntry', 'revenue') IS NULL
BEGIN
    ALTER TABLE VoteEntry
    ADD revenue DECIMAL(15, 2) NOT NULL
        CONSTRAINT DF_VoteEntry_revenue DEFAULT ((0));
END
GO
