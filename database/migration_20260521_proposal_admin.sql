USE MangaEditorialDB;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
SET XACT_ABORT ON;
GO

BEGIN TRAN;

-- Keep the original seeded admin as the single ADMIN account.
DELETE FROM UserRole
WHERE roleId = 1
  AND userId <> (SELECT MIN(userId) FROM UserRole WHERE roleId = 1);

IF COL_LENGTH('Proposal', 'sampleFilePath') IS NULL
    EXEC('ALTER TABLE Proposal ADD sampleFilePath VARCHAR(512) NOT NULL CONSTRAINT DF_Proposal_sampleFilePath DEFAULT ('''')');

IF COL_LENGTH('Proposal', 'originalFileName') IS NULL
    EXEC('ALTER TABLE Proposal ADD originalFileName NVARCHAR(255) NOT NULL CONSTRAINT DF_Proposal_originalFileName DEFAULT ('''')');

IF COL_LENGTH('Proposal', 'approximateChapter') IS NULL
    EXEC('ALTER TABLE Proposal ADD approximateChapter INT NOT NULL CONSTRAINT DF_Proposal_approximateChapter DEFAULT (1)');

IF COL_LENGTH('Proposal', 'submitAttemptCount') IS NULL
    EXEC('ALTER TABLE Proposal ADD submitAttemptCount INT NOT NULL CONSTRAINT DF_Proposal_submitAttemptCount DEFAULT (0)');

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Proposal_status')
    ALTER TABLE Proposal DROP CONSTRAINT CK_Proposal_status;

EXEC('UPDATE Proposal SET status = ''UNDER_REVIEW'' WHERE status IN (''SUBMITTED'', ''VOTING'')');
EXEC('UPDATE Proposal SET status = ''REVISION_REQUESTED'' WHERE status = ''DEFERRED''');

ALTER TABLE Proposal ADD CONSTRAINT CK_Proposal_status
CHECK (status IN ('DRAFT', 'UNDER_REVIEW', 'REVISION_REQUESTED', 'APPROVED', 'REJECTED'));

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Proposal_approxChapter')
    EXEC('ALTER TABLE Proposal ADD CONSTRAINT CK_Proposal_approxChapter CHECK (approximateChapter >= 1)');

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Proposal_submitAttempts')
    EXEC('ALTER TABLE Proposal ADD CONSTRAINT CK_Proposal_submitAttempts CHECK (submitAttemptCount BETWEEN 0 AND 2)');

IF OBJECT_ID('ProposalHistory', 'U') IS NULL
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
            'CREATED', 'UPDATED', 'SUBMITTED', 'ASSIGNED_EDITOR', 'APPROVED', 'REJECTED', 'REVISE_REQUESTED', 'RESUBMITTED')),
        CONSTRAINT CK_PH_submitAttempt      CHECK (submitAttemptNumber BETWEEN 0 AND 2)
    );

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_UserRole_single_admin' AND object_id = OBJECT_ID('UserRole'))
    CREATE UNIQUE INDEX UX_UserRole_single_admin ON UserRole(roleId) WHERE roleId = 1;

COMMIT;
GO
