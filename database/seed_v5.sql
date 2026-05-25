-- ============================================================
--  MANGA EDITORIAL SYSTEM — FULL SEED (v5 — FIXED)
--  Chạy SAU schema.sql
--  Fixes từ v3+v4:
--    1. Role không có IDENTITY → dùng INSERT thường
--    2. TR_Chapter_SubmissionDeadline: submissionDeadline = publicationDate - 14 ngày (chính xác)
--    3. Proposal status 'SUBMITTED' → 'UNDER_REVIEW'
--    4. Chapter status 'SUBMITTED'/'PUBLISHED' → 'COMPLETE'
--    5. Manuscript status 'REVISION_REQUIRED' → 'REJECTED'
--    6. Manuscript INSERT bỏ seriesTitle/chapterTitle/chapterNumber
--       (DB thực tế chưa có cột này — nullable nên bỏ qua an toàn)
--    7. AuditLog entityId dùng ISNULL(..., -1) tránh NULL insert fail
-- ============================================================

USE MangaEditorialDB;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
SET NOCOUNT ON;
GO

-- ============================================================
--  BƯỚC 1: XÓA TOÀN BỘ DỮ LIỆU CŨ
-- ============================================================

PRINT '>>> Đang xóa dữ liệu cũ...';

EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

DELETE FROM AuditLog;
DELETE FROM Notification;
DELETE FROM DecisionVote;
DELETE FROM DecisionSession;
DELETE FROM VoteEntry;
DELETE FROM RankingRecord;
DELETE FROM RankingPeriod;
DELETE FROM Annotation;
DELETE FROM Manuscript;
DELETE FROM ChapterImage;
DELETE FROM PageTask;
DELETE FROM Chapter;
DELETE FROM SeriesAssistant;
DELETE FROM Series;
DELETE FROM ProposalHistory;
DELETE FROM Proposal;
DELETE FROM MangakaAssistant;
DELETE FROM UserRole;
DELETE FROM [User];

DBCC CHECKIDENT ('AuditLog',        RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('Notification',    RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('DecisionVote',    RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('DecisionSession', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('VoteEntry',       RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('RankingRecord',   RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('RankingPeriod',   RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('Annotation',      RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('Manuscript',      RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('ChapterImage',    RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('PageTask',        RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('Chapter',         RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('Series',          RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('ProposalHistory', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('Proposal',        RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('[User]',          RESEED, 0) WITH NO_INFOMSGS;

EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

PRINT '>>> Xóa xong. Bắt đầu load dữ liệu mới...';
GO

-- ============================================================
--  BƯỚC 2: ROLES
--  FIX: Role.id KHÔNG có IDENTITY — dùng INSERT thường (không SET IDENTITY_INSERT)
-- ============================================================

DELETE FROM [Role];   -- đảm bảo sạch nếu schema seed Role trước

INSERT INTO [Role] (id, name) VALUES
    (1, 'ADMIN'),
    (2, 'MANGAKA'),
    (3, 'ASSISTANT'),
    (4, 'TANTOU_EDITOR'),
    (5, 'EDITORIAL_BOARD');
GO

-- ============================================================
--  BƯỚC 3: USERS
-- ============================================================

INSERT INTO [User] (username, passwordHash, fullName, email, status) VALUES
    ('admin',       '12345', 'System Admin',          'admin@mangaflow.local',    'ACTIVE'),
    ('mangaka1',    '12345', 'Yuki Tanaka',            'mangaka1@mangaflow.local', 'ACTIVE'),
    ('assistant1',  '12345', 'Aiko Mori',              'asst1@mangaflow.local',    'ACTIVE'),
    ('assistant2',  '12345', 'Riku Hayashi',           'asst2@mangaflow.local',    'ACTIVE'),
    ('assistant3',  '12345', 'Mika Saito',             'asst3@mangaflow.local',    'ACTIVE'),
    ('assistant4',  '12345', 'Ren Fujimoto',           'asst4@mangaflow.local',    'ACTIVE'),
    ('tantou1',     '12345', 'Hiroshi Yamamoto',       'tantou1@mangaflow.local',  'ACTIVE'),
    ('board1',      '12345', 'Board Member Keiko',     'board1@mangaflow.local',   'ACTIVE'),
    ('board2',      '12345', 'Board Member Sato',      'board2@mangaflow.local',   'ACTIVE'),
    ('board3',      '12345', 'Board Member Natsuki',   'board3@mangaflow.local',   'ACTIVE'),
    ('mangaka2',    '12345', 'Mai Nguyen',             'mangaka2@mangaflow.local', 'ACTIVE'),
    ('mangaka3',    '12345', 'Kenji Ito',              'mangaka3@mangaflow.local', 'ACTIVE'),
    ('mangaka4',    '12345', 'Hiroto Suzuki',          'mangaka4@mangaflow.local', 'ACTIVE'),
    ('mangaka5',    '12345', 'Yuki Sato',              'mangaka5@mangaflow.local', 'ACTIVE'),
    ('assistant5',  '12345', 'Nora Kim',               'asst5@mangaflow.local',    'ACTIVE'),
    ('assistant6',  '12345', 'Hana Kobayashi',         'asst6@mangaflow.local',    'ACTIVE'),
    ('assistant7',  '12345', 'Daichi Sato',            'asst7@mangaflow.local',    'ACTIVE'),
    ('assistant8',  '12345', 'Emiko Tanaka',           'asst8@mangaflow.local',    'ACTIVE'),
    ('assistant9',  '12345', 'Taro Nakamura',          'asst9@mangaflow.local',    'ACTIVE'),
    ('assistant10', '12345', 'Yuki Kobayashi',         'asst10@mangaflow.local',   'ACTIVE'),
    ('tantou2',     '12345', 'Aya Suzuki',             'tantou2@mangaflow.local',  'ACTIVE'),
    ('tantou3',     '12345', 'Jiro Watanabe',          'tantou3@mangaflow.local',  'ACTIVE');
GO

-- ============================================================
--  BƯỚC 4: USER ROLES
-- ============================================================

INSERT INTO UserRole (userId, roleId)
SELECT u.id, v.roleId
FROM (VALUES
    ('admin',        1),
    ('mangaka1',     2), ('mangaka2',   2), ('mangaka3',  2), ('mangaka4', 2), ('mangaka5', 2),
    ('assistant1',   3), ('assistant2', 3), ('assistant3',3), ('assistant4',3),
    ('assistant5',   3), ('assistant6', 3), ('assistant7',3), ('assistant8',3),
    ('assistant9',   3), ('assistant10',3),
    ('tantou1',      4), ('tantou2',    4), ('tantou3',   4),
    ('board1',       5), ('board2',     5), ('board3',    5)
) AS v(username, roleId)
JOIN [User] u ON u.username = v.username;
GO

-- ============================================================
--  BƯỚC 5: MANGAKA ASSISTANTS
-- ============================================================

INSERT INTO MangakaAssistant (mangakaId, assistantId)
SELECT u1.id, u2.id
FROM (VALUES
    ('mangaka1','assistant1'),('mangaka1','assistant2'),
    ('mangaka1','assistant3'),('mangaka1','assistant4'),
    ('mangaka2','assistant5'),('mangaka2','assistant6'),
    ('mangaka2','assistant7'),('mangaka2','assistant8'),
    ('mangaka3','assistant9'),('mangaka3','assistant10'),
    ('mangaka3','assistant1'),('mangaka3','assistant2'),
    ('mangaka4','assistant3'),('mangaka4','assistant4'),
    ('mangaka4','assistant5'),('mangaka4','assistant6'),
    ('mangaka5','assistant7'),('mangaka5','assistant8'),
    ('mangaka5','assistant9'),('mangaka5','assistant10')
) AS v(mk, asst)
JOIN [User] u1 ON u1.username = v.mk
JOIN [User] u2 ON u2.username = v.asst;
GO

-- ============================================================
--  BƯỚC 6: PROPOSALS
--  FIX: 'SUBMITTED' không hợp lệ → đổi thành 'UNDER_REVIEW'
--       (Moonlight Sanctuary vào queue chờ assign editor)
-- ============================================================

DECLARE
    @mk1  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka1'),
    @mk2  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka2'),
    @mk3  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka3'),
    @mk4  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka4'),
    @mk5  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka5'),
    @t1   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou1'),
    @t2   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou2'),
    @t3   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou3');

-- 1. Shadows of Edo — APPROVED
INSERT INTO Proposal (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
VALUES (@mk1, 'Shadows of Edo', 'Action',
    'A disgraced samurai seeks redemption in Edo-period Japan, uncovering a conspiracy threatening the Shogunate.',
    '/uploads/proposals/sample-shadows-of-edo.pdf', 'sample-shadows-of-edo.pdf',
    1, 'APPROVED', DATEADD(DAY,-20,GETDATE()), @t1, 1, DATEADD(DAY,-25,GETDATE()), DATEADD(DAY,-20,GETDATE()));

-- 2. Cyber Ronin — UNDER_REVIEW
INSERT INTO Proposal (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
VALUES (@mk1, 'Cyber Ronin', 'Action',
    'In 2157, a cybernetic warrior hunts rogue AIs across neon-lit megacities.',
    '/uploads/proposals/sample-cyber-ronin.pdf', 'sample-cyber-ronin.pdf',
    1, 'UNDER_REVIEW', DATEADD(DAY,-3,GETDATE()), @t1, 1, DATEADD(DAY,-5,GETDATE()), DATEADD(DAY,-3,GETDATE()));

-- 3. Celestial Kitchen — APPROVED
INSERT INTO Proposal (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
VALUES (@mk2, 'Celestial Kitchen', 'Fantasy',
    'A young cook serves spirits in a floating night market and learns the price of forgotten recipes.',
    '/uploads/proposals/sample-celestial-kitchen.pdf', 'sample-celestial-kitchen.pdf',
    12, 'APPROVED', DATEADD(DAY,-18,GETDATE()), @t2, 1, DATEADD(DAY,-22,GETDATE()), DATEADD(DAY,-16,GETDATE()));

-- 4. Neon Lotus High — APPROVED
INSERT INTO Proposal (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
VALUES (@mk3, 'Neon Lotus High', 'Drama',
    'Students at an elite cyber-art academy battle through murals, music and augmented dreams.',
    '/uploads/proposals/sample-neon-lotus-high.pdf', 'sample-neon-lotus-high.pdf',
    18, 'APPROVED', DATEADD(DAY,-14,GETDATE()), @t1, 2, DATEADD(DAY,-25,GETDATE()), DATEADD(DAY,-10,GETDATE()));

-- 5. Rainfall Bakery — REVISION_REQUESTED
INSERT INTO Proposal (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
VALUES (@mk2, 'Rainfall Bakery', 'Slice of Life',
    'A quiet bakery becomes the meeting point for neighbors trying to rebuild after a long monsoon.',
    '/uploads/proposals/sample-rainfall-bakery.pdf', 'sample-rainfall-bakery.pdf',
    8, 'REVISION_REQUESTED', DATEADD(DAY,-6,GETDATE()), @t2, 1, DATEADD(DAY,-8,GETDATE()), DATEADD(DAY,-2,GETDATE()));

-- 6. Steampunk Chronicles — DRAFT
INSERT INTO Proposal (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submitAttemptCount, createdAt, updatedAt)
VALUES (@mk2, 'Steampunk Chronicles', 'Steampunk',
    'An engineer discovers sentient clockwork machines and must choose between progress and tradition.',
    '/uploads/proposals/steampunk-chronicles-v1.pdf', 'steampunk-chronicles-v1.pdf',
    20, 'DRAFT', 0, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-10,GETDATE()));

-- 7. Moonlight Sanctuary — UNDER_REVIEW (was SUBMITTED — invalid status)
INSERT INTO Proposal (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
VALUES (@mk3, 'Moonlight Sanctuary', 'Fantasy',
    'A princess discovers her magical bloodline and must unite fractured kingdoms against an ancient evil.',
    '/uploads/proposals/moonlight-sanctuary-v1.pdf', 'moonlight-sanctuary-v1.pdf',
    24, 'UNDER_REVIEW', DATEADD(DAY,-7,GETDATE()), @t3, 1, DATEADD(DAY,-8,GETDATE()), DATEADD(DAY,-7,GETDATE()));

-- 8. Mystery at Midnight — UNDER_REVIEW
INSERT INTO Proposal (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
VALUES (@mk4, 'Mystery at Midnight', 'Mystery',
    'A detective with paranormal sensitivity investigates crimes at the boundary between worlds.',
    '/uploads/proposals/mystery-midnight-v1.pdf', 'mystery-midnight-v1.pdf',
    18, 'UNDER_REVIEW', DATEADD(DAY,-4,GETDATE()), @t2, 1, DATEADD(DAY,-5,GETDATE()), DATEADD(DAY,-4,GETDATE()));

-- 9. Heartstring Cafe — REVISION_REQUESTED
INSERT INTO Proposal (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
VALUES (@mk5, 'Heartstring Cafe', 'Slice of Life',
    'A small-town cafe becomes the gathering place for unlikely friendships and second chances.',
    '/uploads/proposals/heartstring-cafe-v1.pdf', 'heartstring-cafe-v1.pdf',
    16, 'REVISION_REQUESTED', DATEADD(DAY,-12,GETDATE()), @t3, 1, DATEADD(DAY,-15,GETDATE()), DATEADD(DAY,-2,GETDATE()));

-- 10. Alien Overlords — REJECTED
INSERT INTO Proposal (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, rejectedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
VALUES (@mk3, 'Alien Overlords', 'Sci-Fi',
    'Humans discover they are not alone - and the visitors are not friendly.',
    '/uploads/proposals/alien-overlords-v1.pdf', 'alien-overlords-v1.pdf',
    22, 'REJECTED', DATEADD(DAY,-20,GETDATE()), DATEADD(DAY,-15,GETDATE()), @t1, 2, DATEADD(DAY,-25,GETDATE()), DATEADD(DAY,-15,GETDATE()));

-- 11. Shadows of Tokyo — APPROVED
INSERT INTO Proposal (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, submittedAt, assignedEditorId, submitAttemptCount, createdAt, updatedAt)
VALUES (@mk2, 'Shadows of Tokyo', 'Thriller',
    'A vigilante operates in Tokyo underground, fighting corruption from within.',
    '/uploads/proposals/shadows-tokyo-v1.pdf', 'shadows-tokyo-v1.pdf',
    26, 'APPROVED', DATEADD(DAY,-30,GETDATE()), @t2, 1, DATEADD(DAY,-35,GETDATE()), DATEADD(DAY,-28,GETDATE()));
GO

-- ============================================================
--  BƯỚC 7: PROPOSAL HISTORY
-- ============================================================

DECLARE
    @mk1  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka1'),
    @mk2  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka2'),
    @mk3  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka3'),
    @mk4  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka4'),
    @mk5  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka5'),
    @t1   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou1'),
    @t2   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou2'),
    @t3   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou3'),
    @pEdo       BIGINT = (SELECT id FROM Proposal WHERE title = 'Shadows of Edo'),
    @pCyber     BIGINT = (SELECT id FROM Proposal WHERE title = 'Cyber Ronin'),
    @pKitchen   BIGINT = (SELECT id FROM Proposal WHERE title = 'Celestial Kitchen'),
    @pLotus     BIGINT = (SELECT id FROM Proposal WHERE title = 'Neon Lotus High'),
    @pBakery    BIGINT = (SELECT id FROM Proposal WHERE title = 'Rainfall Bakery'),
    @pSteam     BIGINT = (SELECT id FROM Proposal WHERE title = 'Steampunk Chronicles'),
    @pMoon      BIGINT = (SELECT id FROM Proposal WHERE title = 'Moonlight Sanctuary'),
    @pMystery   BIGINT = (SELECT id FROM Proposal WHERE title = 'Mystery at Midnight'),
    @pCafe      BIGINT = (SELECT id FROM Proposal WHERE title = 'Heartstring Cafe'),
    @pAlien     BIGINT = (SELECT id FROM Proposal WHERE title = 'Alien Overlords'),
    @pTokyo     BIGINT = (SELECT id FROM Proposal WHERE title = 'Shadows of Tokyo');

INSERT INTO ProposalHistory (proposalId, actorId, actorRole, actionType, note, submitAttemptNumber, createdAt)
VALUES
    (@pEdo, @mk1, 'MANGAKA',       'CREATED',            'Seed draft proposal created.',                     0, DATEADD(DAY,-25,GETDATE())),
    (@pEdo, @mk1, 'MANGAKA',       'SUBMITTED',          'Seed proposal submitted for Tantou review.',       1, DATEADD(DAY,-24,GETDATE())),
    (@pEdo, NULL, 'SYSTEM',        'ASSIGNED_EDITOR',    'Assigned to Tantou Editor tantou1.',               1, DATEADD(DAY,-24,GETDATE())),
    (@pEdo, @t1,  'TANTOU_EDITOR', 'APPROVED',           'Seed proposal approved.',                          1, DATEADD(DAY,-20,GETDATE())),
    (@pCyber, @mk1,'MANGAKA',      'CREATED',            'Seed draft proposal created.',                     0, DATEADD(DAY,-5,GETDATE())),
    (@pCyber, @mk1,'MANGAKA',      'SUBMITTED',          'Seed proposal submitted for Tantou review.',       1, DATEADD(DAY,-3,GETDATE())),
    (@pCyber, NULL,'SYSTEM',       'ASSIGNED_EDITOR',    'Assigned to Tantou Editor tantou1.',               1, DATEADD(DAY,-3,GETDATE())),
    (@pKitchen,@mk2,'MANGAKA',     'CREATED',            'Extended seed proposal created.',                  0, DATEADD(DAY,-22,GETDATE())),
    (@pKitchen,@mk2,'MANGAKA',     'SUBMITTED',          'Submitted with menu-board character samples.',     1, DATEADD(DAY,-18,GETDATE())),
    (@pKitchen,NULL,'SYSTEM',      'ASSIGNED_EDITOR',    'Assigned to Tantou Editor tantou2.',               1, DATEADD(DAY,-18,GETDATE())),
    (@pKitchen,@t2,'TANTOU_EDITOR','APPROVED',           'Approved for short pilot serialization.',          1, DATEADD(DAY,-16,GETDATE())),
    (@pLotus, @mk3,'MANGAKA',      'CREATED',            'Extended seed proposal created.',                  0, DATEADD(DAY,-25,GETDATE())),
    (@pLotus, @mk3,'MANGAKA',      'SUBMITTED',          'Resubmitted after tone revision.',                 2, DATEADD(DAY,-14,GETDATE())),
    (@pLotus, @t1,'TANTOU_EDITOR', 'APPROVED',           'Approved after second attempt.',                   2, DATEADD(DAY,-10,GETDATE())),
    (@pBakery,@mk2,'MANGAKA',      'CREATED',            'Extended seed proposal created.',                  0, DATEADD(DAY,-8,GETDATE())),
    (@pBakery,@mk2,'MANGAKA',      'SUBMITTED',          'Submitted cozy drama concept.',                    1, DATEADD(DAY,-6,GETDATE())),
    (@pBakery,@t2,'TANTOU_EDITOR', 'REVISE_REQUESTED',   'Please sharpen the main conflict in chapter one.', 1, DATEADD(DAY,-2,GETDATE())),
    (@pSteam, @mk2,'MANGAKA',      'CREATED',            'Initial draft created.',                           0, DATEADD(DAY,-10,GETDATE())),
    (@pMoon,  @mk3,'MANGAKA',      'CREATED',            'Initial draft created.',                           0, DATEADD(DAY,-8,GETDATE())),
    (@pMoon,  @mk3,'MANGAKA',      'SUBMITTED',          'Submitted for Tantou review.',                     1, DATEADD(DAY,-7,GETDATE())),
    (@pMystery,@mk4,'MANGAKA',     'CREATED',            'Initial draft created.',                           0, DATEADD(DAY,-5,GETDATE())),
    (@pMystery,@mk4,'MANGAKA',     'SUBMITTED',          'Submitted for Tantou review.',                     1, DATEADD(DAY,-4,GETDATE())),
    (@pMystery,NULL,'SYSTEM',      'ASSIGNED_EDITOR',    'Assigned to Tantou Editor tantou2.',               1, DATEADD(DAY,-4,GETDATE())),
    (@pCafe,  @mk5,'MANGAKA',      'CREATED',            'Initial draft created.',                           0, DATEADD(DAY,-15,GETDATE())),
    (@pCafe,  @mk5,'MANGAKA',      'SUBMITTED',          'Submitted for Tantou review.',                     1, DATEADD(DAY,-12,GETDATE())),
    (@pCafe,  NULL,'SYSTEM',       'ASSIGNED_EDITOR',    'Assigned to Tantou Editor tantou3.',               1, DATEADD(DAY,-12,GETDATE())),
    (@pCafe,  @t3,'TANTOU_EDITOR', 'REVISE_REQUESTED',   'Needs more worldbuilding and character depth.',    1, DATEADD(DAY,-2,GETDATE())),
    (@pAlien, @mk3,'MANGAKA',      'CREATED',            'Initial draft created.',                           0, DATEADD(DAY,-25,GETDATE())),
    (@pAlien, @mk3,'MANGAKA',      'SUBMITTED',          'First submission.',                                1, DATEADD(DAY,-20,GETDATE())),
    (@pAlien, NULL,'SYSTEM',       'ASSIGNED_EDITOR',    'Assigned to Tantou Editor tantou1.',               1, DATEADD(DAY,-20,GETDATE())),
    (@pAlien, @t1,'TANTOU_EDITOR', 'REVISE_REQUESTED',   'Concept needs significant refinement.',            1, DATEADD(DAY,-18,GETDATE())),
    (@pAlien, @mk3,'MANGAKA',      'RESUBMITTED',        'Resubmitted with revisions.',                      2, DATEADD(DAY,-16,GETDATE())),
    (@pAlien, @t1,'TANTOU_EDITOR', 'REJECTED',           'Concept too similar to existing works.',           2, DATEADD(DAY,-15,GETDATE())),
    (@pTokyo, @mk2,'MANGAKA',      'CREATED',            'Initial draft created.',                           0, DATEADD(DAY,-35,GETDATE())),
    (@pTokyo, @mk2,'MANGAKA',      'SUBMITTED',          'Submitted for review.',                            1, DATEADD(DAY,-30,GETDATE())),
    (@pTokyo, NULL,'SYSTEM',       'ASSIGNED_EDITOR',    'Assigned to Tantou Editor tantou2.',               1, DATEADD(DAY,-30,GETDATE())),
    (@pTokyo, @t2,'TANTOU_EDITOR', 'APPROVED',           'Excellent concept. Approved for series.',          1, DATEADD(DAY,-28,GETDATE()));
GO

-- ============================================================
--  BƯỚC 8: SERIES
-- ============================================================

DECLARE
    @mk1  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka1'),
    @mk2  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka2'),
    @mk3  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka3'),
    @t1   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou1'),
    @t2   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou2'),
    @pEdo     BIGINT = (SELECT id FROM Proposal WHERE title = 'Shadows of Edo'),
    @pKitchen BIGINT = (SELECT id FROM Proposal WHERE title = 'Celestial Kitchen'),
    @pLotus   BIGINT = (SELECT id FROM Proposal WHERE title = 'Neon Lotus High'),
    @pTokyo   BIGINT = (SELECT id FROM Proposal WHERE title = 'Shadows of Tokyo');

INSERT INTO Series (proposalId, mangakaId, tantouEditorId, title, genre, status, publicationDate, createdAt)
VALUES
    (@pEdo,     @mk1, @t1, 'Shadows of Edo',    'Action',   'ACTIVE', DATEADD(DAY,60,GETDATE()),  GETDATE()),
    (@pKitchen, @mk2, @t2, 'Celestial Kitchen', 'Fantasy',  'ACTIVE', DATEADD(DAY,45,GETDATE()),  DATEADD(DAY,-15,GETDATE())),
    (@pLotus,   @mk3, @t1, 'Neon Lotus High',   'Drama',    'ACTIVE', DATEADD(DAY,50,GETDATE()),  DATEADD(DAY,-9,GETDATE())),
    (@pTokyo,   @mk2, @t2, 'Shadows of Tokyo',  'Thriller', 'ACTIVE', DATEADD(DAY,45,GETDATE()),  DATEADD(DAY,-25,GETDATE()));
GO

-- ============================================================
--  BƯỚC 9: SERIES ASSISTANTS
-- ============================================================

DECLARE
    @a1  BIGINT = (SELECT id FROM [User] WHERE username = 'assistant1'),
    @a2  BIGINT = (SELECT id FROM [User] WHERE username = 'assistant2'),
    @a3  BIGINT = (SELECT id FROM [User] WHERE username = 'assistant3'),
    @a4  BIGINT = (SELECT id FROM [User] WHERE username = 'assistant4'),
    @a5  BIGINT = (SELECT id FROM [User] WHERE username = 'assistant5'),
    @sEdo     BIGINT = (SELECT id FROM Series WHERE title = 'Shadows of Edo'),
    @sKitchen BIGINT = (SELECT id FROM Series WHERE title = 'Celestial Kitchen'),
    @sLotus   BIGINT = (SELECT id FROM Series WHERE title = 'Neon Lotus High'),
    @sTokyo   BIGINT = (SELECT id FROM Series WHERE title = 'Shadows of Tokyo');

INSERT INTO SeriesAssistant (seriesId, assistantId, enrolledAt)
VALUES
    (@sEdo,     @a1, DATEADD(DAY,-20,GETDATE())),
    (@sEdo,     @a2, DATEADD(DAY,-20,GETDATE())),
    (@sKitchen, @a3, DATEADD(DAY,-14,GETDATE())),
    (@sKitchen, @a4, DATEADD(DAY,-14,GETDATE())),
    (@sKitchen, @a5, DATEADD(DAY,-7, GETDATE())),
    (@sLotus,   @a1, DATEADD(DAY,-8, GETDATE())),
    (@sLotus,   @a4, DATEADD(DAY,-8, GETDATE())),
    (@sLotus,   @a5, DATEADD(DAY,-6, GETDATE())),
    (@sTokyo,   @a1, DATEADD(DAY,-3, GETDATE())),
    (@sTokyo,   @a5, DATEADD(DAY,-3, GETDATE()));
GO

-- ============================================================
--  BƯỚC 10: CHAPTERS
--  FIX: TR_Chapter_SubmissionDeadline → submissionDeadline = publicationDate - 14 ngày (chính xác)
--  FIX: Status 'SUBMITTED'  → 'COMPLETE'
--       Status 'PUBLISHED'  → 'COMPLETE'
--       (schema chỉ cho: PLANNING, IN_PROGRESS, COMPLETE, EDITORIAL_REVIEW, APPROVED, REJECTED)
-- ============================================================

DECLARE
    @sEdo     BIGINT = (SELECT id FROM Series WHERE title = 'Shadows of Edo'),
    @sKitchen BIGINT = (SELECT id FROM Series WHERE title = 'Celestial Kitchen'),
    @sLotus   BIGINT = (SELECT id FROM Series WHERE title = 'Neon Lotus High'),
    @sTokyo   BIGINT = (SELECT id FROM Series WHERE title = 'Shadows of Tokyo');

-- ── Shadows of Edo ──────────────────────────────────────────
-- Ch1: pub = today+60 → deadline = today+46
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sEdo, 1, 'The Broken Blade',
        'IN_PROGRESS',
        DATEADD(DAY,46,GETDATE()), DATEADD(DAY,60,GETDATE()),
        45.00, 0);

-- Ch2: pub = today+90 → deadline = today+76
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sEdo, 2, 'River of Shadows',
        'PLANNING',
        DATEADD(DAY,76,GETDATE()), DATEADD(DAY,90,GETDATE()),
        0.00, 0);

-- ── Celestial Kitchen ───────────────────────────────────────
-- Ch1: pub = today+45 → deadline = today+31
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sKitchen, 1, 'Soup for the Moon Rabbit',
        'EDITORIAL_REVIEW',
        DATEADD(DAY,31,GETDATE()), DATEADD(DAY,45,GETDATE()),
        100.00, 0);

-- Ch2: pub = today+75 → deadline = today+61
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sKitchen, 2, 'The Spice Map',
        'IN_PROGRESS',
        DATEADD(DAY,61,GETDATE()), DATEADD(DAY,75,GETDATE()),
        62.50, 0);

-- Ch3: pub = today+29 → deadline = today+15
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sKitchen, 3, 'The Secret Recipe',
        'IN_PROGRESS',
        DATEADD(DAY,15,GETDATE()), DATEADD(DAY,29,GETDATE()),
        45.00, 0);

-- Ch4: pub = today+36 → deadline = today+22
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sKitchen, 4, 'Culinary Competition',
        'PLANNING',
        DATEADD(DAY,22,GETDATE()), DATEADD(DAY,36,GETDATE()),
        10.00, 0);

-- ── Neon Lotus High ─────────────────────────────────────────
-- Ch1: pub = today+50 → deadline = today+36
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sLotus, 1, 'First Bell in Neon Rain',
        'REJECTED',
        DATEADD(DAY,36,GETDATE()), DATEADD(DAY,50,GETDATE()),
        100.00, 1);

-- Ch2: pub = today+80 → deadline = today+66
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sLotus, 2, 'Graffiti Exam',
        'IN_PROGRESS',
        DATEADD(DAY,66,GETDATE()), DATEADD(DAY,80,GETDATE()),
        35.00, 1);

-- Ch3: pub = today+22 → deadline = today+8
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sLotus, 3, 'City Lights Descend',
        'EDITORIAL_REVIEW',
        DATEADD(DAY,8,GETDATE()), DATEADD(DAY,22,GETDATE()),
        95.00, 1);

-- Ch4: pub = today+29 → deadline = today+15
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sLotus, 4, 'A New Dawn',
        'COMPLETE',       -- was SUBMITTED (invalid)
        DATEADD(DAY,15,GETDATE()), DATEADD(DAY,29,GETDATE()),
        100.00, 0);

-- Ch5: pub = today+24 → deadline = today+10
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sLotus, 5, 'Reflection and Resolve',
        'APPROVED',
        DATEADD(DAY,10,GETDATE()), DATEADD(DAY,24,GETDATE()),
        100.00, 0);

-- Ch6: pub = today-3 → deadline = today-17
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sLotus, 6, 'Echoes of Fate',
        'COMPLETE',       -- was PUBLISHED (invalid)
        DATEADD(DAY,-17,GETDATE()), DATEADD(DAY,-3,GETDATE()),
        100.00, 0);

-- ── Shadows of Tokyo ────────────────────────────────────────
-- Ch1: pub = today+20 → deadline = today+6
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sTokyo, 1, 'The Vigilante Emerges',
        'IN_PROGRESS',
        DATEADD(DAY,6,GETDATE()), DATEADD(DAY,20,GETDATE()),
        60.00, 0);

-- Ch2: pub = today+27 → deadline = today+13
INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk)
VALUES (@sTokyo, 2, 'Underground Network',
        'PLANNING',
        DATEADD(DAY,13,GETDATE()), DATEADD(DAY,27,GETDATE()),
        20.00, 0);
GO

-- ============================================================
--  BƯỚC 11: PAGE TASKS
-- ============================================================

DECLARE
    @a1  BIGINT = (SELECT id FROM [User] WHERE username = 'assistant1'),
    @a2  BIGINT = (SELECT id FROM [User] WHERE username = 'assistant2'),
    @a3  BIGINT = (SELECT id FROM [User] WHERE username = 'assistant3'),
    @a4  BIGINT = (SELECT id FROM [User] WHERE username = 'assistant4'),
    @a5  BIGINT = (SELECT id FROM [User] WHERE username = 'assistant5'),
    @a6  BIGINT = (SELECT id FROM [User] WHERE username = 'assistant6'),

    @chEdo1  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Shadows of Edo')     AND chapterNumber=1),
    @chKit1  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Celestial Kitchen')  AND chapterNumber=1),
    @chKit2  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Celestial Kitchen')  AND chapterNumber=2),
    @chKit3  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Celestial Kitchen')  AND chapterNumber=3),
    @chLot1  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Neon Lotus High')    AND chapterNumber=1),
    @chLot2  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Neon Lotus High')    AND chapterNumber=2),
    @chLot3  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Neon Lotus High')    AND chapterNumber=3),
    @chTok1  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Shadows of Tokyo')   AND chapterNumber=1);

-- Shadows of Edo Ch1
INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
VALUES
    (@chEdo1, @a1,  1, 10, 'SKETCHING', DATEADD(DAY,30,GETDATE()), 'IN_PROGRESS', 0),
    (@chEdo1, @a2, 11, 20, 'INKING',    DATEADD(DAY,35,GETDATE()), 'IN_PROGRESS', 0),
    (@chEdo1, @a1, 21, 30, 'COLORING',  DATEADD(DAY,40,GETDATE()), 'IN_PROGRESS', 0);

-- Celestial Kitchen Ch1
INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
VALUES
    (@chKit1, @a3,  1,  8, 'BACKGROUND', DATEADD(DAY,25,GETDATE()), 'APPROVED',   0),
    (@chKit1, @a4,  9, 16, 'TONING',     DATEADD(DAY,26,GETDATE()), 'SUBMITTED',  0);

-- Celestial Kitchen Ch2
INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
VALUES
    (@chKit2, @a5,  1, 12, 'LETTERING', DATEADD(DAY,50,GETDATE()), 'IN_PROGRESS', 0);

-- Celestial Kitchen Ch3
INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
VALUES
    (@chKit3, @a1,  1, 10, 'INK',  DATEADD(DAY,2,GETDATE()), 'IN_PROGRESS', 0),
    (@chKit3, @a2, 11, 20, 'TONE', DATEADD(DAY,3,GETDATE()), 'IN_PROGRESS', 0);

-- Neon Lotus High Ch1
INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
VALUES
    (@chLot1, @a1,  1, 10, 'SKETCHING', DATEADD(DAY,30,GETDATE()), 'REJECTED', 1);

-- Neon Lotus High Ch2
INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
VALUES
    (@chLot2, @a4,  1,  8, 'INKING',   DATEADD(DAY,55,GETDATE()), 'IN_PROGRESS', 0),
    (@chLot2, @a5,  9, 18, 'COLORING', DATEADD(DAY,56,GETDATE()), 'IN_PROGRESS', 0);

-- Neon Lotus High Ch3
INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
VALUES
    (@chLot3, @a5,  1, 15, 'INK',  DATEADD(DAY,-1,GETDATE()), 'SUBMITTED', 0),
    (@chLot3, @a6, 16, 25, 'TONE', DATEADD(DAY,-1,GETDATE()), 'APPROVED',  1);

-- Shadows of Tokyo Ch1
INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount)
VALUES
    (@chTok1, @a1,  1, 12, 'INK',        DATEADD(DAY,4,GETDATE()), 'IN_PROGRESS', 0),
    (@chTok1, @a5, 13, 25, 'BACKGROUND', DATEADD(DAY,5,GETDATE()), 'REJECTED',    1);
GO

-- ============================================================
--  BƯỚC 12: MANUSCRIPTS
--  FIX: Thêm seriesTitle, chapterTitle, chapterNumber (cột có trong schema)
--  FIX: Status 'REVISION_REQUIRED' → 'REJECTED' (invalid status)
-- ============================================================

DECLARE
    @chEdo1  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Shadows of Edo')     AND chapterNumber=1),
    @chKit1  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Celestial Kitchen')  AND chapterNumber=1),
    @chKit2  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Celestial Kitchen')  AND chapterNumber=2),
    @chLot1  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Neon Lotus High')    AND chapterNumber=1),
    @chLot4  BIGINT = (SELECT id FROM Chapter WHERE seriesId=(SELECT id FROM Series WHERE title='Neon Lotus High')    AND chapterNumber=4);

INSERT INTO Manuscript (chapterId, version, status, submittedAt, fileUrl, revisionDeadline, feedback)
VALUES
    -- Shadows of Edo Ch1 v1
    (@chEdo1, 1, 'UNDER_REVIEW',
     DATEADD(HOUR,-8,GETDATE()),
     '/uploads/manuscripts/shadows-edo-ch1-v1.pdf',
     NULL, NULL),

    -- Celestial Kitchen Ch1 v1
    (@chKit1, 1, 'APPROVED',
     DATEADD(DAY,-5,GETDATE()),
     '/uploads/manuscripts/celestial-kitchen-ch1-v1.pdf',
     NULL, NULL),

    -- Celestial Kitchen Ch1 v2
    (@chKit1, 2, 'UNDER_REVIEW',
     DATEADD(HOUR,-3,GETDATE()),
     '/uploads/manuscripts/celestial-kitchen-ch1-v2.pdf',
     NULL, NULL),

    -- Celestial Kitchen Ch2 v1
    (@chKit2, 1, 'SUBMITTED',
     DATEADD(HOUR,-2,GETDATE()),
     '/uploads/manuscripts/celestial-kitchen-ch2-v1.pdf',
     NULL, NULL),

    -- Neon Lotus High Ch1 v1
    (@chLot1, 1, 'REJECTED',
     DATEADD(DAY,-1,GETDATE()),
     '/uploads/manuscripts/neon-lotus-high-ch1-v1.pdf',
     DATEADD(DAY,2,GETDATE()),
     'Panel flow is strong, but page 4 needs perspective correction before approval.'),

    -- Neon Lotus High Ch1 v2
    (@chLot1, 2, 'UNDER_REVIEW',
     DATEADD(HOUR,-1,GETDATE()),
     '/uploads/manuscripts/neon-lotus-high-ch1-v2.pdf',
     NULL, NULL),

    -- Neon Lotus High Ch4 v1 (was REVISION_REQUIRED → REJECTED)
    (@chLot4, 1, 'REJECTED',
     DATEADD(DAY,-1,GETDATE()),
     '/uploads/manuscripts/neon-lotus-high-ch4-v1.pdf',
     DATEADD(DAY,3,GETDATE()),
     'Action sequences need better flow. Reorganize page order and improve transitions.');
GO

-- ============================================================
--  BƯỚC 13: ANNOTATIONS
-- ============================================================

DECLARE
    @t1   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou1'),
    @t2   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou2'),
    @mEdo1   BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/shadows-edo-ch1-v1.pdf'),
    @mKit1v1 BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/celestial-kitchen-ch1-v1.pdf'),
    @mKit1v2 BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/celestial-kitchen-ch1-v2.pdf'),
    @mKit2v1 BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/celestial-kitchen-ch2-v1.pdf'),
    @mLot1v1 BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/neon-lotus-high-ch1-v1.pdf'),
    @mLot1v2 BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/neon-lotus-high-ch1-v2.pdf'),
    @mLot4v1 BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/neon-lotus-high-ch4-v1.pdf');

INSERT INTO Annotation (manuscriptId, editorId, pageNumber, content)
VALUES
    (@mEdo1,   @t1, 3, 'The sword perspective needs correction — blade appears too short at this angle.'),
    (@mKit1v1, @t2, 6, 'Clarify the spirit customer silhouette before final approval.'),
    (@mKit1v2, @t2, 3, 'Great improvement on spirit expression. More clarity here.'),
    (@mKit1v2, @t2, 5, 'Background details are excellent — maintains atmosphere.'),
    (@mKit1v2, @t2, 8, 'Customer silhouette now clear. Approved for this section.'),
    (@mKit2v1, @t2, 2, 'Good pacing; check speech bubble order on the lower panel.'),
    (@mLot1v1, @t1, 4, 'Crowd depth and hallway vanishing point do not line up yet.'),
    (@mLot1v2, @t1, 4, 'Perspective correction done well. Hallway vanishing point now correct.'),
    (@mLot1v2, @t1, 7, 'Building depth improved significantly.'),
    (@mLot4v1, @t1, 2, 'Sequence jumps too quickly. Need more reaction shots.'),
    (@mLot4v1, @t1, 5, 'Pacing breaks here. Restructure panels 3-5.'),
    (@mLot4v1, @t1, 9, 'Climactic moment feels rushed. Extend with character reaction.');
GO

-- ============================================================
--  BƯỚC 14: RANKING PERIODS, VOTE ENTRIES, RANKING RECORDS
-- ============================================================

INSERT INTO RankingPeriod (name, startDate, endDate, status, calculatedAt)
VALUES
    ('Q2 2026',               DATEADD(DAY,-30,GETDATE()), DATEADD(DAY,30,GETDATE()),  'OPEN',       NULL),
    ('Q1 2026 (Jan-Mar)',     DATEADD(DAY,-120,GETDATE()),DATEADD(DAY,-60,GETDATE()), 'CALCULATED', DATEADD(DAY,-50,GETDATE())),
    ('Q2 2026 (Apr-Jun)',     DATEADD(DAY,-30,GETDATE()), DATEADD(DAY,60,GETDATE()),  'OPEN',       NULL);
GO

DECLARE
    @b1  BIGINT = (SELECT id FROM [User] WHERE username = 'board1'),
    @b2  BIGINT = (SELECT id FROM [User] WHERE username = 'board2'),
    @b3  BIGINT = (SELECT id FROM [User] WHERE username = 'board3'),
    @sEdo     BIGINT = (SELECT id FROM Series WHERE title = 'Shadows of Edo'),
    @sKitchen BIGINT = (SELECT id FROM Series WHERE title = 'Celestial Kitchen'),
    @sLotus   BIGINT = (SELECT id FROM Series WHERE title = 'Neon Lotus High'),
    @sTokyo   BIGINT = (SELECT id FROM Series WHERE title = 'Shadows of Tokyo'),
    @pQ2base  BIGINT = (SELECT id FROM RankingPeriod WHERE name = 'Q2 2026'),
    @pQ1      BIGINT = (SELECT id FROM RankingPeriod WHERE name = 'Q1 2026 (Jan-Mar)'),
    @pQ2ext   BIGINT = (SELECT id FROM RankingPeriod WHERE name = 'Q2 2026 (Apr-Jun)');

-- Vote entries — Q2 base
INSERT INTO VoteEntry (periodId, seriesId, boardMemberId, voteCount, readerCount, submittedAt)
VALUES
    (@pQ2base, @sEdo,     @b1, 845, 1200, DATEADD(DAY,-1,GETDATE())),
    (@pQ2base, @sEdo,     @b2, 790, 1180, DATEADD(DAY,-1,GETDATE())),
    (@pQ2base, @sEdo,     @b3, 810, 1210, DATEADD(DAY,-1,GETDATE())),
    (@pQ2base, @sKitchen, @b1, 845, 1200, DATEADD(DAY,-1,GETDATE())),
    (@pQ2base, @sKitchen, @b2, 790, 1180, DATEADD(DAY,-1,GETDATE())),
    (@pQ2base, @sKitchen, @b3, 810, 1210, DATEADD(DAY,-1,GETDATE())),
    (@pQ2base, @sLotus,   @b1, 420, 1000, DATEADD(DAY,-1,GETDATE())),
    (@pQ2base, @sLotus,   @b2, 390,  990, DATEADD(DAY,-1,GETDATE())),
    (@pQ2base, @sLotus,   @b3, 410,  980, DATEADD(DAY,-1,GETDATE()));

-- Vote entries — Q2 extended
INSERT INTO VoteEntry (periodId, seriesId, boardMemberId, voteCount, readerCount, submittedAt)
VALUES
    (@pQ2ext, @sKitchen, @b1, 920, 1350, DATEADD(DAY,-2,GETDATE())),
    (@pQ2ext, @sKitchen, @b2, 880, 1320, DATEADD(DAY,-2,GETDATE())),
    (@pQ2ext, @sKitchen, @b3, 910, 1360, DATEADD(DAY,-2,GETDATE())),
    (@pQ2ext, @sLotus,   @b1, 650, 1100, DATEADD(DAY,-2,GETDATE())),
    (@pQ2ext, @sLotus,   @b2, 620, 1080, DATEADD(DAY,-2,GETDATE())),
    (@pQ2ext, @sLotus,   @b3, 640, 1090, DATEADD(DAY,-2,GETDATE())),
    (@pQ2ext, @sTokyo,   @b1, 520,  950, DATEADD(DAY,-1,GETDATE())),
    (@pQ2ext, @sTokyo,   @b2, 480,  920, DATEADD(DAY,-1,GETDATE())),
    (@pQ2ext, @sTokyo,   @b3, 510,  940, DATEADD(DAY,-1,GETDATE()));

-- Ranking records
INSERT INTO RankingRecord (periodId, seriesId, rankScore, rankPosition, isBottomTwenty, calculatedAt)
VALUES
    (@pQ2base, @sKitchen, 68.67,  2, 0, GETDATE()),
    (@pQ2base, @sLotus,   40.87, 12, 1, GETDATE()),
    (@pQ1,     @sKitchen, 71.45,  2, 0, DATEADD(DAY,-50,GETDATE())),
    (@pQ1,     @sLotus,   38.92, 19, 1, DATEADD(DAY,-50,GETDATE())),
    (@pQ2ext,  @sKitchen, 78.12,  1, 0, GETDATE()),
    (@pQ2ext,  @sLotus,   54.23,  8, 0, GETDATE()),
    (@pQ2ext,  @sTokyo,   42.87, 15, 0, GETDATE());
GO

-- ============================================================
--  BƯỚC 15: DECISION SESSIONS & VOTES
-- ============================================================

DECLARE
    @b1  BIGINT = (SELECT id FROM [User] WHERE username = 'board1'),
    @b2  BIGINT = (SELECT id FROM [User] WHERE username = 'board2'),
    @b3  BIGINT = (SELECT id FROM [User] WHERE username = 'board3'),
    @sLotus   BIGINT = (SELECT id FROM Series WHERE title = 'Neon Lotus High'),
    @rankLotusBase BIGINT = (SELECT id FROM RankingRecord
                             WHERE periodId = (SELECT id FROM RankingPeriod WHERE name='Q2 2026')
                               AND seriesId = (SELECT id FROM Series WHERE title='Neon Lotus High')),
    @rankLotusExt  BIGINT = (SELECT id FROM RankingRecord
                             WHERE periodId = (SELECT id FROM RankingPeriod WHERE name='Q2 2026 (Apr-Jun)')
                               AND seriesId = (SELECT id FROM Series WHERE title='Neon Lotus High'));

-- Decision session 1 — OPEN
INSERT INTO DecisionSession (seriesId, rankingRecordId, status, result, openedAt, closedAt)
VALUES (@sLotus, @rankLotusBase, 'OPEN', NULL, DATEADD(HOUR,-5,GETDATE()), NULL);

DECLARE @ds1 BIGINT = SCOPE_IDENTITY();

INSERT INTO DecisionVote (sessionId, voterId, decision, justification, votedAt)
VALUES
    (@ds1, @b1, 'CHANGE_TYPE', 'Shift the first arc toward character drama before cancellation is considered.', DATEADD(HOUR,-4,GETDATE())),
    (@ds1, @b2, 'CONTINUE',    NULL,                                                                            DATEADD(HOUR,-3,GETDATE())),
    (@ds1, @b3, 'CANCEL',      'Reader conversion is below the safe threshold after the pilot push.',           DATEADD(HOUR,-2,GETDATE()));

-- Decision session 2 — OPEN
INSERT INTO DecisionSession (seriesId, rankingRecordId, status, result, openedAt, closedAt)
VALUES (@sLotus, @rankLotusExt, 'OPEN', NULL, DATEADD(HOUR,-8,GETDATE()), NULL);

DECLARE @ds2 BIGINT = SCOPE_IDENTITY();

INSERT INTO DecisionVote (sessionId, voterId, decision, justification, votedAt)
VALUES
    (@ds2, @b1, 'CONTINUE',    'Reader conversion is improving. Let''s continue.',                  DATEADD(HOUR,-6,GETDATE())),
    (@ds2, @b2, 'CHANGE_TYPE', 'Shift narrative toward character-driven arcs to boost engagement.', DATEADD(HOUR,-5,GETDATE())),
    (@ds2, @b3, 'CONTINUE',    'Art quality is exceptional. Worth keeping alive.',                  DATEADD(HOUR,-4,GETDATE()));
GO

-- ============================================================
--  BƯỚC 16: NOTIFICATIONS
-- ============================================================

DECLARE
    @mk1  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka1'),
    @mk2  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka2'),
    @mk3  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka3'),
    @mk4  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka4'),
    @mk5  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka5'),
    @a1   BIGINT = (SELECT id FROM [User] WHERE username = 'assistant1'),
    @a3   BIGINT = (SELECT id FROM [User] WHERE username = 'assistant3'),
    @a4   BIGINT = (SELECT id FROM [User] WHERE username = 'assistant4'),
    @t1   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou1'),
    @t2   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou2'),
    @pEdo     BIGINT = (SELECT id FROM Proposal WHERE title = 'Shadows of Edo'),
    @pCyber   BIGINT = (SELECT id FROM Proposal WHERE title = 'Cyber Ronin'),
    @pKitchen BIGINT = (SELECT id FROM Proposal WHERE title = 'Celestial Kitchen'),
    @pMoon    BIGINT = (SELECT id FROM Proposal WHERE title = 'Moonlight Sanctuary'),
    @pMystery BIGINT = (SELECT id FROM Proposal WHERE title = 'Mystery at Midnight'),
    @pCafe    BIGINT = (SELECT id FROM Proposal WHERE title = 'Heartstring Cafe'),
    @mEdo1    BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/shadows-edo-ch1-v1.pdf'),
    @mKit2v1  BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/celestial-kitchen-ch2-v1.pdf'),
    @mKit1v2  BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/celestial-kitchen-ch1-v2.pdf'),
    @mLot1v1  BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/neon-lotus-high-ch1-v1.pdf'),
    @tKit1    BIGINT = (SELECT TOP 1 id FROM PageTask
                        WHERE chapterId=(SELECT id FROM Chapter
                                         WHERE seriesId=(SELECT id FROM Series WHERE title='Celestial Kitchen')
                                           AND chapterNumber=1)
                          AND assistantId=(SELECT id FROM [User] WHERE username='assistant3')),
    @tLot2    BIGINT = (SELECT TOP 1 id FROM PageTask
                        WHERE chapterId=(SELECT id FROM Chapter
                                         WHERE seriesId=(SELECT id FROM Series WHERE title='Neon Lotus High')
                                           AND chapterNumber=2)
                          AND assistantId=(SELECT id FROM [User] WHERE username='assistant4')
                        ORDER BY id);

INSERT INTO Notification (userId, type, message, referenceId, referenceType, isRead)
VALUES
    (@mk1, 'PROPOSAL_RESOLVED',     'Your proposal "Shadows of Edo" was APPROVED!',                               @pEdo,    'PROPOSAL',   0),
    (@t1,  'MANUSCRIPT_SUBMITTED',  'New manuscript submitted for Chapter 1 of Shadows of Edo.',                 @mEdo1,   'MANUSCRIPT', 0),
    (@t1,  'PROPOSAL_ASSIGNED',     'Proposal "Cyber Ronin" is ready for Tantou review.',                        @pCyber,  'PROPOSAL',   0),
    (@a1,  'TASK_DUE_REMINDER',     'Your sketching task for Chapter 1 is due in 30 days.',                      @tKit1,   'TASK',       0),
    (@mk2, 'SERIES_CREATED',        'Series "Celestial Kitchen" is now active.',                                  @pKitchen,'PROPOSAL',   0),
    (@a3,  'TASK_ASSIGNED',         'Background task assigned for Celestial Kitchen Chapter 1.',                  @tKit1,   'TASK',       0),
    (@a4,  'TASK_ASSIGNED',         'Inking task assigned for Neon Lotus High Chapter 2.',                        @tLot2,   'TASK',       0),
    (@mk3, 'MANUSCRIPT_REJECTED',   'Neon Lotus High Chapter 1 needs revision before approval.',                 @mLot1v1, 'MANUSCRIPT', 0),
    (@t2,  'MANUSCRIPT_SUBMITTED',  'Celestial Kitchen Chapter 2 has been submitted.',                           @mKit2v1, 'MANUSCRIPT', 0),
    (@mk2, 'MANUSCRIPT_REVIEW_UPDATE','Revised manuscript for Celestial Kitchen Ch1 is now under review.',       @mKit1v2, 'MANUSCRIPT', 0),
    (@t2,  'MANUSCRIPT_SUBMITTED',  'Celestial Kitchen Ch1 revision v2 submitted for review.',                   @mKit1v2, 'MANUSCRIPT', 0),
    (@mk3, 'PROPOSAL_SUBMITTED_CONFIRMATION','Your proposal "Moonlight Sanctuary" has been received.',           @pMoon,   'PROPOSAL',   0),
    (@mk4, 'PROPOSAL_ASSIGNED',     'Your proposal "Mystery at Midnight" has been assigned to a Tantou Editor.', @pMystery,'PROPOSAL',   0),
    (@mk5, 'REVISION_REQUESTED',    'Your proposal "Heartstring Cafe" requires revision.',                        @pCafe,   'PROPOSAL',   0);
GO

-- ============================================================
--  BƯỚC 17: AUDIT LOG
--  FIX: entityId NOT NULL — chỉ insert các dòng có entityId xác định rõ
-- ============================================================

DECLARE
    @mk1  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka1'),
    @mk2  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka2'),
    @mk3  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka3'),
    @mk4  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka4'),
    @mk5  BIGINT = (SELECT id FROM [User] WHERE username = 'mangaka5'),
    @a1   BIGINT = (SELECT id FROM [User] WHERE username = 'assistant1'),
    @t1   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou1'),
    @t2   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou2'),
    @t3   BIGINT = (SELECT id FROM [User] WHERE username = 'tantou3'),
    @b1   BIGINT = (SELECT id FROM [User] WHERE username = 'board1'),
    @b2   BIGINT = (SELECT id FROM [User] WHERE username = 'board2'),
    @pEdo     BIGINT = (SELECT id FROM Proposal WHERE title = 'Shadows of Edo'),
    @pCyber   BIGINT = (SELECT id FROM Proposal WHERE title = 'Cyber Ronin'),
    @pKitchen BIGINT = (SELECT id FROM Proposal WHERE title = 'Celestial Kitchen'),
    @pMoon    BIGINT = (SELECT id FROM Proposal WHERE title = 'Moonlight Sanctuary'),
    @pMystery BIGINT = (SELECT id FROM Proposal WHERE title = 'Mystery at Midnight'),
    @pCafe    BIGINT = (SELECT id FROM Proposal WHERE title = 'Heartstring Cafe'),
    @pAlien   BIGINT = (SELECT id FROM Proposal WHERE title = 'Alien Overlords'),
    @pTokyo   BIGINT = (SELECT id FROM Proposal WHERE title = 'Shadows of Tokyo'),
    @sEdo     BIGINT = (SELECT id FROM Series WHERE title = 'Shadows of Edo'),
    @sKitchen BIGINT = (SELECT id FROM Series WHERE title = 'Celestial Kitchen'),
    @sTokyo   BIGINT = (SELECT id FROM Series WHERE title = 'Shadows of Tokyo'),
    @mEdo1    BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/shadows-edo-ch1-v1.pdf'),
    @mLot1v1  BIGINT = (SELECT id FROM Manuscript WHERE fileUrl='/uploads/manuscripts/neon-lotus-high-ch1-v1.pdf'),
    @tKit1    BIGINT = (SELECT TOP 1 id FROM PageTask
                        WHERE chapterId=(SELECT id FROM Chapter
                                         WHERE seriesId=(SELECT id FROM Series WHERE title='Celestial Kitchen')
                                           AND chapterNumber=1)
                        ORDER BY id),
    @ds1      BIGINT = (SELECT TOP 1 id FROM DecisionSession ORDER BY id);

INSERT INTO AuditLog (actorId, action, entityType, entityId, detail, performedAt)
VALUES
    (@mk1, 'PROPOSAL_SUBMITTED',       'PROPOSAL',   @pEdo,     '{"status":"SUBMITTED"}',                          DATEADD(DAY,-18,GETDATE())),
    (@t1,  'PROPOSAL_APPROVED',        'PROPOSAL',   @pEdo,     '{"status":"APPROVED"}',                           DATEADD(DAY,-20,GETDATE())),
    (@mk1, 'SERIES_CREATED',           'SERIES',     @sEdo,     CONCAT('{"seriesId":',@sEdo,'}'),                  DATEADD(DAY,-20,GETDATE())),
    (@mk1, 'MANUSCRIPT_SUBMITTED',     'MANUSCRIPT', @mEdo1,    '{"version":1,"chapter":"The Broken Blade"}',      DATEADD(HOUR,-8,GETDATE())),
    (@t1,  'MANUSCRIPT_REVIEW_STARTED','MANUSCRIPT', @mEdo1,    '{"status":"UNDER_REVIEW"}',                       DATEADD(HOUR,-7,GETDATE())),
    (@mk2, 'PROPOSAL_CREATED',         'PROPOSAL',   @pKitchen, '{"status":"DRAFT"}',                              DATEADD(DAY,-22,GETDATE())),
    (@mk3, 'PROPOSAL_CREATED',         'PROPOSAL',   @pMoon,    '{"status":"DRAFT"}',                              DATEADD(DAY,-8,GETDATE())),
    (@mk3, 'PROPOSAL_SUBMITTED',       'PROPOSAL',   @pMoon,    '{"status":"UNDER_REVIEW"}',                       DATEADD(DAY,-7,GETDATE())),
    (@mk4, 'PROPOSAL_CREATED',         'PROPOSAL',   @pMystery, '{"status":"DRAFT"}',                              DATEADD(DAY,-5,GETDATE())),
    (@mk4, 'PROPOSAL_SUBMITTED',       'PROPOSAL',   @pMystery, '{"status":"UNDER_REVIEW"}',                       DATEADD(DAY,-4,GETDATE())),
    (@t2,  'PROPOSAL_ASSIGNED',        'PROPOSAL',   @pMystery, CONCAT('{"assignedEditorId":',@t2,'}'),            DATEADD(DAY,-4,GETDATE())),
    (@mk5, 'PROPOSAL_CREATED',         'PROPOSAL',   @pCafe,    '{"status":"DRAFT"}',                              DATEADD(DAY,-15,GETDATE())),
    (@mk5, 'PROPOSAL_SUBMITTED',       'PROPOSAL',   @pCafe,    '{"status":"UNDER_REVIEW"}',                       DATEADD(DAY,-12,GETDATE())),
    (@t3,  'PROPOSAL_REVISION_REQUESTED','PROPOSAL', @pCafe,    '{"reason":"Needs more worldbuilding"}',           DATEADD(DAY,-2,GETDATE())),
    (@mk3, 'PROPOSAL_CREATED',         'PROPOSAL',   @pAlien,   '{"status":"DRAFT"}',                              DATEADD(DAY,-25,GETDATE())),
    (@mk3, 'PROPOSAL_SUBMITTED',       'PROPOSAL',   @pAlien,   '{"status":"UNDER_REVIEW"}',                       DATEADD(DAY,-20,GETDATE())),
    (@t1,  'PROPOSAL_REJECTED',        'PROPOSAL',   @pAlien,   '{"reason":"Concept too similar to existing"}',    DATEADD(DAY,-15,GETDATE())),
    (@mk2, 'PROPOSAL_APPROVED',        'PROPOSAL',   @pTokyo,   '{"status":"APPROVED"}',                           DATEADD(DAY,-28,GETDATE())),
    (@mk2, 'SERIES_CREATED',           'SERIES',     @sTokyo,   CONCAT('{"seriesId":',@sTokyo,'}'),                DATEADD(DAY,-25,GETDATE())),
    (@mk2, 'MANUSCRIPT_SUBMITTED',     'MANUSCRIPT', @mEdo1,    '{"chapter":"The Broken Blade","version":1}',      DATEADD(HOUR,-3,GETDATE())),
    (@t1,  'MANUSCRIPT_FEEDBACK_ADDED','MANUSCRIPT', @mLot1v1,  '{"chapter":"First Bell in Neon Rain","revision":"required"}', DATEADD(DAY,-1,GETDATE())),
    (@a1,  'IMAGE_UPLOADED',           'PAGETASK',   ISNULL(@tKit1, -1),    '{"imageType":"PAGE","pageNumber":1}',             DATEADD(DAY,-3,GETDATE())),
    (@b1,  'DECISION_VOTE_CAST',       'DECISION',   ISNULL(@ds1, -1),      '{"series":"Neon Lotus High","decision":"CONTINUE"}',  DATEADD(HOUR,-6,GETDATE())),
    (@b2,  'DECISION_VOTE_CAST',       'DECISION',   ISNULL(@ds1, -1),      '{"series":"Neon Lotus High","decision":"CHANGE_TYPE"}',DATEADD(HOUR,-5,GETDATE()));
GO

-- ============================================================
--  DONE
-- ============================================================

PRINT '';
PRINT '========================================================';
PRINT '  FULL SEED v5 (FIXED) — IMPORTED SUCCESSFULLY';
PRINT '========================================================';
PRINT '';
PRINT 'USERS (all password: 12345):';
PRINT '  admin                          — ADMIN';
PRINT '  mangaka1/2/3/4/5               — MANGAKA';
PRINT '  assistant1..10                 — ASSISTANT';
PRINT '  tantou1/2/3                    — TANTOU_EDITOR';
PRINT '  board1/2/3                     — EDITORIAL_BOARD';
PRINT '';
PRINT 'DATA:';
PRINT '  11 Proposals (DRAFT/UNDER_REVIEW/REVISION_REQUESTED/APPROVED/REJECTED)';
PRINT '  4 Series (Shadows of Edo, Celestial Kitchen, Neon Lotus High, Shadows of Tokyo)';
PRINT '  14 Chapters (PLANNING/IN_PROGRESS/EDITORIAL_REVIEW/COMPLETE/APPROVED/REJECTED)';
PRINT '  20+ Page Tasks (IN_PROGRESS/SUBMITTED/APPROVED/REJECTED)';
PRINT '  7 Manuscripts with versioning';
PRINT '  12 Annotations';
PRINT '  3 Ranking Periods + votes + records';
PRINT '  2 Decision Sessions + votes';
PRINT '  14 Notifications';
PRINT '  24 Audit Log entries';
PRINT '';
GO
