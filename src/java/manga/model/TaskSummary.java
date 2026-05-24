package manga.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import java.sql.Date;

public class TaskSummary {
    private long id;
    private long chapterId;
    private long assistantId;
    private int pageRangeStart;
    private int pageRangeEnd;
    private String taskType;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    private Date dueDate;
    private String status;
    private int rejectionCount;
    private String chapterTitle;
    private Integer chapterNumber;
    private String seriesTitle;
    private String assistantName;
    private boolean delayed;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public long getChapterId() { return chapterId; }
    public void setChapterId(long chapterId) { this.chapterId = chapterId; }
    public long getAssistantId() { return assistantId; }
    public void setAssistantId(long assistantId) { this.assistantId = assistantId; }
    public int getPageRangeStart() { return pageRangeStart; }
    public void setPageRangeStart(int pageRangeStart) { this.pageRangeStart = pageRangeStart; }
    public int getPageRangeEnd() { return pageRangeEnd; }
    public void setPageRangeEnd(int pageRangeEnd) { this.pageRangeEnd = pageRangeEnd; }
    public String getTaskType() { return taskType; }
    public void setTaskType(String taskType) { this.taskType = taskType; }
    public Date getDueDate() { return dueDate; }
    public void setDueDate(Date dueDate) { this.dueDate = dueDate; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public int getRejectionCount() { return rejectionCount; }
    public void setRejectionCount(int rejectionCount) { this.rejectionCount = rejectionCount; }
    public String getChapterTitle() { return chapterTitle; }
    public void setChapterTitle(String chapterTitle) { this.chapterTitle = chapterTitle; }
    public Integer getChapterNumber() { return chapterNumber; }
    public void setChapterNumber(Integer chapterNumber) { this.chapterNumber = chapterNumber; }
    public String getSeriesTitle() { return seriesTitle; }
    public void setSeriesTitle(String seriesTitle) { this.seriesTitle = seriesTitle; }
    public String getAssistantName() { return assistantName; }
    public void setAssistantName(String assistantName) { this.assistantName = assistantName; }
    public boolean isDelayed() { return delayed; }
    public void setDelayed(boolean delayed) { this.delayed = delayed; }
}
