-- ============================================================
--  MANGA EDITORIAL SYSTEM - EXTENDED TEST DATA
--  Run AFTER:
--    1) schema.sql
--    2) seed.sql
--
--  Adds more mangaka, assistants, proposals, series, chapters,
--  page tasks, images, manuscripts, annotations, rankings,
--  decision votes, notifications and audit logs.
--
--  All added users have password: 12345
-- ============================================================

USE MangaEditorialDB;
GO

SET NOCOUNT ON;

-- ------------------------------------------------------------
--  Prerequisite check
-- ------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [Role] WHERE id = 2 AND name = 'MANGAKA')
   OR NOT EXISTS (SELECT 1 FROM [Role] WHERE id = 3 AND name = 'ASSISTANT')
   OR NOT EXISTS (SELECT 1 FROM [Role] WHERE id = 4 AND name = 'TANTOU_EDITOR')
   OR NOT EXISTS (SELECT 1 FROM [Role] WHERE id = 5 AND name = 'EDITORIAL_BOARD')
   OR (SELECT COUNT(DISTINCT username) FROM [User] WHERE username IN ('mangaka1', 'assistant1', 'tantou1', 'board1')) < 4
BEGIN
    THROW 51000, 'Please run schema.sql and seed.sql before importing extended_test_data.sql.', 1;
END;

-- ------------------------------------------------------------
--  Extra users
-- ------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [User] WHERE username = 'mangaka2')
    INSERT INTO [User] (username, passwordHash, fullName, email, status)
    VALUES ('mangaka2', '12345', 'Mai Nguyen', 'mangaka2@mangaflow.local', 'ACTIVE');

IF NOT EXISTS (SELECT 1 FROM [User] WHERE username = 'mangaka3')
    INSERT INTO [User] (username, passwordHash, fullName, email, status)
    VALUES ('mangaka3', '12345', 'Kenji Ito', 'mangaka3@mangaflow.local', 'ACTIVE');

IF NOT EXISTS (SELECT 1 FROM [User] WHERE username = 'assistant3')
    INSERT INTO [User] (username, passwordHash, fullName, email, status)
    VALUES ('assistant3', '12345', 'Linh Tran', 'asst3@mangaflow.local', 'ACTIVE');

IF NOT EXISTS (SELECT 1 FROM [User] WHERE username = 'assistant4')
    INSERT INTO [User] (username, passwordHash, fullName, email, status)
    VALUES ('assistant4', '12345', 'Minh Pham', 'asst4@mangaflow.local', 'ACTIVE');

IF NOT EXISTS (SELECT 1 FROM [User] WHERE username = 'assistant5')
    INSERT INTO [User] (username, passwordHash, fullName, email, status)
    VALUES ('assistant5', '12345', 'Nora Kim', 'asst5@mangaflow.local', 'ACTIVE');

IF NOT EXISTS (SELECT 1 FROM [User] WHERE username = 'tantou2')
    INSERT INTO [User] (username, passwordHash, fullName, email, status)
    VALUES ('tantou2', '12345', 'Aya Suzuki', 'tantou2@mangaflow.local', 'ACTIVE');

INSERT INTO UserRole (userId, roleId)
SELECT u.id, v.roleId
FROM (
    VALUES
        ('mangaka2', 2),
        ('mangaka3', 2),
        ('assistant3', 3),
        ('assistant4', 3),
        ('assistant5', 3),
        ('tantou2', 4)
) AS v(username, roleId)
JOIN [User] u ON u.username = v.username
WHERE NOT EXISTS (
    SELECT 1
    FROM UserRole ur
    WHERE ur.userId = u.id
      AND ur.roleId = v.roleId
);

-- ------------------------------------------------------------
--  Shared IDs
-- ------------------------------------------------------------
DECLARE
    @mangaka1 BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka1'),
    @mangaka2 BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka2'),
    @mangaka3 BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka3'),
    @assistant1 BIGINT = (SELECT id FROM [User] WHERE username = 'assistant1'),
    @assistant3 BIGINT = (SELECT id FROM [User] WHERE username = 'assistant3'),
    @assistant4 BIGINT = (SELECT id FROM [User] WHERE username = 'assistant4'),
    @assistant5 BIGINT = (SELECT id FROM [User] WHERE username = 'assistant5'),
    @tantou1 BIGINT = (SELECT id FROM [User] WHERE username = 'tantou1'),
    @tantou2 BIGINT = (SELECT id FROM [User] WHERE username = 'tantou2'),
    @board1 BIGINT = (SELECT id FROM [User] WHERE username = 'board1'),
    @board2 BIGINT = (SELECT id FROM [User] WHERE username = 'board2'),
    @board3 BIGINT = (SELECT id FROM [User] WHERE username = 'board3'),
    @proposalKitchen BIGINT,
    @proposalLotus BIGINT,
    @proposalBakery BIGINT,
    @seriesEdo BIGINT = (SELECT TOP 1 id FROM Series WHERE title = 'Shadows of Edo' ORDER BY id),
    @seriesKitchen BIGINT,
    @seriesLotus BIGINT,
    @chapterKitchen1 BIGINT,
    @chapterKitchen2 BIGINT,
    @chapterKitchen3 BIGINT,
    @chapterLotus1 BIGINT,
    @chapterLotus2 BIGINT,
    @taskKitchen1 BIGINT,
    @taskKitchen2 BIGINT,
    @taskKitchen3 BIGINT,
    @taskLotus1 BIGINT,
    @taskLotus2 BIGINT,
    @taskLotus3 BIGINT,
    @manuscriptKitchen1 BIGINT,
    @manuscriptKitchen2 BIGINT,
    @manuscriptLotus1 BIGINT,
    @periodId BIGINT = (SELECT TOP 1 id FROM RankingPeriod WHERE name = 'Q2 2026' ORDER BY id),
    @rankKitchen BIGINT,
    @rankLotus BIGINT,
    @lotusDecisionSession BIGINT,
    @pubKitchen1 DATE = DATEADD(DAY, 45, GETDATE()),
    @pubKitchen2 DATE = DATEADD(DAY, 75, GETDATE()),
    @pubKitchen3 DATE = DATEADD(DAY, 105, GETDATE()),
    @pubLotus1 DATE = DATEADD(DAY, 50, GETDATE()),
    @pubLotus2 DATE = DATEADD(DAY, 80, GETDATE());

-- ------------------------------------------------------------
--  Proposals
-- ------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Proposal WHERE title = 'Celestial Kitchen' AND mangakaId = @mangaka2)
BEGIN
    INSERT INTO Proposal
        (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
    VALUES
        (@mangaka2,
         'Celestial Kitchen',
         'Fantasy',
         'A young cook serves spirits in a floating night market and learns the price of forgotten recipes.',
         '/uploads/proposals/sample-celestial-kitchen.pdf',
         'sample-celestial-kitchen.pdf',
         12,
         'APPROVED',
         DATEADD(DAY, -18, GETDATE()),
         @tantou2,
         1,
         DATEADD(DAY, -22, GETDATE()),
         DATEADD(DAY, -16, GETDATE()));
END;
SET @proposalKitchen = (SELECT id FROM Proposal WHERE title = 'Celestial Kitchen' AND mangakaId = @mangaka2);

IF NOT EXISTS (SELECT 1 FROM Proposal WHERE title = 'Neon Lotus High' AND mangakaId = @mangaka3)
BEGIN
    INSERT INTO Proposal
        (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
    VALUES
        (@mangaka3,
         'Neon Lotus High',
         'Drama',
         'Students at an elite cyber-art academy battle through murals, music and augmented dreams.',
         '/uploads/proposals/sample-neon-lotus-high.pdf',
         'sample-neon-lotus-high.pdf',
         18,
         'APPROVED',
         DATEADD(DAY, -14, GETDATE()),
         @tantou1,
         2,
         DATEADD(DAY, -25, GETDATE()),
         DATEADD(DAY, -10, GETDATE()));
END;
SET @proposalLotus = (SELECT id FROM Proposal WHERE title = 'Neon Lotus High' AND mangakaId = @mangaka3);

IF NOT EXISTS (SELECT 1 FROM Proposal WHERE title = 'Rainfall Bakery' AND mangakaId = @mangaka2)
BEGIN
    INSERT INTO Proposal
        (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
    VALUES
        (@mangaka2,
         'Rainfall Bakery',
         'Slice of Life',
         'A quiet bakery becomes the meeting point for neighbors trying to rebuild after a long monsoon.',
         '/uploads/proposals/sample-rainfall-bakery.pdf',
         'sample-rainfall-bakery.pdf',
         8,
         'REVISION_REQUESTED',
         DATEADD(DAY, -6, GETDATE()),
         @tantou2,
         1,
         DATEADD(DAY, -8, GETDATE()),
         DATEADD(DAY, -2, GETDATE()));
END;
SET @proposalBakery = (SELECT id FROM Proposal WHERE title = 'Rainfall Bakery' AND mangakaId = @mangaka2);

INSERT INTO ProposalHistory
    (proposalId, actorId, actorRole, actionType, note, submitAttemptNumber, createdAt)
SELECT proposalId, actorId, actorRole, actionType, note, submitAttemptNumber, createdAt
FROM (
    VALUES
        (@proposalKitchen, @mangaka2, 'MANGAKA', 'CREATED', 'Extended seed proposal created.', 0, DATEADD(DAY, -22, GETDATE())),
        (@proposalKitchen, @mangaka2, 'MANGAKA', 'SUBMITTED', 'Submitted with menu-board character samples.', 1, DATEADD(DAY, -18, GETDATE())),
        (@proposalKitchen, NULL, 'SYSTEM', 'ASSIGNED_EDITOR', 'Assigned to Tantou Editor tantou2.', 1, DATEADD(DAY, -18, GETDATE())),
        (@proposalKitchen, @tantou2, 'TANTOU_EDITOR', 'APPROVED', 'Approved for short pilot serialization.', 1, DATEADD(DAY, -16, GETDATE())),
        (@proposalLotus, @mangaka3, 'MANGAKA', 'CREATED', 'Extended seed proposal created.', 0, DATEADD(DAY, -25, GETDATE())),
        (@proposalLotus, @mangaka3, 'MANGAKA', 'SUBMITTED', 'Resubmitted after tone revision.', 2, DATEADD(DAY, -14, GETDATE())),
        (@proposalLotus, @tantou1, 'TANTOU_EDITOR', 'APPROVED', 'Approved after second attempt.', 2, DATEADD(DAY, -10, GETDATE())),
        (@proposalBakery, @mangaka2, 'MANGAKA', 'CREATED', 'Extended seed proposal created.', 0, DATEADD(DAY, -8, GETDATE())),
        (@proposalBakery, @mangaka2, 'MANGAKA', 'SUBMITTED', 'Submitted cozy drama concept.', 1, DATEADD(DAY, -6, GETDATE())),
        (@proposalBakery, @tantou2, 'TANTOU_EDITOR', 'REVISE_REQUESTED', 'Please sharpen the main conflict in chapter one.', 1, DATEADD(DAY, -2, GETDATE()))
) AS h(proposalId, actorId, actorRole, actionType, note, submitAttemptNumber, createdAt)
WHERE NOT EXISTS (
    SELECT 1
    FROM ProposalHistory ph
    WHERE ph.proposalId = h.proposalId
      AND ph.actionType = h.actionType
      AND ISNULL(ph.note, '') = ISNULL(h.note, '')
);

-- ------------------------------------------------------------
--  Series and assistants
-- ------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Series WHERE proposalId = @proposalKitchen)
BEGIN
    INSERT INTO Series
        (proposalId, mangakaId, tantouEditorId, title, genre, status, publicationDate, createdAt)
    VALUES
        (@proposalKitchen, @mangaka2, @tantou2, 'Celestial Kitchen', 'Fantasy', 'ACTIVE', @pubKitchen1, DATEADD(DAY, -15, GETDATE()));
END;
SET @seriesKitchen = (SELECT id FROM Series WHERE proposalId = @proposalKitchen);

IF NOT EXISTS (SELECT 1 FROM Series WHERE proposalId = @proposalLotus)
BEGIN
    INSERT INTO Series
        (proposalId, mangakaId, tantouEditorId, title, genre, status, publicationDate, createdAt)
    VALUES
        (@proposalLotus, @mangaka3, @tantou1, 'Neon Lotus High', 'Drama', 'ACTIVE', @pubLotus1, DATEADD(DAY, -9, GETDATE()));
END;
SET @seriesLotus = (SELECT id FROM Series WHERE proposalId = @proposalLotus);

INSERT INTO SeriesAssistant (seriesId, assistantId, enrolledAt)
SELECT seriesId, assistantId, enrolledAt
FROM (
    VALUES
        (@seriesKitchen, @assistant3, DATEADD(DAY, -14, GETDATE())),
        (@seriesKitchen, @assistant4, DATEADD(DAY, -14, GETDATE())),
        (@seriesKitchen, @assistant5, DATEADD(DAY, -7, GETDATE())),
        (@seriesLotus, @assistant1, DATEADD(DAY, -8, GETDATE())),
        (@seriesLotus, @assistant4, DATEADD(DAY, -8, GETDATE())),
        (@seriesLotus, @assistant5, DATEADD(DAY, -6, GETDATE()))
) AS sa(seriesId, assistantId, enrolledAt)
WHERE NOT EXISTS (
    SELECT 1
    FROM SeriesAssistant existing
    WHERE existing.seriesId = sa.seriesId
      AND existing.assistantId = sa.assistantId
);

-- ------------------------------------------------------------
--  Chapters
-- ------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Chapter WHERE seriesId = @seriesKitchen AND chapterNumber = 1)
    INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
    VALUES (@seriesKitchen, 1, 'Soup for the Moon Rabbit', 'EDITORIAL_REVIEW', DATEADD(DAY, -14, @pubKitchen1), @pubKitchen1, 100.00, 0);
SET @chapterKitchen1 = (SELECT id FROM Chapter WHERE seriesId = @seriesKitchen AND chapterNumber = 1);

IF NOT EXISTS (SELECT 1 FROM Chapter WHERE seriesId = @seriesKitchen AND chapterNumber = 2)
    INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
    VALUES (@seriesKitchen, 2, 'The Spice Map', 'IN_PROGRESS', DATEADD(DAY, -14, @pubKitchen2), @pubKitchen2, 62.50, 0);
SET @chapterKitchen2 = (SELECT id FROM Chapter WHERE seriesId = @seriesKitchen AND chapterNumber = 2);

IF NOT EXISTS (SELECT 1 FROM Chapter WHERE seriesId = @seriesKitchen AND chapterNumber = 3)
    INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
    VALUES (@seriesKitchen, 3, 'A Table for Ghosts', 'PLANNING', DATEADD(DAY, -14, @pubKitchen3), @pubKitchen3, 10.00, 0);
SET @chapterKitchen3 = (SELECT id FROM Chapter WHERE seriesId = @seriesKitchen AND chapterNumber = 3);

IF NOT EXISTS (SELECT 1 FROM Chapter WHERE seriesId = @seriesLotus AND chapterNumber = 1)
    INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
    VALUES (@seriesLotus, 1, 'First Bell in Neon Rain', 'REJECTED', DATEADD(DAY, -14, @pubLotus1), @pubLotus1, 100.00, 1);
SET @chapterLotus1 = (SELECT id FROM Chapter WHERE seriesId = @seriesLotus AND chapterNumber = 1);

IF NOT EXISTS (SELECT 1 FROM Chapter WHERE seriesId = @seriesLotus AND chapterNumber = 2)
    INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
    VALUES (@seriesLotus, 2, 'Graffiti Exam', 'IN_PROGRESS', DATEADD(DAY, -14, @pubLotus2), @pubLotus2, 35.00, 1);
SET @chapterLotus2 = (SELECT id FROM Chapter WHERE seriesId = @seriesLotus AND chapterNumber = 2);

-- ------------------------------------------------------------
--  Page tasks
-- ------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM PageTask WHERE chapterId = @chapterKitchen1 AND assistantId = @assistant3 AND pageRangeStart = 1 AND pageRangeEnd = 8 AND taskType = 'BACKGROUND')
    INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
    VALUES (@chapterKitchen1, @assistant3, 1, 8, 'BACKGROUND', DATEADD(DAY, 25, GETDATE()), 'APPROVED', 0);
SET @taskKitchen1 = (SELECT id FROM PageTask WHERE chapterId = @chapterKitchen1 AND assistantId = @assistant3 AND pageRangeStart = 1 AND pageRangeEnd = 8 AND taskType = 'BACKGROUND');

IF NOT EXISTS (SELECT 1 FROM PageTask WHERE chapterId = @chapterKitchen1 AND assistantId = @assistant4 AND pageRangeStart = 9 AND pageRangeEnd = 16 AND taskType = 'TONING')
    INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
    VALUES (@chapterKitchen1, @assistant4, 9, 16, 'TONING', DATEADD(DAY, 26, GETDATE()), 'SUBMITTED', 0);
SET @taskKitchen2 = (SELECT id FROM PageTask WHERE chapterId = @chapterKitchen1 AND assistantId = @assistant4 AND pageRangeStart = 9 AND pageRangeEnd = 16 AND taskType = 'TONING');

IF NOT EXISTS (SELECT 1 FROM PageTask WHERE chapterId = @chapterKitchen2 AND assistantId = @assistant5 AND pageRangeStart = 1 AND pageRangeEnd = 12 AND taskType = 'LETTERING')
    INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
    VALUES (@chapterKitchen2, @assistant5, 1, 12, 'LETTERING', DATEADD(DAY, 50, GETDATE()), 'IN_PROGRESS', 0);
SET @taskKitchen3 = (SELECT id FROM PageTask WHERE chapterId = @chapterKitchen2 AND assistantId = @assistant5 AND pageRangeStart = 1 AND pageRangeEnd = 12 AND taskType = 'LETTERING');

IF NOT EXISTS (SELECT 1 FROM PageTask WHERE chapterId = @chapterLotus1 AND assistantId = @assistant1 AND pageRangeStart = 1 AND pageRangeEnd = 10 AND taskType = 'SKETCHING')
    INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
    VALUES (@chapterLotus1, @assistant1, 1, 10, 'SKETCHING', DATEADD(DAY, 30, GETDATE()), 'REJECTED', 1);
SET @taskLotus1 = (SELECT id FROM PageTask WHERE chapterId = @chapterLotus1 AND assistantId = @assistant1 AND pageRangeStart = 1 AND pageRangeEnd = 10 AND taskType = 'SKETCHING');

IF NOT EXISTS (SELECT 1 FROM PageTask WHERE chapterId = @chapterLotus2 AND assistantId = @assistant4 AND pageRangeStart = 1 AND pageRangeEnd = 8 AND taskType = 'INKING')
    INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
    VALUES (@chapterLotus2, @assistant4, 1, 8, 'INKING', DATEADD(DAY, 55, GETDATE()), 'IN_PROGRESS', 0);
SET @taskLotus2 = (SELECT id FROM PageTask WHERE chapterId = @chapterLotus2 AND assistantId = @assistant4 AND pageRangeStart = 1 AND pageRangeEnd = 8 AND taskType = 'INKING');

IF NOT EXISTS (SELECT 1 FROM PageTask WHERE chapterId = @chapterLotus2 AND assistantId = @assistant5 AND pageRangeStart = 9 AND pageRangeEnd = 18 AND taskType = 'COLORING')
    INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
    VALUES (@chapterLotus2, @assistant5, 9, 18, 'COLORING', DATEADD(DAY, 56, GETDATE()), 'PENDING', 0);
SET @taskLotus3 = (SELECT id FROM PageTask WHERE chapterId = @chapterLotus2 AND assistantId = @assistant5 AND pageRangeStart = 9 AND pageRangeEnd = 18 AND taskType = 'COLORING');

-- ------------------------------------------------------------
--  Chapter images
-- ------------------------------------------------------------
INSERT INTO ChapterImage
    (chapterId, pageTaskId, uploadedBy, imageType, pageNumber, fileUrl, originalFileName, fileSizeBytes, note)
SELECT chapterId, pageTaskId, uploadedBy, imageType, pageNumber, fileUrl, originalFileName, fileSizeBytes, note
FROM (
    VALUES
        (@chapterKitchen1, NULL, @mangaka2, 'COVER', NULL, '/uploads/images/celestial-kitchen-ch1-cover.png', 'celestial-kitchen-ch1-cover.png', 2048000, NULL),
        (@chapterKitchen1, @taskKitchen1, @assistant3, 'PAGE', 1, '/uploads/images/celestial-kitchen-ch1-p01.png', 'celestial-kitchen-ch1-p01.png', 950000, NULL),
        (@chapterKitchen1, @taskKitchen1, @assistant3, 'PAGE', 2, '/uploads/images/celestial-kitchen-ch1-p02.png', 'celestial-kitchen-ch1-p02.png', 975000, NULL),
        (@chapterKitchen1, @taskKitchen2, @assistant4, 'PAGE', 9, '/uploads/images/celestial-kitchen-ch1-p09-tone.png', 'celestial-kitchen-ch1-p09-tone.png', 880000, 'Needs final texture pass.'),
        (@chapterKitchen2, @taskKitchen3, @assistant5, 'REFERENCE', NULL, '/uploads/images/celestial-kitchen-spice-market-ref.png', 'spice-market-ref.png', 1230000, NULL),
        (@chapterLotus1, @taskLotus1, @assistant1, 'PAGE', 4, '/uploads/images/neon-lotus-high-ch1-p04-v1.png', 'neon-lotus-high-ch1-p04-v1.png', 1010000, 'Rejected: redraw crowd perspective.'),
        (@chapterLotus2, @taskLotus2, @assistant4, 'PAGE', 1, '/uploads/images/neon-lotus-high-ch2-p01-ink.png', 'neon-lotus-high-ch2-p01-ink.png', 990000, NULL)
) AS img(chapterId, pageTaskId, uploadedBy, imageType, pageNumber, fileUrl, originalFileName, fileSizeBytes, note)
WHERE NOT EXISTS (
    SELECT 1
    FROM ChapterImage existing
    WHERE existing.fileUrl = img.fileUrl
);

-- ------------------------------------------------------------
--  Manuscripts and annotations
-- ------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Manuscript WHERE fileUrl = '/uploads/manuscripts/celestial-kitchen-ch1-v1.pdf')
    INSERT INTO Manuscript (chapterId, version, status, submittedAt, fileUrl, revisionDeadline, feedback)
    VALUES (@chapterKitchen1, 1, 'UNDER_REVIEW', DATEADD(HOUR, -8, GETDATE()), '/uploads/manuscripts/celestial-kitchen-ch1-v1.pdf', NULL, NULL);
SET @manuscriptKitchen1 = (SELECT id FROM Manuscript WHERE fileUrl = '/uploads/manuscripts/celestial-kitchen-ch1-v1.pdf');

IF NOT EXISTS (SELECT 1 FROM Manuscript WHERE fileUrl = '/uploads/manuscripts/celestial-kitchen-ch2-v1.pdf')
    INSERT INTO Manuscript (chapterId, version, status, submittedAt, fileUrl, revisionDeadline, feedback)
    VALUES (@chapterKitchen2, 1, 'SUBMITTED', DATEADD(HOUR, -2, GETDATE()), '/uploads/manuscripts/celestial-kitchen-ch2-v1.pdf', NULL, NULL);
SET @manuscriptKitchen2 = (SELECT id FROM Manuscript WHERE fileUrl = '/uploads/manuscripts/celestial-kitchen-ch2-v1.pdf');

IF NOT EXISTS (SELECT 1 FROM Manuscript WHERE fileUrl = '/uploads/manuscripts/neon-lotus-high-ch1-v1.pdf')
    INSERT INTO Manuscript (chapterId, version, status, submittedAt, fileUrl, revisionDeadline, feedback)
    VALUES (@chapterLotus1, 1, 'REJECTED', DATEADD(DAY, -1, GETDATE()), '/uploads/manuscripts/neon-lotus-high-ch1-v1.pdf', DATEADD(DAY, 2, GETDATE()), 'Panel flow is strong, but page 4 needs perspective correction before approval.');
SET @manuscriptLotus1 = (SELECT id FROM Manuscript WHERE fileUrl = '/uploads/manuscripts/neon-lotus-high-ch1-v1.pdf');

INSERT INTO Annotation
    (manuscriptId, editorId, pageNumber, content)
SELECT manuscriptId, editorId, pageNumber, content
FROM (
    VALUES
        (@manuscriptKitchen1, @tantou2, 6, 'Clarify the spirit customer silhouette before final approval.'),
        (@manuscriptKitchen2, @tantou2, 2, 'Good pacing; check speech bubble order on the lower panel.'),
        (@manuscriptLotus1, @tantou1, 4, 'Crowd depth and hallway vanishing point do not line up yet.')
) AS ann(manuscriptId, editorId, pageNumber, content)
WHERE NOT EXISTS (
    SELECT 1
    FROM Annotation existing
    WHERE existing.manuscriptId = ann.manuscriptId
      AND existing.editorId = ann.editorId
      AND existing.pageNumber = ann.pageNumber
      AND existing.content = ann.content
);

-- ------------------------------------------------------------
--  Ranking votes and records
-- ------------------------------------------------------------
INSERT INTO VoteEntry
    (periodId, seriesId, boardMemberId, voteCount, readerCount, submittedAt)
SELECT periodId, seriesId, boardMemberId, voteCount, readerCount, submittedAt
FROM (
    VALUES
        (@periodId, @seriesKitchen, @board1, 845, 1200, DATEADD(DAY, -1, GETDATE())),
        (@periodId, @seriesKitchen, @board2, 790, 1180, DATEADD(DAY, -1, GETDATE())),
        (@periodId, @seriesKitchen, @board3, 810, 1210, DATEADD(DAY, -1, GETDATE())),
        (@periodId, @seriesLotus, @board1, 420, 1000, DATEADD(DAY, -1, GETDATE())),
        (@periodId, @seriesLotus, @board2, 390, 990, DATEADD(DAY, -1, GETDATE())),
        (@periodId, @seriesLotus, @board3, 410, 980, DATEADD(DAY, -1, GETDATE()))
) AS ve(periodId, seriesId, boardMemberId, voteCount, readerCount, submittedAt)
WHERE @periodId IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM VoteEntry existing
    WHERE existing.periodId = ve.periodId
      AND existing.seriesId = ve.seriesId
      AND existing.boardMemberId = ve.boardMemberId
);

IF @periodId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM RankingRecord WHERE periodId = @periodId AND seriesId = @seriesKitchen)
    INSERT INTO RankingRecord (periodId, seriesId, rankScore, rankPosition, isBottomTwenty, calculatedAt)
    VALUES (@periodId, @seriesKitchen, 68.67, 2, 0, GETDATE());
SET @rankKitchen = (SELECT id FROM RankingRecord WHERE periodId = @periodId AND seriesId = @seriesKitchen);

IF @periodId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM RankingRecord WHERE periodId = @periodId AND seriesId = @seriesLotus)
    INSERT INTO RankingRecord (periodId, seriesId, rankScore, rankPosition, isBottomTwenty, calculatedAt)
    VALUES (@periodId, @seriesLotus, 40.87, 12, 1, GETDATE());
SET @rankLotus = (SELECT id FROM RankingRecord WHERE periodId = @periodId AND seriesId = @seriesLotus);

-- ------------------------------------------------------------
--  Decision session and votes
-- ------------------------------------------------------------
IF @rankLotus IS NOT NULL AND NOT EXISTS (SELECT 1 FROM DecisionSession WHERE rankingRecordId = @rankLotus)
BEGIN
    INSERT INTO DecisionSession (seriesId, rankingRecordId, status, result, openedAt, closedAt)
    VALUES (@seriesLotus, @rankLotus, 'OPEN', NULL, DATEADD(HOUR, -5, GETDATE()), NULL);
END;
SET @lotusDecisionSession = (SELECT TOP 1 id FROM DecisionSession WHERE rankingRecordId = @rankLotus ORDER BY id);

INSERT INTO DecisionVote
    (sessionId, voterId, decision, justification, votedAt)
SELECT sessionId, voterId, decision, justification, votedAt
FROM (
    VALUES
        (@lotusDecisionSession, @board1, 'CHANGE_TYPE', 'Shift the first arc toward character drama before cancellation is considered.', DATEADD(HOUR, -4, GETDATE())),
        (@lotusDecisionSession, @board2, 'CONTINUE', NULL, DATEADD(HOUR, -3, GETDATE())),
        (@lotusDecisionSession, @board3, 'CANCEL', 'Reader conversion is below the safe threshold after the pilot push.', DATEADD(HOUR, -2, GETDATE()))
) AS dv(sessionId, voterId, decision, justification, votedAt)
WHERE dv.sessionId IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM DecisionVote existing
    WHERE existing.sessionId = dv.sessionId
      AND existing.voterId = dv.voterId
      AND existing.decision = dv.decision
);

-- ------------------------------------------------------------
--  Notifications and audit logs
-- ------------------------------------------------------------
INSERT INTO Notification
    (userId, type, message, referenceId, referenceType, isRead)
SELECT userId, type, message, referenceId, referenceType, isRead
FROM (
    VALUES
        (@mangaka2, 'SERIES_CREATED', 'Series "Celestial Kitchen" is now active.', @proposalKitchen, 'PROPOSAL', 0),
        (@assistant3, 'TASK_ASSIGNED', 'Background task assigned for Celestial Kitchen Chapter 1.', @taskKitchen1, 'TASK', 0),
        (@assistant4, 'TASK_ASSIGNED', 'Inking task assigned for Neon Lotus High Chapter 2.', @taskLotus2, 'TASK', 0),
        (@mangaka3, 'MANUSCRIPT_REJECTED', 'Neon Lotus High Chapter 1 needs revision before approval.', @manuscriptLotus1, 'MANUSCRIPT', 0),
        (@tantou2, 'MANUSCRIPT_SUBMITTED', 'Celestial Kitchen Chapter 2 has been submitted.', @manuscriptKitchen2, 'MANUSCRIPT', 0)
) AS n(userId, type, message, referenceId, referenceType, isRead)
WHERE NOT EXISTS (
    SELECT 1
    FROM Notification existing
    WHERE existing.userId = n.userId
      AND existing.type = n.type
      AND existing.referenceId = n.referenceId
      AND existing.referenceType = n.referenceType
);

INSERT INTO AuditLog
    (actorId, action, entityType, entityId, detail, performedAt)
SELECT actorId, action, entityType, entityId, detail, performedAt
FROM (
    VALUES
        (@mangaka2, 'PROPOSAL_SUBMITTED', 'PROPOSAL', @proposalKitchen, '{"status":"SUBMITTED"}', DATEADD(DAY, -18, GETDATE())),
        (@tantou2, 'PROPOSAL_APPROVED', 'PROPOSAL', @proposalKitchen, '{"status":"APPROVED"}', DATEADD(DAY, -16, GETDATE())),
        (@mangaka2, 'SERIES_CREATED', 'PROPOSAL', @proposalKitchen, CONCAT('{"seriesId":', @seriesKitchen, '}'), DATEADD(DAY, -15, GETDATE())),
        (@assistant3, 'IMAGE_UPLOADED', 'IMAGE', @taskKitchen1, '{"imageType":"PAGE","pageNumber":1}', DATEADD(DAY, -3, GETDATE())),
        (@tantou1, 'MANUSCRIPT_REJECTED', 'MANUSCRIPT', @manuscriptLotus1, '{"status":"REJECTED","revisionRequired":true}', DATEADD(HOUR, -20, GETDATE())),
        (@board3, 'DECISION_VOTE_CAST', 'DECISION', @lotusDecisionSession, '{"decision":"CANCEL"}', DATEADD(HOUR, -2, GETDATE()))
) AS a(actorId, action, entityType, entityId, detail, performedAt)
WHERE a.entityId IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM AuditLog existing
    WHERE existing.action = a.action
      AND existing.entityType = a.entityType
      AND existing.entityId = a.entityId
      AND ISNULL(existing.detail, '') = ISNULL(a.detail, '')
);

PRINT 'Extended test data imported successfully.';
PRINT 'Added users: mangaka2, mangaka3, assistant3, assistant4, assistant5, tantou2.';
PRINT 'Added series: Celestial Kitchen, Neon Lotus High.';
PRINT 'Also added extra chapters, tasks, chapter images, manuscripts, annotations, ranking data and decision votes.';
GO
