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
        // Validate file URL
        if (request.getFileUrl() == null || request.getFileUrl().trim().isEmpty()) {
            throw new BusinessRuleException("File URL cannot be empty");
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

        // BR-46: Cannot submit new manuscript while current review cycle unfinished
        if (hasActiveReviewCycle(chapterId)) {
            throw new BusinessRuleException("Cannot submit manuscript while active review cycle exists (BR-46)");
        }

        // Create new manuscript version
        long manuscriptId = manuscriptRepository.submit(chapterId, request.getFileUrl().trim());
        ManuscriptSummary manuscript = manuscriptRepository.findById(manuscriptId);

        // Notify Tantou Editor
        long tantouId = manuscriptRepository.getChapterTantou(chapterId);
        notificationService.notifyUser(
            tantouId,
            "MANUSCRIPT_SUBMITTED",
            "New manuscript submitted for chapter #" + chapterId,
            manuscriptId,
            "MANUSCRIPT"
        );

        // Audit log
        auditLogService.append(
            user,
            "MANUSCRIPT_SUBMITTED",
            "MANUSCRIPT",
            manuscriptId,
            auditLogService.jsonPair("chapterId", String.valueOf(chapterId))
        );

        return manuscript;
    }

    @Transactional
    public void approveManuscript(long manuscriptId, ApproveManuscriptRequest request, AuthenticatedUser user) {
        ManuscriptSummary manuscript = manuscriptRepository.findById(manuscriptId);
        if (manuscript == null) {
            throw new BusinessRuleException("Manuscript not found");
        }

        // Validate user is assigned Tantou Editor
        long tantouId = manuscriptRepository.getManuscriptTantou(manuscriptId);
        if (tantouId != user.getId()) {
            throw new BusinessRuleException("Only assigned Tantou Editor can approve manuscript");
        }

        // Validate manuscript status
        String status = manuscriptRepository.getStatus(manuscriptId);
        if (ManuscriptStatus.APPROVED.name().equals(status) || ManuscriptStatus.ARCHIVED.name().equals(status)) {
            throw new BusinessRuleException("Cannot approve finalized manuscript (BR-45)");
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
        ManuscriptSummary manuscript = manuscriptRepository.findById(manuscriptId);
        if (manuscript == null) {
            throw new BusinessRuleException("Manuscript not found");
        }

        // BR-40: Reject manuscript REQUIRES feedback
        if (request.getFeedback() == null || request.getFeedback().trim().isEmpty()) {
            throw new BusinessRuleException("Feedback is required when rejecting manuscript (BR-40)");
        }

        // Validate user is assigned Tantou Editor
        long tantouId = manuscriptRepository.getManuscriptTantou(manuscriptId);
        if (tantouId != user.getId()) {
            throw new BusinessRuleException("Only assigned Tantou Editor can reject manuscript");
        }

        // Validate manuscript status
        String status = manuscriptRepository.getStatus(manuscriptId);
        if (ManuscriptStatus.APPROVED.name().equals(status) || ManuscriptStatus.ARCHIVED.name().equals(status)) {
            throw new BusinessRuleException("Cannot reject finalized manuscript (BR-45)");
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
    public void startReview(long manuscriptId, AuthenticatedUser user) {
        ManuscriptSummary manuscript = manuscriptRepository.findById(manuscriptId);
        if (manuscript == null) {
            throw new BusinessRuleException("Manuscript not found");
        }

        // Validate user is assigned Tantou Editor
        long tantouId = manuscriptRepository.getManuscriptTantou(manuscriptId);
        if (tantouId != user.getId()) {
            throw new BusinessRuleException("Only assigned Tantou Editor can start review");
        }

        // BR-38: Cannot enter editorial review if chapter still has unapproved pages
        long chapterId = manuscript.getChapterId();
        if (!pageTaskRepository.areAllTasksApproved(chapterId)) {
            throw new BusinessRuleException("Cannot enter editorial review if chapter still has unapproved pages (BR-38)");
        }

        // Start review with 48h deadline (BR-43)
        manuscriptRepository.startReview(manuscriptId);

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
}
