package manga.model;

import java.sql.Timestamp;

public class Proposal {
    private long id;
    private long mangakaId;
    private String title;
    private String genre;
    private String synopsis;
    private String status;
    private Timestamp submittedAt;
    private Timestamp votingDeadline;
    private Timestamp rejectedAt;
    private Long assignedEditorId;
    private int approveVotes;
    private int rejectVotes;
    private int abstainVotes;

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getMangakaId() {
        return mangakaId;
    }

    public void setMangakaId(long mangakaId) {
        this.mangakaId = mangakaId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getGenre() {
        return genre;
    }

    public void setGenre(String genre) {
        this.genre = genre;
    }

    public String getSynopsis() {
        return synopsis;
    }

    public void setSynopsis(String synopsis) {
        this.synopsis = synopsis;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Timestamp getSubmittedAt() {
        return submittedAt;
    }

    public void setSubmittedAt(Timestamp submittedAt) {
        this.submittedAt = submittedAt;
    }

    public Timestamp getVotingDeadline() {
        return votingDeadline;
    }

    public void setVotingDeadline(Timestamp votingDeadline) {
        this.votingDeadline = votingDeadline;
    }

    public Timestamp getRejectedAt() {
        return rejectedAt;
    }

    public void setRejectedAt(Timestamp rejectedAt) {
        this.rejectedAt = rejectedAt;
    }

    public Long getAssignedEditorId() {
        return assignedEditorId;
    }

    public void setAssignedEditorId(Long assignedEditorId) {
        this.assignedEditorId = assignedEditorId;
    }

    public int getApproveVotes() {
        return approveVotes;
    }

    public void setApproveVotes(int approveVotes) {
        this.approveVotes = approveVotes;
    }

    public int getRejectVotes() {
        return rejectVotes;
    }

    public void setRejectVotes(int rejectVotes) {
        this.rejectVotes = rejectVotes;
    }

    public int getAbstainVotes() {
        return abstainVotes;
    }

    public void setAbstainVotes(int abstainVotes) {
        this.abstainVotes = abstainVotes;
    }
}

