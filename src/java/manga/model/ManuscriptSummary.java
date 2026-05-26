package manga.model;

import java.sql.Timestamp;

public class ManuscriptSummary {
    private long id;
    private long chapterId;
    private int version;
    private String status;
    private Timestamp submittedAt;
    private Timestamp reviewDeadline;
    private String fileUrl;
    private Timestamp revisionDeadline;
    private String feedback;
    private String seriesTitle;
    private String chapterTitle;
    private Integer chapterNumber;
    private String synopsis;
    private String mangakaName;
    private String reviewerName;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public long getChapterId() { return chapterId; }
    public void setChapterId(long chapterId) { this.chapterId = chapterId; }
    public int getVersion() { return version; }
    public void setVersion(int version) { this.version = version; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Timestamp getSubmittedAt() { return submittedAt; }
    public void setSubmittedAt(Timestamp submittedAt) { this.submittedAt = submittedAt; }
    public Timestamp getReviewDeadline() { return reviewDeadline; }
    public void setReviewDeadline(Timestamp reviewDeadline) { this.reviewDeadline = reviewDeadline; }
    public String getFileUrl() { return fileUrl; }
    public void setFileUrl(String fileUrl) { this.fileUrl = fileUrl; }
    public Timestamp getRevisionDeadline() { return revisionDeadline; }
    public void setRevisionDeadline(Timestamp revisionDeadline) { this.revisionDeadline = revisionDeadline; }
    public String getFeedback() { return feedback; }
    public void setFeedback(String feedback) { this.feedback = feedback; }
    public String getSeriesTitle() { return seriesTitle; }
    public void setSeriesTitle(String seriesTitle) { this.seriesTitle = seriesTitle; }
    public String getChapterTitle() { return chapterTitle; }
    public void setChapterTitle(String chapterTitle) { this.chapterTitle = chapterTitle; }
    public Integer getChapterNumber() { return chapterNumber; }
    public void setChapterNumber(Integer chapterNumber) { this.chapterNumber = chapterNumber; }
    public String getSynopsis() { return synopsis; }
    public void setSynopsis(String synopsis) { this.synopsis = synopsis; }
    public String getMangakaName() { return mangakaName; }
    public void setMangakaName(String mangakaName) { this.mangakaName = mangakaName; }
    public String getReviewerName() { return reviewerName; }
    public void setReviewerName(String reviewerName) { this.reviewerName = reviewerName; }
}
