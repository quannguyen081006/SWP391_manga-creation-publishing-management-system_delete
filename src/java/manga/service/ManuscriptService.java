package manga.service;

import manga.common.exception.BusinessRuleException;
import manga.dto.ApproveManuscriptRequest;
import manga.dto.RejectManuscriptRequest;
import manga.dto.SubmitManuscriptRequest;
import manga.enums.ChapterStatus;
import manga.enums.ManuscriptStatus;
import manga.model.AuthenticatedUser;
import manga.model.ManuscriptSummary;
import manga.repository.ChapterRepository;
import manga.repository.ManuscriptRepository;
import manga.repository.PageTaskRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Timestamp;
import java.util.List;
import java.util.Calendar;

@Service
public class ManuscriptService {

    @Autowired
    private ManuscriptRepository manuscriptRepository;

    @Autowired
    private ChapterRepository chapterRepository;

    @Autowired
    private PageTaskRepository pageTaskRepository;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private AuditLogService auditLogService;

    @Transactional
    public ManuscriptSummary submitManuscript(long chapterId, SubmitManuscriptRequest request, AuthenticatedUser user) {
        ManuscriptSummary manuscript = createDraft(chapterId, request, user);
        submitDraft(manuscript.getId(), user);
        return manuscriptRepository.findById(manuscript.getId());
    }

    @Transactional
    public ManuscriptSummary createDraft(long chapterId, String fileUrl, AuthenticatedUser user) {
        SubmitManuscriptRequest request = new SubmitManuscriptRequest();
        request.setFileUrl(fileUrl);
        return createDraft(chapterId, request, user);
    }

    @Transactional
    public ManuscriptSummary createDraft(long chapterId, SubmitManuscriptRequest request, AuthenticatedUser user) {
        if (request == null) {
            request = new SubmitManuscriptRequest();
        }
        String fileUrl = request.getFileUrl();
        // Validate file URL
        if (fileUrl == null || fileUrl.trim().isEmpty()) {
            throw new BusinessRuleException("Manuscript file is required");
        }

        // Validate user is Mangaka owner of series
        long ownerId = manuscriptRepository.getChapterMangaka(chapterId);
        if (ownerId != user.getId()) {
            throw new BusinessRuleException("Only chapter owner can submit manuscript");
        }

        // BR-23: Only COMPLETE chapters can submit manuscript
        if (!isChapterComplete(chapterId)) {
            throw new BusinessRuleException("Chapter must be COMPLETE before submitting manuscript (BR-23)");
        }

        if (hasOpenManuscriptVersion(chapterId)) {
            throw new BusinessRuleException("Cannot create manuscript while a draft or active review version exists");
        }

        long manuscriptId = manuscriptRepository.createDraft(
                chapterId,
                fileUrl.trim(),
                trimToNull(request.getOriginalFileName()),
                trimToNull(request.getNotes()),
                trimToNull(request.getGenre()));
        return manuscriptRepository.findById(manuscriptId);
    }

    @Transactional
    public void submitDraft(long manuscriptId, AuthenticatedUser user) {
        ManuscriptSummary manuscript = requireManuscript(manuscriptId);
        long ownerId = manuscriptRepository.getChapterMangaka(manuscript.getChapterId());
        if (ownerId != user.getId()) {
            throw new BusinessRuleException("Only chapter owner can submit manuscript");
        }
        if (!ManuscriptStatus.DRAFT.name().equals(manuscript.getStatus())) {
            throw new BusinessRuleException("Only DRAFT manuscript versions can be submitted");
        }
        if (hasActiveReviewCycleExcept(manuscript.getChapterId(), manuscriptId)) {
            throw new BusinessRuleException("Cannot submit manuscript while another version is under review");
        }

        manuscriptRepository.submitForReview(manuscriptId);

        // Notify Tantou Editor
        long tantouId = manuscriptRepository.getChapterTantou(manuscript.getChapterId());
        notificationService.notifyUser(
            tantouId,
            "MANUSCRIPT_SUBMITTED",
            "New manuscript submitted for chapter #" + manuscript.getChapterId(),
            manuscriptId,
            "MANUSCRIPT"
        );

        // Audit log
        auditLogService.append(
            user,
            "MANUSCRIPT_SUBMITTED",
            "MANUSCRIPT",
            manuscriptId,
            auditLogService.jsonPair("chapterId", String.valueOf(manuscript.getChapterId()))
        );
    }

    @Transactional
    public void approveManuscript(long manuscriptId, ApproveManuscriptRequest request, AuthenticatedUser user) {
        ManuscriptSummary manuscript = requireManuscript(manuscriptId);

        // Validate user is assigned Tantou Editor
        long tantouId = manuscriptRepository.getManuscriptTantou(manuscriptId);
        if (tantouId != user.getId()) {
            throw new BusinessRuleException("Only assigned Tantou Editor can approve manuscript");
        }
        if (!isCurrentVersion(manuscript)) {
            throw new BusinessRuleException("Only current manuscript version can be approved");
        }

        // Validate manuscript status
        String status = manuscriptRepository.getStatus(manuscriptId);
        if (!ManuscriptStatus.UNDER_REVIEW.name().equals(status)) {
            throw new BusinessRuleException("Only UNDER_REVIEW manuscripts can be approved");
        }

        // Approve manuscript
        manuscriptRepository.approve(manuscriptId);

        // Notify Mangaka
        long chapterId = manuscript.getChapterId();
        long mangakaId = manuscriptRepository.getChapterMangaka(chapterId);
        notificationService.notifyUser(
            mangakaId,
            "MANUSCRIPT_APPROVED",
            "Manuscript approved for chapter #" + chapterId,
            manuscriptId,
            "MANUSCRIPT"
        );

        // Audit log
        auditLogService.append(
            user,
            "MANUSCRIPT_APPROVED",
            "MANUSCRIPT",
            manuscriptId,
            auditLogService.jsonPair("chapterId", String.valueOf(chapterId))
        );
    }

    @Transactional
    public void rejectManuscript(long manuscriptId, RejectManuscriptRequest request, AuthenticatedUser user) {
        ManuscriptSummary manuscript = requireManuscript(manuscriptId);

        // BR-40: Reject manuscript REQUIRES feedback
        if (request.getFeedback() == null || request.getFeedback().trim().isEmpty()) {
            throw new BusinessRuleException("Feedback is required when rejecting manuscript (BR-40)");
        }

        // Validate user is assigned Tantou Editor
        long tantouId = manuscriptRepository.getManuscriptTantou(manuscriptId);
        if (tantouId != user.getId()) {
            throw new BusinessRuleException("Only assigned Tantou Editor can reject manuscript");
        }
        if (!isCurrentVersion(manuscript)) {
            throw new BusinessRuleException("Only current manuscript version can be rejected");
        }

        // Validate manuscript status
        String status = manuscriptRepository.getStatus(manuscriptId);
        if (!ManuscriptStatus.UNDER_REVIEW.name().equals(status)) {
            throw new BusinessRuleException("Only UNDER_REVIEW manuscripts can be rejected");
        }

        // Reject manuscript
        manuscriptRepository.reject(manuscriptId, request.getFeedback().trim());

        // Notify Mangaka with feedback
        long chapterId = manuscript.getChapterId();
        long mangakaId = manuscriptRepository.getChapterMangaka(chapterId);
        notificationService.notifyUser(
            mangakaId,
            "MANUSCRIPT_REJECTED",
            "Manuscript rejected for chapter #" + chapterId + ". Feedback: " + request.getFeedback().trim(),
            manuscriptId,
            "MANUSCRIPT"
        );

        // Audit log
        auditLogService.append(
            user,
            "MANUSCRIPT_REJECTED",
            "MANUSCRIPT",
            manuscriptId,
            auditLogService.jsonTwoPairs("chapterId", String.valueOf(chapterId), "feedback", request.getFeedback().trim())
        );
    }

    @Transactional
    public void requestRevision(long manuscriptId, String feedback, AuthenticatedUser user) {
        ManuscriptSummary manuscript = requireManuscript(manuscriptId);
        String cleanFeedback = trimToNull(feedback);
        long tantouId = manuscriptRepository.getManuscriptTantou(manuscriptId);
        if (tantouId != user.getId()) {
            throw new BusinessRuleException("Only assigned Tantou Editor can request revision");
        }
        if (!isCurrentVersion(manuscript)) {
            throw new BusinessRuleException("Only current manuscript version can require revision");
        }
        if (!ManuscriptStatus.UNDER_REVIEW.name().equals(manuscript.getStatus())) {
            throw new BusinessRuleException("Only UNDER_REVIEW manuscripts can require revision");
        }
        if (cleanFeedback == null && manuscriptRepository.listAnnotations(manuscriptId).isEmpty()) {
            throw new BusinessRuleException("Feedback or at least one annotation is required when requesting revision");
        }

        manuscriptRepository.requestRevision(manuscriptId, cleanFeedback);

        long mangakaId = manuscriptRepository.getChapterMangaka(manuscript.getChapterId());
        notificationService.notifyUser(
            mangakaId,
            "MANUSCRIPT_REVISION_REQUESTED",
            "Revision requested for chapter #" + manuscript.getChapterId() + (cleanFeedback == null ? "." : ". Feedback: " + cleanFeedback),
            manuscriptId,
            "MANUSCRIPT"
        );

        auditLogService.append(
            user,
            "MANUSCRIPT_REVISION_REQUESTED",
            "MANUSCRIPT",
            manuscriptId,
            auditLogService.jsonTwoPairs("chapterId", String.valueOf(manuscript.getChapterId()), "feedback", cleanFeedback == null ? "" : cleanFeedback)
        );
    }

    @Transactional
    public void startReview(long manuscriptId, AuthenticatedUser user) {
        ManuscriptSummary manuscript = requireManuscript(manuscriptId);

        // Validate user is assigned Tantou Editor
        long tantouId = manuscriptRepository.getManuscriptTantou(manuscriptId);
        if (tantouId != user.getId()) {
            throw new BusinessRuleException("Only assigned Tantou Editor can start review");
        }
        if (!isCurrentVersion(manuscript)) {
            throw new BusinessRuleException("Only current manuscript version can be reviewed");
        }

        // BR-38: Cannot enter editorial review if chapter still has unapproved pages
        long chapterId = manuscript.getChapterId();
        if (!pageTaskRepository.areAllTasksApproved(chapterId)) {
            throw new BusinessRuleException("Cannot enter editorial review if chapter still has unapproved pages (BR-38)");
        }

        // Start review with 48h deadline (BR-43)
        manuscriptRepository.startReview(manuscriptId);

        long mangakaId = manuscriptRepository.getChapterMangaka(chapterId);
        notificationService.notifyUser(
            mangakaId,
            "MANUSCRIPT_REVIEW_STARTED",
            "Review started for chapter #" + chapterId,
            manuscriptId,
            "MANUSCRIPT"
        );

        // Audit log
        auditLogService.append(
            user,
            "MANUSCRIPT_REVIEW_STARTED",
            "MANUSCRIPT",
            manuscriptId,
            auditLogService.jsonPair("chapterId", String.valueOf(chapterId))
        );
    }

    public List<ManuscriptSummary> listManuscriptVersions(long chapterId) {
        return manuscriptRepository.listByChapter(chapterId);
    }

    public ManuscriptSummary getActiveManuscript(long chapterId) {
        List<ManuscriptSummary> manuscripts = manuscriptRepository.listByChapter(chapterId);
        if (manuscripts.isEmpty()) {
            return null;
        }
        // Return first (latest) non-archived manuscript
        for (ManuscriptSummary m : manuscripts) {
            if (!ManuscriptStatus.ARCHIVED.name().equals(m.getStatus())) {
                return m;
            }
        }
        return null;
    }

    public ManuscriptSummary getManuscriptById(long manuscriptId) {
        return manuscriptRepository.findById(manuscriptId);
    }

    @Transactional
    public void updateDraft(long manuscriptId, String fileUrl, AuthenticatedUser user) {
        updateDraft(manuscriptId, fileUrl, null, user);
    }

    @Transactional
    public void updateDraft(long manuscriptId, String fileUrl, String originalFileName, AuthenticatedUser user) {
        ManuscriptSummary manuscript = requireManuscript(manuscriptId);
        if (fileUrl == null || fileUrl.trim().isEmpty()) {
            throw new BusinessRuleException("Manuscript file is required");
        }
        long ownerId = manuscriptRepository.getChapterMangaka(manuscript.getChapterId());
        if (ownerId != user.getId()) {
            throw new BusinessRuleException("Only owner can edit manuscript");
        }
        if (!ManuscriptStatus.DRAFT.name().equals(manuscript.getStatus())) {
            throw new BusinessRuleException("Only DRAFT manuscript versions can be edited");
        }
        manuscriptRepository.updateFile(manuscriptId, fileUrl.trim(), trimToNull(originalFileName));
    }

    @Transactional
    public void deleteDraft(long manuscriptId, AuthenticatedUser user) {
        ManuscriptSummary manuscript = requireManuscript(manuscriptId);
        long ownerId = manuscriptRepository.getChapterMangaka(manuscript.getChapterId());
        if (ownerId != user.getId()) {
            throw new BusinessRuleException("Only owner can delete manuscript");
        }
        if (!ManuscriptStatus.DRAFT.name().equals(manuscript.getStatus())) {
            throw new BusinessRuleException("Only DRAFT manuscript versions can be deleted");
        }
        manuscriptRepository.delete(manuscriptId);
    }

    private boolean isChapterComplete(long chapterId) {
        // BR-22: Chapter only COMPLETE when all page tasks are APPROVED
        return pageTaskRepository.areAllTasksApproved(chapterId);
    }

    private boolean hasActiveReviewCycle(long chapterId) {
        List<ManuscriptSummary> manuscripts = manuscriptRepository.listByChapter(chapterId);
        for (ManuscriptSummary m : manuscripts) {
            String status = m.getStatus();
            if (ManuscriptStatus.SUBMITTED.name().equals(status) || 
                ManuscriptStatus.UNDER_REVIEW.name().equals(status)) {
                return true;
            }
        }
        return false;
    }

    private boolean hasOpenManuscriptVersion(long chapterId) {
        List<ManuscriptSummary> manuscripts = manuscriptRepository.listByChapter(chapterId);
        for (ManuscriptSummary m : manuscripts) {
            String status = m.getStatus();
            if (ManuscriptStatus.DRAFT.name().equals(status)
                    || ManuscriptStatus.SUBMITTED.name().equals(status)
                    || ManuscriptStatus.UNDER_REVIEW.name().equals(status)) {
                return true;
            }
        }
        return false;
    }

    private boolean hasActiveReviewCycleExcept(long chapterId, long manuscriptId) {
        List<ManuscriptSummary> manuscripts = manuscriptRepository.listByChapter(chapterId);
        for (ManuscriptSummary m : manuscripts) {
            if (m.getId() == manuscriptId) {
                continue;
            }
            String status = m.getStatus();
            if (ManuscriptStatus.SUBMITTED.name().equals(status)
                    || ManuscriptStatus.UNDER_REVIEW.name().equals(status)) {
                return true;
            }
        }
        return false;
    }

    private ManuscriptSummary requireManuscript(long manuscriptId) {
        ManuscriptSummary manuscript = manuscriptRepository.findById(manuscriptId);
        if (manuscript == null) {
            throw new BusinessRuleException("Manuscript not found");
        }
        return manuscript;
    }

    private boolean isCurrentVersion(ManuscriptSummary manuscript) {
        List<ManuscriptSummary> versions = manuscriptRepository.listByChapter(manuscript.getChapterId());
        return !versions.isEmpty() && versions.get(0).getId() == manuscript.getId();
    }

    private String trimToNull(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return value.trim();
    }
}
