package manga.repository;

import manga.model.PageSlotSummary;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

@Repository
public class PageRepository {

    private static final String TABLE_PAGE = "[dbo].[Page]";

    private volatile Boolean pageTableReady;

    @Autowired
    private DataSource dataSource;

    private void requirePageTableReady() {
        if (!isPageTableReady()) {
            throw new IllegalArgumentException(
                    "Bảng Page chưa có. Chạy database/migration_add_page_table.sql trên MangaEditorialDB trước.");
        }
    }

    private boolean isPageTableReady() {
        if (pageTableReady != null) {
            return pageTableReady.booleanValue();
        }
        synchronized (this) {
            if (pageTableReady != null) {
                return pageTableReady.booleanValue();
            }
            boolean ready = false;
            String sql = "SELECT CASE WHEN OBJECT_ID('dbo.Page', 'U') IS NOT NULL THEN 1 ELSE 0 END";
            try (Connection conn = dataSource.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    ready = rs.getInt(1) == 1;
                }
            } catch (SQLException ex) {
                ready = false;
            }
            pageTableReady = Boolean.valueOf(ready);
            return ready;
        }
    }

    private static final String LIST_SQL =
            "SELECT p.id, p.chapterId, p.pageNumber, p.imageUrl, p.uploadedBy, p.uploadedAt, p.status, "
            + "t.id AS taskId, t.taskType, t.status AS taskStatus, t.assistantId, u.fullName AS assistantName "
            + "FROM " + TABLE_PAGE + " p "
            + "OUTER APPLY ( "
            + "  SELECT TOP 1 pt.id, pt.taskType, pt.status, pt.assistantId "
            + "  FROM PageTask pt "
            + "  WHERE pt.chapterId = p.chapterId "
            + "    AND p.pageNumber BETWEEN pt.pageRangeStart AND pt.pageRangeEnd "
            + "  ORDER BY pt.updatedAt DESC "
            + ") t "
            + "LEFT JOIN [User] u ON u.id = t.assistantId "
            + "WHERE p.chapterId = ? "
            + "ORDER BY p.pageNumber";

    public List<PageSlotSummary> listByChapter(long chapterId) {
        if (!isPageTableReady()) {
            return new ArrayList<PageSlotSummary>();
        }
        List<PageSlotSummary> rows = new ArrayList<PageSlotSummary>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(LIST_SQL)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(map(rs));
                }
            }
        } catch (SQLException ex) {
            if (isMissingPageTable(ex)) {
                pageTableReady = Boolean.FALSE;
                return new ArrayList<PageSlotSummary>();
            }
            throw new RuntimeException("Cannot list chapter pages", ex);
        }
        return rows;
    }

    public long create(long chapterId, int pageNumber) {
        requirePageTableReady();
        String sql = "INSERT INTO " + TABLE_PAGE + " (chapterId, pageNumber, status, createdAt) VALUES (?, ?, 'EMPTY', GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, chapterId);
            ps.setInt(2, pageNumber);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getLong(1);
                }
            }
            throw new IllegalStateException("Cannot create page slot");
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create page slot", ex);
        }
    }

    public void bulkCreate(long chapterId, int totalPages) {
        try (Connection conn = dataSource.getConnection()) {
            bulkCreate(conn, chapterId, totalPages);
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot bulk create page slots", ex);
        }
    }

    public void bulkCreate(Connection conn, long chapterId, int totalPages) throws SQLException {
        if (totalPages < 1) {
            return;
        }
        if (!isPageTableReady()) {
            return;
        }
        String sql = "INSERT INTO " + TABLE_PAGE + " (chapterId, pageNumber, status, createdAt) VALUES (?, ?, 'EMPTY', GETDATE())";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 1; i <= totalPages; i++) {
                ps.setLong(1, chapterId);
                ps.setInt(2, i);
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    public int countByChapter(long chapterId) {
        if (!isPageTableReady()) {
            return 0;
        }
        String sql = "SELECT COUNT(1) FROM " + TABLE_PAGE + " WHERE chapterId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot count pages", ex);
        }
    }

    public int countUploaded(long chapterId) {
        if (!isPageTableReady()) {
            return 0;
        }
        String sql = "SELECT COUNT(1) FROM " + TABLE_PAGE + " WHERE chapterId = ? AND status = 'UPLOADED'";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot count uploaded pages", ex);
        }
    }

    public PageSlotSummary findById(long pageId) {
        if (!isPageTableReady()) {
            return null;
        }
        String sql = "SELECT id, chapterId, pageNumber, imageUrl, uploadedBy, uploadedAt, status "
                + "FROM " + TABLE_PAGE + " WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, pageId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                PageSlotSummary slot = new PageSlotSummary();
                slot.setId(rs.getLong("id"));
                slot.setChapterId(rs.getLong("chapterId"));
                slot.setPageNumber(rs.getInt("pageNumber"));
                slot.setImageUrl(rs.getString("imageUrl"));
                long uploadedBy = rs.getLong("uploadedBy");
                slot.setUploadedBy(rs.wasNull() ? null : Long.valueOf(uploadedBy));
                slot.setUploadedAt(rs.getTimestamp("uploadedAt"));
                slot.setStatus(rs.getString("status"));
                return slot;
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load page", ex);
        }
    }

    public void markUploaded(long pageId, String imageUrl, long uploadedBy) {
        requirePageTableReady();
        String sql = "UPDATE " + TABLE_PAGE + " SET imageUrl = ?, uploadedBy = ?, uploadedAt = GETDATE(), status = 'UPLOADED' WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, imageUrl);
            ps.setLong(2, uploadedBy);
            ps.setLong(3, pageId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Page not found");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update page image", ex);
        }
    }

    public int nextPageNumber(long chapterId) {
        requirePageTableReady();
        String sql = "SELECT ISNULL(MAX(pageNumber), 0) + 1 FROM " + TABLE_PAGE + " WHERE chapterId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 1;
            }
        } catch (SQLException ex) {
            if (isMissingPageTable(ex)) {
                pageTableReady = Boolean.FALSE;
                throw new IllegalArgumentException(
                        "Bảng Page chưa có. Chạy database/migration_add_page_table.sql trên MangaEditorialDB trước.");
            }
            throw new RuntimeException("Cannot resolve next page number", ex);
        }
    }

    private boolean isMissingPageTable(Throwable ex) {
        while (ex != null) {
            String msg = ex.getMessage();
            if (msg != null) {
                String lower = msg.toLowerCase();
                if (lower.contains("invalid object name") && lower.contains("page")) {
                    return true;
                }
            }
            ex = ex.getCause();
        }
        return false;
    }

    public List<PageSlotSummary> listEmptySlots(long chapterId, int limit) {
        if (!isPageTableReady()) {
            return new ArrayList<PageSlotSummary>();
        }
        String sql = "SELECT TOP (?) id, chapterId, pageNumber, imageUrl, uploadedBy, uploadedAt, status "
                + "FROM " + TABLE_PAGE + " WHERE chapterId = ? AND status = 'EMPTY' ORDER BY pageNumber";
        List<PageSlotSummary> rows = new ArrayList<PageSlotSummary>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setLong(2, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    PageSlotSummary slot = new PageSlotSummary();
                    slot.setId(rs.getLong("id"));
                    slot.setChapterId(rs.getLong("chapterId"));
                    slot.setPageNumber(rs.getInt("pageNumber"));
                    slot.setStatus(rs.getString("status"));
                    rows.add(slot);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list empty page slots", ex);
        }
        return rows;
    }

    private PageSlotSummary map(ResultSet rs) throws SQLException {
        PageSlotSummary slot = new PageSlotSummary();
        slot.setId(rs.getLong("id"));
        slot.setChapterId(rs.getLong("chapterId"));
        slot.setPageNumber(rs.getInt("pageNumber"));
        slot.setImageUrl(rs.getString("imageUrl"));
        long uploadedBy = rs.getLong("uploadedBy");
        slot.setUploadedBy(rs.wasNull() ? null : Long.valueOf(uploadedBy));
        slot.setUploadedAt(rs.getTimestamp("uploadedAt"));
        slot.setStatus(rs.getString("status"));
        long taskId = rs.getLong("taskId");
        slot.setTaskId(rs.wasNull() ? null : Long.valueOf(taskId));
        slot.setTaskType(rs.getString("taskType"));
        slot.setTaskStatus(rs.getString("taskStatus"));
        long assistantId = rs.getLong("assistantId");
        slot.setAssistantId(rs.wasNull() ? null : Long.valueOf(assistantId));
        slot.setAssistantName(rs.getString("assistantName"));
        return slot;
    }
}
