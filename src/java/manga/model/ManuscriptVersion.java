package manga.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import manga.enums.ManuscriptStatus;

/**
 * ManuscriptVersion entity - Aggregate root for the manuscript workspace.
 * 
 * Represents a versioned manuscript workspace with immutable page snapshots.
 * Each version stores its own pages and annotations, supporting v1 → v2 → v3 chains.
 * 
 * Business Rules:
 * - BR-1: Only chapters in EDITORIAL_REVIEW can create manuscripts
 * - BR-2: Only one UNDER_REVIEW per chapter
 * - BR-3: REJECTED manuscripts cannot be mutated
 * - BR-4: APPROVED manuscripts cannot be mutated
 */
public class ManuscriptVersion {
    private Long id;
    private Long chapterId;
    private Integer version;
    private Long previousVersionId;
    private ManuscriptStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime submittedAt;
    private LocalDateTime approvedAt;
    private LocalDateTime rejectedAt;
    private LocalDateTime publishedAt;
    private Long createdBy;
    private Long submittedBy;
    private Long approvedBy;
    private Long rejectedBy;
    private String feedback;
    private String revisionNotes;
    private Integer totalPageCount;
    
    // Child entities
    private List<ManuscriptPage> pages = new ArrayList<>();
    private List<Annotation> annotations = new ArrayList<>();
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Long getChapterId() {
        return chapterId;
    }
    
    public void setChapterId(Long chapterId) {
        this.chapterId = chapterId;
    }
    
    public Integer getVersion() {
        return version;
    }
    
    public void setVersion(Integer version) {
        this.version = version;
    }
    
    public Long getPreviousVersionId() {
        return previousVersionId;
    }
    
    public void setPreviousVersionId(Long previousVersionId) {
        this.previousVersionId = previousVersionId;
    }
    
    public ManuscriptStatus getStatus() {
        return status;
    }
    
    public void setStatus(ManuscriptStatus status) {
        this.status = status;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getSubmittedAt() {
        return submittedAt;
    }
    
    public void setSubmittedAt(LocalDateTime submittedAt) {
        this.submittedAt = submittedAt;
    }
    
    public LocalDateTime getApprovedAt() {
        return approvedAt;
    }
    
    public void setApprovedAt(LocalDateTime approvedAt) {
        this.approvedAt = approvedAt;
    }
    
    public LocalDateTime getRejectedAt() {
        return rejectedAt;
    }
    
    public void setRejectedAt(LocalDateTime rejectedAt) {
        this.rejectedAt = rejectedAt;
    }
    
    public LocalDateTime getPublishedAt() {
        return publishedAt;
    }
    
    public void setPublishedAt(LocalDateTime publishedAt) {
        this.publishedAt = publishedAt;
    }
    
    public Long getCreatedBy() {
        return createdBy;
    }
    
    public void setCreatedBy(Long createdBy) {
        this.createdBy = createdBy;
    }
    
    public Long getSubmittedBy() {
        return submittedBy;
    }
    
    public void setSubmittedBy(Long submittedBy) {
        this.submittedBy = submittedBy;
    }
    
    public Long getApprovedBy() {
        return approvedBy;
    }
    
    public void setApprovedBy(Long approvedBy) {
        this.approvedBy = approvedBy;
    }
    
    public Long getRejectedBy() {
        return rejectedBy;
    }
    
    public void setRejectedBy(Long rejectedBy) {
        this.rejectedBy = rejectedBy;
    }
    
    public String getFeedback() {
        return feedback;
    }
    
    public void setFeedback(String feedback) {
        this.feedback = feedback;
    }
    
    public String getRevisionNotes() {
        return revisionNotes;
    }
    
    public void setRevisionNotes(String revisionNotes) {
        this.revisionNotes = revisionNotes;
    }
    
    public Integer getTotalPageCount() {
        return totalPageCount;
    }
    
    public void setTotalPageCount(Integer totalPageCount) {
        this.totalPageCount = totalPageCount;
    }
    
    public List<ManuscriptPage> getPages() {
        return pages;
    }
    
    public void setPages(List<ManuscriptPage> pages) {
        this.pages = pages;
    }
    
    public List<Annotation> getAnnotations() {
        return annotations;
    }
    
    public void setAnnotations(List<Annotation> annotations) {
        this.annotations = annotations;
    }
    
    // Business rule validation methods
    
    /**
     * Check if this manuscript version can be edited.
     * BR-3: REJECTED cannot be mutated
     * BR-4: APPROVED cannot be mutated
     */
    public boolean canEdit() {
        return status == ManuscriptStatus.DRAFT;
    }
    
    /**
     * Check if this manuscript version can be submitted for review.
     */
    public boolean canSubmit() {
        return status == ManuscriptStatus.DRAFT && !pages.isEmpty();
    }
    
    /**
     * Check if this manuscript version can be approved.
     */
    public boolean canApprove() {
        return status == ManuscriptStatus.UNDER_REVIEW;
    }
    
    /**
     * Check if this manuscript version can be rejected.
     */
    public boolean canReject() {
        return status == ManuscriptStatus.UNDER_REVIEW;
    }
    
    /**
     * Check if this is the latest version for the chapter.
     * This would be validated at the service/repository level.
     */
    public boolean isLatestVersion() {
        // This would be checked by querying the repository
        return true; // Placeholder
    }
    
    /**
     * Check if this version can generate the next version.
     * Only the current (latest) version can generate next version.
     */
    public boolean canGenerateNextVersion() {
        // This would be checked by querying the repository
        return true; // Placeholder - service layer enforces this
    }
    
    /**
     * Check if this manuscript version is immutable.
     * Returns true for APPROVED, PUBLISHED, REJECTED, ARCHIVED statuses.
     */
    public boolean isImmutable() {
        return status == ManuscriptStatus.APPROVED || 
               status == ManuscriptStatus.PUBLISHED ||
               status == ManuscriptStatus.REJECTED || 
               status == ManuscriptStatus.ARCHIVED;
    }
    
    /**
     * Validate that this manuscript can be edited.
     * Throws exception if immutable.
     */
    public void validateEditable() {
        if (isImmutable()) {
            throw new IllegalStateException(
                "Manuscript version " + version + " is " + status + " and cannot be edited"
            );
        }
    }
    
    /**
     * Check if this manuscript version can be published.
     */
    public boolean canPublish() {
        return status == ManuscriptStatus.APPROVED;
    }
}
