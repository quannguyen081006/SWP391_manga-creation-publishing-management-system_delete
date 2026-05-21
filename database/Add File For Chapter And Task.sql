-- ============================================================
--  MIGRATION: Add Chapter Image support
--  Gắn ảnh vào PageTask (output của Assistant) và Chapter
--  Không thay đổi bất kỳ bảng nào đã tồn tại.
-- ============================================================

USE MangaEditorialDB;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
SET XACT_ABORT ON;
GO

BEGIN TRAN;

-- ============================================================
--  TABLE: ChapterImage
--  Mỗi row = 1 file ảnh do Assistant upload cho 1 PageTask.
--  pageTaskId: gắn vào task cụ thể (nullable để cover edge case
--              Mangaka upload ảnh cover/reference không thuộc task nào).
--  uploadedBy: ai upload (thường là assistantId, có thể là mangakaId).
--  imageType:  PAGE (trang truyện) | COVER (bìa chapter) | REFERENCE (tham khảo)
--  pageNumber: số trang trong chapter, NULL nếu không phải PAGE.
--  isActive:   soft-delete, chỉ version mới nhất = 1 cho cùng (chapterId, pageNumber).
-- ============================================================

IF OBJECT_ID('ChapterImage', 'U') IS NULL
CREATE TABLE ChapterImage (
    id              BIGINT          NOT NULL IDENTITY(1,1),
    chapterId       BIGINT          NOT NULL,
    pageTaskId      BIGINT              NULL,   -- NULL = không thuộc task cụ thể (ảnh cover/ref)
    uploadedBy      BIGINT          NOT NULL,
    imageType       VARCHAR(20)     NOT NULL CONSTRAINT DF_ChapterImage_imageType  DEFAULT 'PAGE',
    pageNumber      INT                 NULL,   -- NULL nếu imageType != 'PAGE'
    fileUrl         VARCHAR(512)    NOT NULL,
    originalFileName NVARCHAR(255)  NOT NULL,
    fileSizeBytes   BIGINT              NULL,
    uploadedAt      DATETIME        NOT NULL CONSTRAINT DF_ChapterImage_uploadedAt DEFAULT GETDATE(),
    isActive        BIT             NOT NULL CONSTRAINT DF_ChapterImage_isActive   DEFAULT 1,
    note            NVARCHAR(500)       NULL,   -- Mangaka ghi chú khi reject/yêu cầu sửa

    CONSTRAINT PK_ChapterImage              PRIMARY KEY (id),
    CONSTRAINT FK_CI_Chapter                FOREIGN KEY (chapterId)  REFERENCES Chapter(id),
    CONSTRAINT FK_CI_PageTask               FOREIGN KEY (pageTaskId) REFERENCES PageTask(id),
    CONSTRAINT FK_CI_UploadedBy             FOREIGN KEY (uploadedBy) REFERENCES [User](id),
    CONSTRAINT CK_CI_imageType              CHECK (imageType IN ('PAGE', 'COVER', 'REFERENCE')),
    CONSTRAINT CK_CI_pageNumber             CHECK (pageNumber IS NULL OR pageNumber >= 1),
    CONSTRAINT CK_CI_fileSizeBytes          CHECK (fileSizeBytes IS NULL OR fileSizeBytes > 0)
);
GO

-- Performance: tra cứu ảnh theo chapter (view gallery)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChapterImage_chapterId' AND object_id = OBJECT_ID('ChapterImage'))
    CREATE INDEX IX_ChapterImage_chapterId
    ON ChapterImage (chapterId, isActive, pageNumber);
GO

-- Performance: tra cứu ảnh theo task (Assistant xem lại submission)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChapterImage_pageTaskId' AND object_id = OBJECT_ID('ChapterImage'))
    CREATE INDEX IX_ChapterImage_pageTaskId
    ON ChapterImage (pageTaskId)
    WHERE pageTaskId IS NOT NULL;
GO

-- Performance: tra cứu ảnh do 1 user upload
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChapterImage_uploadedBy' AND object_id = OBJECT_ID('ChapterImage'))
    CREATE INDEX IX_ChapterImage_uploadedBy
    ON ChapterImage (uploadedBy, uploadedAt);
GO

-- ============================================================
--  UPDATE: Notification referenceType — thêm 'IMAGE' nếu cần
--  (không bắt buộc, chỉ nếu muốn notify khi ảnh bị reject)
-- ============================================================

-- Nếu muốn gửi notification khi Mangaka reject ảnh cụ thể,
-- drop và recreate constraint CK_Notification_refType để thêm 'IMAGE'.
-- Uncomment block dưới nếu cần:

/*
ALTER TABLE Notification DROP CONSTRAINT CK_Notification_refType;
ALTER TABLE Notification ADD CONSTRAINT CK_Notification_refType
    CHECK (referenceType IS NULL OR referenceType IN (
        'PROPOSAL','CHAPTER','TASK','MANUSCRIPT','DECISION','IMAGE'));
*/

-- ============================================================
--  UPDATE: AuditLog entityType — thêm 'IMAGE' để track upload/delete
-- ============================================================

ALTER TABLE AuditLog DROP CONSTRAINT CK_AuditLog_entityType;
ALTER TABLE AuditLog ADD CONSTRAINT CK_AuditLog_entityType
    CHECK (entityType IN (
        'PROPOSAL','CHAPTER','TASK','MANUSCRIPT','DECISION','USER','IMAGE'));
GO

COMMIT;
GO

PRINT 'Migration V2 completed: ChapterImage table created.';
GO