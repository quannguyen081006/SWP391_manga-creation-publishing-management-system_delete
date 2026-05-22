-- Performance Analytics Tables (Independent from Ranking Period)
-- These tables are for Mangaka Performance Analytics only
-- They are completely separate from RankingPeriod and RankingRecord

-- PerformancePeriod: Manages evaluation periods for mangaka performance
CREATE TABLE PerformancePeriod (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    startDate DATE NOT NULL,
    endDate DATE NOT NULL,
    status NVARCHAR(20) NOT NULL DEFAULT 'OPEN', -- OPEN, CLOSED, CALCULATED
    createdAt DATETIME NOT NULL DEFAULT GETDATE(),
    calculatedAt DATETIME NULL,
    CONSTRAINT CK_PerformancePeriod_Status CHECK (status IN ('OPEN', 'CLOSED', 'CALCULATED')),
    CONSTRAINT CK_PerformancePeriod_Dates CHECK (endDate >= startDate)
);

-- PerformanceVote: Stores board member evaluations for mangaka
CREATE TABLE PerformanceVote (
    id INT IDENTITY(1,1) PRIMARY KEY,
    periodId INT NOT NULL,
    mangakaId BIGINT NOT NULL,
    boardMemberId BIGINT NOT NULL,
    popularityScore INT NOT NULL CHECK (popularityScore >= 0 AND popularityScore <= 10),
    reliabilityScore INT NOT NULL CHECK (reliabilityScore >= 0 AND reliabilityScore <= 10),
    qualityScore INT NOT NULL CHECK (qualityScore >= 0 AND qualityScore <= 10),
    comment NVARCHAR(500) NULL,
    votedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_PerformanceVote_Period FOREIGN KEY (periodId) REFERENCES PerformancePeriod(id),
    CONSTRAINT FK_PerformanceVote_Mangaka FOREIGN KEY (mangakaId) REFERENCES [User](id),
    CONSTRAINT FK_PerformanceVote_BoardMember FOREIGN KEY (boardMemberId) REFERENCES [User](id),
    CONSTRAINT UQ_PerformanceVote_Unique UNIQUE (periodId, mangakaId, boardMemberId)
);

-- PerformanceResult: Stores calculated analytics results (immutable)
CREATE TABLE PerformanceResult (
    id INT IDENTITY(1,1) PRIMARY KEY,
    periodId INT NOT NULL,
    mangakaId BIGINT NOT NULL,
    overallScore DECIMAL(5,2) NOT NULL,
    popularityScore DECIMAL(5,2) NOT NULL,
    reliabilityScore DECIMAL(5,2) NOT NULL,
    qualityScore DECIMAL(5,2) NOT NULL,
    overallRank INT NOT NULL,
    popularityRank INT NOT NULL,
    reliabilityRank INT NOT NULL,
    qualityRank INT NOT NULL,
    calculatedAt DATETIME NOT NULL,
    CONSTRAINT FK_PerformanceResult_Period FOREIGN KEY (periodId) REFERENCES PerformancePeriod(id),
    CONSTRAINT FK_PerformanceResult_Mangaka FOREIGN KEY (mangakaId) REFERENCES [User](id),
    CONSTRAINT UQ_PerformanceResult_Unique UNIQUE (periodId, mangakaId)
);

-- Indexes for better query performance
CREATE INDEX IX_PerformanceVote_Period ON PerformanceVote(periodId);
CREATE INDEX IX_PerformanceVote_Mangaka ON PerformanceVote(mangakaId);
CREATE INDEX IX_PerformanceVote_BoardMember ON PerformanceVote(boardMemberId);
CREATE INDEX IX_PerformanceResult_Period ON PerformanceResult(periodId);
CREATE INDEX IX_PerformanceResult_OverallRank ON PerformanceResult(periodId, overallRank);
CREATE INDEX IX_PerformanceResult_PopularityRank ON PerformanceResult(periodId, popularityRank);
CREATE INDEX IX_PerformanceResult_ReliabilityRank ON PerformanceResult(periodId, reliabilityRank);
CREATE INDEX IX_PerformanceResult_QualityRank ON PerformanceResult(periodId, qualityRank);
