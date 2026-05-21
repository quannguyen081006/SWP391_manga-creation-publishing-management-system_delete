-- ============================================================
--  MANGA EDITORIAL SYSTEM — SQL Server DDL Script
--  Generated from Section 3 Domain Model / Entity Design
-- ============================================================

USE master;
GO

IF DB_ID('MangaEditorialDB') IS NOT NULL
    DROP DATABASE MangaEditorialDB;
GO

CREATE DATABASE MangaEditorialDB;
GO

USE MangaEditorialDB;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
--  MODULE 1: USER & ROLE
-- ============================================================

CREATE TABLE [Role] (
    id      BIGINT          NOT NULL,
    name    VARCHAR(50)     NOT NULL,
    CONSTRAINT PK_Role      PRIMARY KEY (id),
    CONSTRAINT UQ_Role_name UNIQUE      (name),
    CONSTRAINT CK_Role_name CHECK (name IN ('ADMIN','MANGAKA','ASSISTANT','TANTOU_EDITOR','EDITORIAL_BOARD'))
);
GO

CREATE TABLE [User] (
    id              BIGINT          NOT NULL IDENTITY(1,1),
    username        VARCHAR(100)    NOT NULL,
    passwordHash    VARCHAR(255)    NOT NULL,
    fullName        VARCHAR(255)    NOT NULL,
    email           VARCHAR(255)    NOT NULL,
    status          VARCHAR(10)     NOT NULL CONSTRAINT DF_User_status DEFAULT 'ACTIVE',
    createdAt       DATETIME        NOT NULL CONSTRAINT DF_User_createdAt DEFAULT GETDATE(),
    updatedAt       DATETIME        NOT NULL CONSTRAINT DF_User_updatedAt DEFAULT GETDATE(),
    CONSTRAINT PK_User              PRIMARY KEY (id),
    CONSTRAINT UQ_User_username     UNIQUE (username),
    CONSTRAINT UQ_User_email        UNIQUE (email),
    CONSTRAINT CK_User_status       CHECK (status IN ('ACTIVE','INACTIVE'))
);
GO

CREATE TABLE UserRole (
    userId  BIGINT  NOT NULL,
    roleId  BIGINT  NOT NULL,
    CONSTRAINT PK_UserRole          PRIMARY KEY (userId, roleId),
    CONSTRAINT FK_UserRole_User     FOREIGN KEY (userId) REFERENCES [User](id),
    CONSTRAINT FK_UserRole_Role     FOREIGN KEY (roleId) REFERENCES [Role](id)
);
GO

-- BR-USER-ADMIN: Role id 1 is seeded as ADMIN; keep exactly one admin assignment.
CREATE UNIQUE INDEX UX_UserRole_single_admin
ON UserRole(roleId)
WHERE roleId = 1;
GO

-- ============================================================
--  MODULE 2: PROPOSAL & TANTOU REVIEW
-- ============================================================

CREATE TABLE Proposal (
    id                  BIGINT          NOT NULL IDENTITY(1,1),
    mangakaId           BIGINT          NOT NULL,
    title               VARCHAR(255)    NOT NULL,
    genre               VARCHAR(100)    NOT NULL,
    synopsis            NVARCHAR(MAX)   NOT NULL,
    sampleFilePath      VARCHAR(512)    NOT NULL,
    originalFileName    NVARCHAR(255)   NOT NULL,
    approximateChapter  INT             NOT NULL,
    status              VARCHAR(20)     NOT NULL CONSTRAINT DF_Proposal_status DEFAULT 'DRAFT',
    submittedAt         DATETIME            NULL,
    rejectedAt          DATETIME            NULL,
    assignedEditorId    BIGINT              NULL,
    submitAttemptCount  INT             NOT NULL CONSTRAINT DF_Proposal_submitAttemptCount DEFAULT 0,
    createdAt           DATETIME        NOT NULL CONSTRAINT DF_Proposal_createdAt DEFAULT GETDATE(),
    updatedAt           DATETIME        NOT NULL CONSTRAINT DF_Proposal_updatedAt DEFAULT GETDATE(),
    CONSTRAINT PK_Proposal              PRIMARY KEY (id),
    CONSTRAINT FK_Proposal_Mangaka      FOREIGN KEY (mangakaId)        REFERENCES [User](id),
    CONSTRAINT FK_Proposal_Editor       FOREIGN KEY (assignedEditorId) REFERENCES [User](id),
    CONSTRAINT CK_Proposal_status       CHECK (status IN (
        'DRAFT','UNDER_REVIEW','REVISION_REQUESTED','APPROVED','REJECTED')),
    CONSTRAINT CK_Proposal_approxChapter CHECK (approximateChapter >= 1),
    CONSTRAINT CK_Proposal_submitAttempts CHECK (submitAttemptCount BETWEEN 0 AND 2)
);
GO

CREATE TABLE ProposalHistory (
    id                  BIGINT          NOT NULL IDENTITY(1,1),
    proposalId          BIGINT          NOT NULL,
    actorId             BIGINT              NULL,
    actorRole           VARCHAR(50)     NOT NULL,
    actionType          VARCHAR(30)     NOT NULL,
    note                NVARCHAR(MAX)       NULL,
    submitAttemptNumber INT             NOT NULL CONSTRAINT DF_PH_submitAttemptNumber DEFAULT 0,
    createdAt           DATETIME        NOT NULL CONSTRAINT DF_PH_createdAt DEFAULT GETDATE(),
    CONSTRAINT PK_ProposalHistory       PRIMARY KEY (id),
    CONSTRAINT FK_PH_Proposal           FOREIGN KEY (proposalId) REFERENCES Proposal(id),
    CONSTRAINT FK_PH_Actor              FOREIGN KEY (actorId) REFERENCES [User](id),
    CONSTRAINT CK_PH_actionType         CHECK (actionType IN (
        'CREATED','UPDATED','SUBMITTED','ASSIGNED_EDITOR','APPROVED','REJECTED','REVISE_REQUESTED','RESUBMITTED')),
    CONSTRAINT CK_PH_submitAttempt      CHECK (submitAttemptNumber BETWEEN 0 AND 2)
);
GO

-- ============================================================
--  MODULE 3: SERIES, CHAPTER & TASKS
-- ============================================================

CREATE TABLE Series (
    id                  BIGINT          NOT NULL IDENTITY(1,1),
    proposalId          BIGINT          NOT NULL,
    mangakaId           BIGINT          NOT NULL,
    tantouEditorId      BIGINT          NOT NULL,
    title               VARCHAR(255)    NOT NULL,
    genre               VARCHAR(100)    NOT NULL,
    status              VARCHAR(10)     NOT NULL CONSTRAINT DF_Series_status DEFAULT 'ACTIVE',
    publicationDate     DATE                NULL,
    createdAt           DATETIME        NOT NULL CONSTRAINT DF_Series_createdAt DEFAULT GETDATE(),
    CONSTRAINT PK_Series                PRIMARY KEY (id),
    CONSTRAINT UQ_Series_proposalId     UNIQUE (proposalId),          -- BR-18: atomic, one-to-one
    CONSTRAINT FK_Series_Proposal       FOREIGN KEY (proposalId)      REFERENCES Proposal(id),
    CONSTRAINT FK_Series_Mangaka        FOREIGN KEY (mangakaId)       REFERENCES [User](id),
    CONSTRAINT FK_Series_TantouEditor   FOREIGN KEY (tantouEditorId)  REFERENCES [User](id),
    CONSTRAINT CK_Series_status         CHECK (status IN ('ACTIVE','CANCELLED'))
);
GO

CREATE TABLE SeriesAssistant (
    seriesId    BIGINT      NOT NULL,
    assistantId BIGINT      NOT NULL,
    enrolledAt  DATETIME    NOT NULL CONSTRAINT DF_SA_enrolledAt DEFAULT GETDATE(),
    CONSTRAINT PK_SeriesAssistant       PRIMARY KEY (seriesId, assistantId),
    CONSTRAINT FK_SA_Series             FOREIGN KEY (seriesId)    REFERENCES Series(id),
    CONSTRAINT FK_SA_Assistant          FOREIGN KEY (assistantId) REFERENCES [User](id)
);
GO

CREATE TABLE Chapter (
    id                  BIGINT              NOT NULL IDENTITY(1,1),
    seriesId            BIGINT              NOT NULL,
    chapterNumber       INT                 NOT NULL,
    title               VARCHAR(255)        NOT NULL,
    status              VARCHAR(20)         NOT NULL CONSTRAINT DF_Chapter_status DEFAULT 'PLANNING',
    submissionDeadline  DATE                NOT NULL,   -- pub_date - 14 days (BR-22), enforced via trigger
    publicationDate     DATE                NOT NULL,
    completionPct       DECIMAL(5,2)        NOT NULL CONSTRAINT DF_Chapter_completionPct DEFAULT 0.00,
    atRisk              BIT                 NOT NULL CONSTRAINT DF_Chapter_atRisk DEFAULT 0,
    createdAt           DATETIME            NOT NULL CONSTRAINT DF_Chapter_createdAt DEFAULT GETDATE(),
    CONSTRAINT PK_Chapter               PRIMARY KEY (id),
    CONSTRAINT FK_Chapter_Series        FOREIGN KEY (seriesId) REFERENCES Series(id),
    CONSTRAINT CK_Chapter_status        CHECK (status IN (
        'PLANNING','IN_PROGRESS','COMPLETE','EDITORIAL_REVIEW','APPROVED','REJECTED')),
    CONSTRAINT CK_Chapter_completionPct CHECK (completionPct BETWEEN 0.00 AND 100.00)
);
GO

-- BR-22: submissionDeadline must be publicationDate - 14 days
CREATE TRIGGER TR_Chapter_SubmissionDeadline
ON Chapter
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE submissionDeadline <> DATEADD(DAY, -14, publicationDate)
    )
    BEGIN
        RAISERROR('BR-22: submissionDeadline must be publicationDate minus 14 days.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

CREATE TABLE PageTask (
    id              BIGINT          NOT NULL IDENTITY(1,1),
    chapterId       BIGINT          NOT NULL,
    assistantId     BIGINT          NOT NULL,
    pageRangeStart  INT             NOT NULL,
    pageRangeEnd    INT             NOT NULL,
    taskType        VARCHAR(100)    NOT NULL,
    dueDate         DATE            NOT NULL,
    status          VARCHAR(20)     NOT NULL CONSTRAINT DF_PageTask_status DEFAULT 'PENDING',
    rejectionCount  INT             NOT NULL CONSTRAINT DF_PageTask_rejectionCount DEFAULT 0,
    assignedAt      DATETIME        NOT NULL CONSTRAINT DF_PageTask_assignedAt DEFAULT GETDATE(),
    updatedAt       DATETIME        NOT NULL CONSTRAINT DF_PageTask_updatedAt DEFAULT GETDATE(),
    CONSTRAINT PK_PageTask              PRIMARY KEY (id),
    CONSTRAINT FK_PageTask_Chapter      FOREIGN KEY (chapterId)   REFERENCES Chapter(id),
    CONSTRAINT FK_PageTask_Assistant    FOREIGN KEY (assistantId) REFERENCES [User](id),
    CONSTRAINT CK_PageTask_pageRange    CHECK (pageRangeEnd >= pageRangeStart),
    CONSTRAINT CK_PageTask_status       CHECK (status IN (
        'PENDING','IN_PROGRESS','SUBMITTED','APPROVED','REJECTED','OVERDUE'))
);
GO

-- BR-34: dueDate must be <= chapter.submissionDeadline
CREATE TRIGGER TR_PageTask_DueDate
ON PageTask
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Chapter c ON c.id = i.chapterId
        WHERE i.dueDate > c.submissionDeadline
    )
    BEGIN
        RAISERROR('BR-34: PageTask dueDate must not exceed the chapter submissionDeadline.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- ============================================================
--  MODULE 4: MANUSCRIPT & ANNOTATION
-- ============================================================

CREATE TABLE Manuscript (
    id                  BIGINT          NOT NULL IDENTITY(1,1),
    chapterId           BIGINT          NOT NULL,
    version             INT             NOT NULL CONSTRAINT DF_Manuscript_version DEFAULT 1,
    status              VARCHAR(20)     NOT NULL CONSTRAINT DF_Manuscript_status DEFAULT 'SUBMITTED',
    submittedAt         DATETIME        NOT NULL CONSTRAINT DF_Manuscript_submittedAt DEFAULT GETDATE(),
    -- BR-48: reviewDeadline = submittedAt + 48h (computed)
    reviewDeadline      AS DATEADD(HOUR, 48, submittedAt) PERSISTED,
    fileUrl             VARCHAR(512)    NOT NULL,
    revisionDeadline    DATETIME            NULL,   -- rejectedAt + 3 days (BR-27), set by application
    CONSTRAINT PK_Manuscript            PRIMARY KEY (id),
    CONSTRAINT FK_Manuscript_Chapter    FOREIGN KEY (chapterId) REFERENCES Chapter(id),
    CONSTRAINT CK_Manuscript_status     CHECK (status IN (
        'SUBMITTED','UNDER_REVIEW','APPROVED','REJECTED','ARCHIVED')),
    CONSTRAINT CK_Manuscript_version    CHECK (version >= 1)
);
GO

CREATE TABLE Annotation (
    id              BIGINT      NOT NULL IDENTITY(1,1),
    manuscriptId    BIGINT      NOT NULL,
    editorId        BIGINT      NOT NULL,
    pageNumber      INT         NOT NULL,
    content         NVARCHAR(MAX)   NOT NULL,
    createdAt       DATETIME    NOT NULL CONSTRAINT DF_Annotation_createdAt DEFAULT GETDATE(),
    CONSTRAINT PK_Annotation            PRIMARY KEY (id),
    CONSTRAINT FK_Annotation_Manuscript FOREIGN KEY (manuscriptId) REFERENCES Manuscript(id),
    CONSTRAINT FK_Annotation_Editor     FOREIGN KEY (editorId)     REFERENCES [User](id),
    CONSTRAINT CK_Annotation_pageNumber CHECK (pageNumber >= 1)
);
GO

-- ============================================================
--  MODULE 5: RANKING
-- ============================================================

CREATE TABLE RankingPeriod (
    id              BIGINT          NOT NULL IDENTITY(1,1),
    name            VARCHAR(255)    NOT NULL,
    startDate       DATE            NOT NULL,
    endDate         DATE            NOT NULL,
    status          VARCHAR(15)     NOT NULL CONSTRAINT DF_RankingPeriod_status DEFAULT 'OPEN',
    calculatedAt    DATETIME            NULL,
    CONSTRAINT PK_RankingPeriod         PRIMARY KEY (id),
    CONSTRAINT CK_RankingPeriod_status  CHECK (status IN ('OPEN','CLOSED','CALCULATED')),
    CONSTRAINT CK_RankingPeriod_dates   CHECK (endDate > startDate)
);
GO

CREATE TABLE VoteEntry (
    id              BIGINT      NOT NULL IDENTITY(1,1),
    periodId        BIGINT      NOT NULL,
    seriesId        BIGINT      NOT NULL,
    boardMemberId   BIGINT      NOT NULL,
    voteCount       INT         NOT NULL,
    readerCount     INT         NOT NULL,
    submittedAt     DATETIME    NOT NULL CONSTRAINT DF_VoteEntry_submittedAt DEFAULT GETDATE(),
    CONSTRAINT PK_VoteEntry             PRIMARY KEY (id),
    CONSTRAINT FK_VE_Period             FOREIGN KEY (periodId)      REFERENCES RankingPeriod(id),
    CONSTRAINT FK_VE_Series             FOREIGN KEY (seriesId)      REFERENCES Series(id),
    CONSTRAINT FK_VE_BoardMember        FOREIGN KEY (boardMemberId) REFERENCES [User](id),
    CONSTRAINT CK_VE_voteCount          CHECK (voteCount  >= 0),    -- BR-57
    CONSTRAINT CK_VE_readerCount        CHECK (readerCount > 0)     -- BR-58
);
GO

CREATE TABLE RankingRecord (
    id              BIGINT          NOT NULL IDENTITY(1,1),
    periodId        BIGINT          NOT NULL,
    seriesId        BIGINT          NOT NULL,
    -- BR-54: rankScore = (voteCount / readerCount) * 100
    rankScore       DECIMAL(6,2)    NOT NULL,
    rankPosition    INT             NOT NULL,
    isBottomTwenty  BIT             NOT NULL CONSTRAINT DF_RankingRecord_isBottomTwenty DEFAULT 0,
    calculatedAt    DATETIME        NOT NULL CONSTRAINT DF_RankingRecord_calculatedAt DEFAULT GETDATE(),
    CONSTRAINT PK_RankingRecord         PRIMARY KEY (id),
    CONSTRAINT FK_RR_Period             FOREIGN KEY (periodId)  REFERENCES RankingPeriod(id),
    CONSTRAINT FK_RR_Series             FOREIGN KEY (seriesId)  REFERENCES Series(id),
    CONSTRAINT CK_RR_rankScore          CHECK (rankScore >= 0),
    CONSTRAINT CK_RR_rankPosition       CHECK (rankPosition >= 1)
);
GO

-- ============================================================
--  MODULE 6: DECISION SESSION
-- ============================================================

CREATE TABLE DecisionSession (
    id                  BIGINT      NOT NULL IDENTITY(1,1),
    seriesId            BIGINT      NOT NULL,
    rankingRecordId     BIGINT      NOT NULL,
    status              VARCHAR(10) NOT NULL CONSTRAINT DF_DecisionSession_status DEFAULT 'OPEN',
    result              VARCHAR(15)     NULL,
    openedAt            DATETIME    NOT NULL CONSTRAINT DF_DecisionSession_openedAt DEFAULT GETDATE(),
    closedAt            DATETIME        NULL,
    CONSTRAINT PK_DecisionSession           PRIMARY KEY (id),
    CONSTRAINT FK_DS_Series                 FOREIGN KEY (seriesId)       REFERENCES Series(id),
    CONSTRAINT FK_DS_RankingRecord          FOREIGN KEY (rankingRecordId) REFERENCES RankingRecord(id),
    CONSTRAINT CK_DS_status                 CHECK (status IN ('OPEN','CLOSED','DEFERRED')),
    CONSTRAINT CK_DS_result                 CHECK (result IS NULL OR result IN (
        'CONTINUE','CANCEL','CHANGE_TYPE','DEFERRED'))
);
GO

CREATE TABLE DecisionVote (
    id              BIGINT          NOT NULL IDENTITY(1,1),
    sessionId       BIGINT          NOT NULL,
    voterId         BIGINT          NOT NULL,
    decision        VARCHAR(15)     NOT NULL,
    justification   NVARCHAR(MAX)       NULL,   -- NOT NULL when decision = CANCEL (BR-72), enforced via trigger
    votedAt         DATETIME        NOT NULL CONSTRAINT DF_DecisionVote_votedAt DEFAULT GETDATE(),
    CONSTRAINT PK_DecisionVote          PRIMARY KEY (id),
    CONSTRAINT FK_DV_Session            FOREIGN KEY (sessionId) REFERENCES DecisionSession(id),
    CONSTRAINT FK_DV_Voter              FOREIGN KEY (voterId)   REFERENCES [User](id),
    CONSTRAINT CK_DV_decision           CHECK (decision IN ('CONTINUE','CANCEL','CHANGE_TYPE'))
);
GO

-- BR-72: justification required when decision = CANCEL
CREATE TRIGGER TR_DecisionVote_CancelJustification
ON DecisionVote
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE decision = 'CANCEL' AND (justification IS NULL OR LTRIM(RTRIM(justification)) = '')
    )
    BEGIN
        RAISERROR('BR-72: Justification is required when decision is CANCEL.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- ============================================================
--  MODULE 7: NOTIFICATION & AUDIT
-- ============================================================

CREATE TABLE Notification (
    id              BIGINT          NOT NULL IDENTITY(1,1),
    userId          BIGINT          NOT NULL,
    type            VARCHAR(50)     NOT NULL,
    message         NVARCHAR(MAX)   NOT NULL,
    referenceId     BIGINT              NULL,
    referenceType   VARCHAR(50)         NULL,
    isRead          BIT             NOT NULL CONSTRAINT DF_Notification_isRead DEFAULT 0,
    createdAt       DATETIME        NOT NULL CONSTRAINT DF_Notification_createdAt DEFAULT GETDATE(),
    CONSTRAINT PK_Notification          PRIMARY KEY (id),
    CONSTRAINT FK_Notification_User     FOREIGN KEY (userId) REFERENCES [User](id),
    CONSTRAINT CK_Notification_refType  CHECK (referenceType IS NULL OR referenceType IN (
        'PROPOSAL','CHAPTER','TASK','MANUSCRIPT','DECISION'))
);
GO

CREATE TABLE AuditLog (
    id              BIGINT          NOT NULL IDENTITY(1,1),
    actorId         BIGINT              NULL,   -- NULL = system action
    action          VARCHAR(255)    NOT NULL,
    entityType      VARCHAR(100)    NOT NULL,
    entityId        BIGINT          NOT NULL,
    detail          NVARCHAR(MAX)       NULL,   -- JSON stored as NVARCHAR (BR-73)
    performedAt     DATETIME        NOT NULL CONSTRAINT DF_AuditLog_performedAt DEFAULT GETDATE(),
    CONSTRAINT PK_AuditLog              PRIMARY KEY (id),
    CONSTRAINT FK_AuditLog_Actor        FOREIGN KEY (actorId) REFERENCES [User](id),
    CONSTRAINT CK_AuditLog_entityType   CHECK (entityType IN (
        'PROPOSAL','CHAPTER','TASK','MANUSCRIPT','DECISION','USER'))
);
GO

-- ============================================================
--  INDEXES (performance)
-- ============================================================

CREATE INDEX IX_Proposal_mangakaId        ON Proposal         (mangakaId);
CREATE INDEX IX_Proposal_status           ON Proposal         (status);
CREATE INDEX IX_Proposal_assignedEditor   ON Proposal         (assignedEditorId);
CREATE INDEX IX_ProposalHistory_proposal  ON ProposalHistory  (proposalId, createdAt);
CREATE INDEX IX_Series_mangakaId          ON Series           (mangakaId);
CREATE INDEX IX_Chapter_seriesId          ON Chapter          (seriesId);
CREATE INDEX IX_Chapter_status            ON Chapter          (status);
CREATE INDEX IX_PageTask_chapterId        ON PageTask         (chapterId);
CREATE INDEX IX_PageTask_assistantId      ON PageTask         (assistantId);
CREATE INDEX IX_Manuscript_chapterId      ON Manuscript       (chapterId);
CREATE INDEX IX_Annotation_manuscriptId   ON Annotation       (manuscriptId);
CREATE INDEX IX_VoteEntry_periodId        ON VoteEntry        (periodId);
CREATE INDEX IX_RankingRecord_periodId    ON RankingRecord    (periodId);
CREATE INDEX IX_RankingRecord_seriesId    ON RankingRecord    (seriesId);
CREATE INDEX IX_DecisionSession_seriesId  ON DecisionSession  (seriesId);
CREATE INDEX IX_Notification_userId       ON Notification     (userId);
CREATE INDEX IX_Notification_isRead       ON Notification     (userId, isRead);
CREATE INDEX IX_AuditLog_entityType_Id    ON AuditLog         (entityType, entityId);
CREATE INDEX IX_AuditLog_actorId          ON AuditLog         (actorId);
GO

PRINT 'Schema created successfully.';
GO
