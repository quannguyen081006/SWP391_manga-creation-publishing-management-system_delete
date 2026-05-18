-- ============================================================
--  MANGA EDITORIAL SYSTEM — SEED DATA
--  Run AFTER schema.sql
--  Passwords are stored as plain-text for dev/testing only.
--  All users have password: 12345
-- ============================================================

USE MangaEditorialDB;
GO

-- ============================================================
--  ROLES
-- ============================================================
INSERT INTO [Role] (id, name) VALUES
    (1, 'ADMIN'),
    (2, 'MANGAKA'),
    (3, 'ASSISTANT'),
    (4, 'TANTOU_EDITOR'),
    (5, 'EDITORIAL_BOARD');
GO

-- ============================================================
--  USERS  (passwordHash stored as plain text - dev only)
-- ============================================================
INSERT INTO [User] (username, passwordHash, fullName, email, status) VALUES
    ('admin',       '12345', 'System Admin',        'admin@mangaflow.local',   'ACTIVE'),  -- id 1
    ('mangaka1',    '12345', 'Yuki Tanaka',          'mangaka1@mangaflow.local','ACTIVE'),  -- id 2
    ('assistant1',  '12345', 'Aiko Mori',            'asst1@mangaflow.local',   'ACTIVE'),  -- id 3
    ('assistant2',  '12345', 'Riku Hayashi',         'asst2@mangaflow.local',   'ACTIVE'),  -- id 4
    ('tantou1',     '12345', 'Hiroshi Yamamoto',     'tantou1@mangaflow.local', 'ACTIVE'),  -- id 5
    ('board1',      '12345', 'Board Member Keiko',   'board1@mangaflow.local',  'ACTIVE'),  -- id 6
    ('board2',      '12345', 'Board Member Sato',    'board2@mangaflow.local',  'ACTIVE'),  -- id 7
    ('board3',      '12345', 'Board Member Natsuki', 'board3@mangaflow.local',  'ACTIVE');  -- id 8
GO

-- ============================================================
--  USER ROLES
-- ============================================================
INSERT INTO UserRole (userId, roleId) VALUES
    (1, 1),  -- admin        → ADMIN
    (2, 2),  -- mangaka1     → MANGAKA
    (3, 3),  -- assistant1   → ASSISTANT
    (4, 3),  -- assistant2   → ASSISTANT
    (5, 4),  -- tantou1      → TANTOU_EDITOR
    (6, 5),  -- board1       → EDITORIAL_BOARD
    (7, 5),  -- board2       → EDITORIAL_BOARD
    (8, 5);  -- board3       → EDITORIAL_BOARD
GO

-- ============================================================
--  PROPOSAL  (APPROVED — will lead to a Series)
-- ============================================================
INSERT INTO Proposal
    (mangakaId, title, genre, synopsis, status, submittedAt, assignedEditorId, createdAt, updatedAt)
VALUES
    (2,
     'Shadows of Edo',
     'Historical Action',
     'A disgraced samurai seeks redemption in Edo-period Japan, uncovering a conspiracy threatening the Shogunate.',
     'APPROVED',
     DATEADD(DAY, -20, GETDATE()),
     5,
     DATEADD(DAY, -25, GETDATE()),
     DATEADD(DAY, -20, GETDATE())
    );
GO
-- proposal id = 1

-- A second proposal in VOTING state for board testing
INSERT INTO Proposal
    (mangakaId, title, genre, synopsis, status, submittedAt, assignedEditorId, createdAt, updatedAt)
VALUES
    (2,
     'Cyber Ronin',
     'Sci-Fi Action',
     'In 2157, a cybernetic warrior hunts rogue AIs across neon-lit megacities.',
     'VOTING',
     DATEADD(DAY, -3, GETDATE()),
     NULL,
     DATEADD(DAY, -5, GETDATE()),
     DATEADD(DAY, -3, GETDATE())
    );
GO
-- proposal id = 2

-- ============================================================
--  PROPOSAL VOTES  (on proposal 2 — VOTING state)
-- ============================================================
INSERT INTO ProposalVote (proposalId, voterId, voteType, reason)
VALUES
    (2, 6, 'APPROVE', NULL),
    (2, 7, 'APPROVE', NULL);
-- board3 (id=8) has not voted yet — ready for testing
GO

-- ============================================================
--  SERIES  (auto-created from approved proposal 1)
-- ============================================================
INSERT INTO Series
    (proposalId, mangakaId, tantouEditorId, title, genre, status, publicationDate, createdAt)
VALUES
    (1, 2, 5,
     'Shadows of Edo',
     'Historical Action',
     'ACTIVE',
     DATEADD(DAY, 60, GETDATE()),
     GETDATE());
GO
-- series id = 1

-- ============================================================
--  SERIES ASSISTANTS
-- ============================================================
INSERT INTO SeriesAssistant (seriesId, assistantId)
VALUES
    (1, 3),  -- assistant1 enrolled in series 1
    (1, 4);  -- assistant2 enrolled in series 1
GO

-- ============================================================
--  CHAPTERS
--  submissionDeadline = publicationDate - 14 days  (BR-22)
-- ============================================================
DECLARE @pub1 DATE = DATEADD(DAY, 60, GETDATE());
DECLARE @pub2 DATE = DATEADD(DAY, 90, GETDATE());

INSERT INTO Chapter
    (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES
    (1, 1, 'The Broken Blade',
     'IN_PROGRESS',
     DATEADD(DAY, -14, @pub1), @pub1,
     45.00, 0),
    (1, 2, 'River of Shadows',
     'PLANNING',
     DATEADD(DAY, -14, @pub2), @pub2,
     0.00, 0);
GO
-- chapter ids: 1, 2

-- ============================================================
--  PAGE TASKS  (chapter 1, IN_PROGRESS)
-- ============================================================
INSERT INTO PageTask
    (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
VALUES
    (1, 3, 1,  10, 'SKETCHING', DATEADD(DAY, 30, GETDATE()), 'IN_PROGRESS', 0),
    (1, 4, 11, 20, 'INKING',    DATEADD(DAY, 35, GETDATE()), 'PENDING',     0),
    (1, 3, 21, 30, 'COLORING',  DATEADD(DAY, 40, GETDATE()), 'PENDING',     0);
GO

-- ============================================================
--  MANUSCRIPT  (chapter 1, version 1)
-- ============================================================
INSERT INTO Manuscript
    (chapterId, version, status, fileUrl)
VALUES
    (1, 1, 'UNDER_REVIEW', '/uploads/manuscripts/shadows-edo-ch1-v1.pdf');
GO
-- manuscript id = 1

-- ============================================================
--  ANNOTATION  (tantou editor annotated page 3)
-- ============================================================
INSERT INTO Annotation
    (manuscriptId, editorId, pageNumber, content)
VALUES
    (1, 5, 3, 'The sword perspective needs correction — blade appears too short at this angle.');
GO

-- ============================================================
--  RANKING PERIOD  (OPEN — ready for vote entry)
-- ============================================================
INSERT INTO RankingPeriod
    (name, startDate, endDate, status)
VALUES
    ('Q2 2026',
     DATEADD(DAY, -30, GETDATE()),
     DATEADD(DAY,  30, GETDATE()),
     'OPEN');
GO
-- ranking_period id = 1

-- ============================================================
--  NOTIFICATIONS  (sample)
-- ============================================================
INSERT INTO Notification
    (userId, type, message, referenceId, referenceType, isRead)
VALUES
    (2,  'PROPOSAL_RESOLVED',      'Your proposal "Shadows of Edo" was APPROVED!',            1, 'PROPOSAL', 0),
    (5,  'MANUSCRIPT_SUBMITTED',   'New manuscript submitted for Chapter 1 of Shadows of Edo.',1,'MANUSCRIPT', 0),
    (6,  'VOTING_OPENED',          'Proposal "Cyber Ronin" is now open for voting.',           2, 'PROPOSAL', 0),
    (7,  'VOTING_OPENED',          'Proposal "Cyber Ronin" is now open for voting.',           2, 'PROPOSAL', 0),
    (8,  'VOTING_OPENED',          'Proposal "Cyber Ronin" is now open for voting.',           2, 'PROPOSAL', 0),
    (3,  'TASK_DUE_REMINDER',      'Your sketching task for Chapter 1 is due in 30 days.',    1, 'TASK',     0);
GO

-- ============================================================
--  AUDIT LOG  (sample entries)
-- ============================================================
INSERT INTO AuditLog (actorId, action, entityType, entityId, detail)
VALUES
    (2, 'PROPOSAL_SUBMITTED', 'PROPOSAL', 1, '{"status":"SUBMITTED"}'),
    (1, 'PROPOSAL_APPROVED',  'PROPOSAL', 1, '{"status":"APPROVED"}'),
    (2, 'SERIES_CREATED',     'PROPOSAL', 1, '{"seriesId":1}'),
    (2, 'MANUSCRIPT_SUBMITTED','MANUSCRIPT',1,'{"version":1,"chapterId":1}'),
    (5, 'MANUSCRIPT_REVIEW_STARTED','MANUSCRIPT',1,'{"status":"UNDER_REVIEW"}');
GO

PRINT 'Seed data inserted successfully.';
PRINT '';
PRINT 'Test accounts (all passwords: 12345):';
PRINT '  admin     — ADMIN';
PRINT '  mangaka1  — MANGAKA';
PRINT '  assistant1 / assistant2 — ASSISTANT';
PRINT '  tantou1   — TANTOU_EDITOR';
PRINT '  board1 / board2 / board3 — EDITORIAL_BOARD';
GO
