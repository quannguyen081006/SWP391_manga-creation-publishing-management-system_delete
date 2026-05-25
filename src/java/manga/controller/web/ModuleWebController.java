package manga.controller.web;

import manga.model.AuthenticatedUser;
import manga.model.ChapterSummary;
import manga.model.ManuscriptSummary;
import manga.model.Proposal;
import manga.model.SeriesSummary;
import manga.model.TaskSummary;
import manga.repository.ChapterRepository;
import manga.repository.AuditLogRepository;
import manga.repository.DecisionRepository;
import manga.repository.ManuscriptRepository;
import manga.repository.PageTaskRepository;
import manga.repository.ProductionRepository;
import manga.repository.RankingRepository;
import manga.repository.UserAdminRepository;
import manga.service.AuditLogService;
import manga.service.NotificationService;
import manga.service.ProposalService;
import java.io.File;
import java.io.IOException;
import java.sql.Date;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import static manga.common.util.SessionUserUtil.requireRole;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
@RequestMapping("/main")
public class ModuleWebController {

    @Autowired
    private ProposalService proposalService;

    @Autowired
    private ProductionRepository productionRepository;

    @Autowired
    private ChapterRepository chapterRepository;

    @Autowired
    private PageTaskRepository pageTaskRepository;

    @Autowired
    private ManuscriptRepository manuscriptRepository;

    @Autowired
    private RankingRepository rankingRepository;

    @Autowired
    private DecisionRepository decisionRepository;

    @Autowired
    private UserAdminRepository userAdminRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Autowired
    private AuditLogService auditLogService;

    @Autowired
    private NotificationService notificationService;

    @RequestMapping(value = "/proposals/{id}/edit", method = RequestMethod.GET)
    public String proposalEditPage(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        Proposal proposal = proposalService.getDetail(user, id);
        boolean editableStatus = "DRAFT".equalsIgnoreCase(proposal.getStatus()) || "REVISION_REQUESTED".equalsIgnoreCase(proposal.getStatus());
        if (!user.hasRole("MANGAKA") || proposal.getMangakaId() != user.getId()
                || !editableStatus || proposal.getSubmitAttemptCount() >= ProposalService.MAX_SUBMIT_ATTEMPTS) {
            throw new IllegalArgumentException("Only editable proposal owner can edit proposal");
        }
        model.addAttribute("proposal", proposal);
        model.addAttribute("genres", proposalService.listGenres());
        return "proposal/edit";
    }

    @RequestMapping(value = "/proposals/{id}/edit", method = RequestMethod.POST)
    public String proposalEdit(
            @PathVariable("id") long id,
            HttpSession session,
            HttpServletRequest request,
            @RequestParam("title") String title,
            @RequestParam("genre") String genre,
            @RequestParam("synopsis") String synopsis,
            @RequestParam("approximateChapter") Integer approximateChapter,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            UploadInfo upload = saveUpload(request, "sampleFile");
            proposalService.updateDraft(user, id, title, genre, synopsis,
                    upload.path, upload.originalName, approximateChapter);
            return "redirect:/main/proposals/" + id;
        } catch (Exception ex) {
            Proposal proposal = proposalService.getDetail(user, id);
            model.addAttribute("proposal", proposal);
            model.addAttribute("error", ex.getMessage());
            model.addAttribute("genres", proposalService.listGenres());
            return "proposal/edit";
        }
    }

    private UploadInfo saveUpload(HttpServletRequest request, String fieldName) throws IOException, ServletException {
        Part part = request.getPart(fieldName);
        if (part == null || part.getSize() == 0) {
            return new UploadInfo(null, null);
        }
        String submittedName = part.getSubmittedFileName();
        String originalName = submittedName == null ? "proposal-file" : new File(submittedName).getName();
        String safeName = originalName.replaceAll("[^A-Za-z0-9._-]", "_");
        String storedName = System.currentTimeMillis() + "_" + safeName;
        String uploadPath = request.getServletContext().getRealPath("/uploads/proposals");
        if (uploadPath == null) {
            throw new IOException("Upload directory is not available");
        }
        File dir = new File(uploadPath);
        if (!dir.exists() && !dir.mkdirs()) {
            throw new IOException("Cannot create upload directory");
        }
        part.write(new File(dir, storedName).getAbsolutePath());
        return new UploadInfo("/uploads/proposals/" + storedName, originalName);
    }

    private static class UploadInfo {
        private final String path;
        private final String originalName;

        private UploadInfo(String path, String originalName) {
            this.path = path;
            this.originalName = originalName;
        }
    }

    @RequestMapping(value = "/series/{id}", method = RequestMethod.GET)
    public String seriesDetail(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        SeriesSummary found = null;
        for (SeriesSummary s : productionRepository.listSeries(user)) {
            if (s.getId() == id) {
                found = s;
                break;
            }
        }
        if (found == null) {
            throw new IllegalArgumentException("Series not found");
        }
        model.addAttribute("series", found);
        model.addAttribute("chapters", chapterRepository.listBySeries(id));
        return "series/detail";
    }

    @RequestMapping(value = "/chapters/detail", method = RequestMethod.GET)
    public String chapterDetailPage(HttpSession session) {
        requireUser(session);
        return "chapter/detail";
    }

    @RequestMapping(value = "/chapters/{id}", method = RequestMethod.GET)
    public String chapterDetail(@PathVariable("id") long id, HttpSession session) {
        requireUser(session);
        ChapterSummary chapter = chapterRepository.findById(id);
        if (chapter == null) {
            throw new IllegalArgumentException("Chapter not found");
        }
        return "redirect:/main/chapters/detail?id=" + id;
    }

    @RequestMapping(value = "/chapters/{id}/submit-review", method = RequestMethod.POST)
    public String chapterSubmitReview(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            chapterRepository.submitForReview(id, user.getId());
            return "redirect:/main/chapters/detail?id=" + id;
        } catch (RuntimeException ex) {
            try {
                return "redirect:/main/chapters/detail?id=" + id + "&error="
                        + java.net.URLEncoder.encode(ex.getMessage(), "UTF-8");
            } catch (java.io.UnsupportedEncodingException e) {
                return "redirect:/main/chapters/detail?id=" + id;
            }
        }
    }

    @RequestMapping(value = "/tasks/{id}", method = RequestMethod.GET)
    public String taskDetail(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        pageTaskRepository.markDelayedTasks();
        pageTaskRepository.markOverdueTasks();
        TaskSummary task = pageTaskRepository.findById(id);
        if (task == null) {
            throw new IllegalArgumentException("Task not found");
        }
        boolean canAssistantUpdate = user.hasRole("ASSISTANT") && user.getId() == task.getAssistantId();
        boolean canAssistantSubmit = canAssistantUpdate
                && ("IN_PROGRESS".equalsIgnoreCase(task.getStatus())
                || "REJECTED".equalsIgnoreCase(task.getStatus())
                || "OVERDUE".equalsIgnoreCase(task.getStatus()));
        boolean isOwnerMangaka = user.hasRole("MANGAKA") && pageTaskRepository.getTaskOwnerMangaka(id) == user.getId();
        boolean canMangakaReview = isOwnerMangaka
                && "SUBMITTED".equalsIgnoreCase(task.getStatus());
        boolean canTantouView = user.hasRole("TANTOU_EDITOR") && pageTaskRepository.getTaskTantouEditor(id) == user.getId();
        if (!user.hasRole("ADMIN") && !canAssistantUpdate && !isOwnerMangaka && !canTantouView) {
            throw new IllegalArgumentException("You can only view tasks assigned to your role");
        }
        model.addAttribute("task", task);
        model.addAttribute("canAssistantUpdate", canAssistantUpdate);
        model.addAttribute("canAssistantSubmit", canAssistantSubmit);
        model.addAttribute("canMangakaTaskOwner", isOwnerMangaka);
        model.addAttribute("canMangakaReview", canMangakaReview);
        return "task/detail";
    }

    @RequestMapping(value = "/tasks/{id}/assistant-status", method = RequestMethod.POST)
    public String taskUpdateByAssistant(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("status") String status,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            pageTaskRepository.updateStatusByAssistant(id, user.getId(), status);
            return "redirect:/main/tasks/" + id;
        } catch (RuntimeException ex) {
            taskDetail(id, session, model);
            model.addAttribute("error", ex.getMessage());
            return "task/detail";
        }
    }

    @RequestMapping(value = "/tasks/{id}/approve", method = RequestMethod.POST)
    public String taskApprove(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            if (pageTaskRepository.getTaskOwnerMangaka(id) != user.getId()) {
                throw new IllegalArgumentException("Only owner can approve");
            }
            pageTaskRepository.approveByMangaka(id, user.getId(), null);
            return "redirect:/main/tasks/" + id;
        } catch (RuntimeException ex) {
            taskDetail(id, session, model);
            model.addAttribute("error", ex.getMessage());
            return "task/detail";
        }
    }

    @RequestMapping(value = "/tasks/{id}/reject", method = RequestMethod.POST)
    public String taskReject(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            if (pageTaskRepository.getTaskOwnerMangaka(id) != user.getId()) {
                throw new IllegalArgumentException("Only owner can reject");
            }
            pageTaskRepository.rejectByMangaka(id, user.getId(), "Rejected via web form");
            return "redirect:/main/tasks/" + id;
        } catch (RuntimeException ex) {
            taskDetail(id, session, model);
            model.addAttribute("error", ex.getMessage());
            return "task/detail";
        }
    }

    @RequestMapping(value = "/manuscripts/{id}", method = RequestMethod.GET)
    public String manuscriptDetail(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        ManuscriptSummary manuscript = manuscriptRepository.findById(id);
        if (manuscript == null) {
            throw new IllegalArgumentException("Manuscript not found");
        }

        long chapterId = manuscript.getChapterId();
        long mangakaId = manuscriptRepository.getChapterMangaka(chapterId);
        long tantouId = manuscriptRepository.getManuscriptTantou(id);
        String status = manuscript.getStatus();
        boolean isMangakaOwner = user.getId() == mangakaId;
        boolean isAssignedTantou = user.getId() == tantouId;
        boolean isUnderReview = "UNDER_REVIEW".equals(status);
        boolean isRejected = "REJECTED".equals(status);
        boolean isApproved = "APPROVED".equals(status);
        boolean isDraft = "DRAFT".equals(status);
        boolean isSubmitted = "SUBMITTED".equals(status);

        // Get version history
        List<ManuscriptSummary> versionHistory = manuscriptRepository.listByChapter(chapterId);
        
        // Check if there's an active review cycle (any manuscript in SUBMITTED or UNDER_REVIEW)
        boolean hasActiveReviewCycle = versionHistory.stream()
            .anyMatch(m -> "SUBMITTED".equals(m.getStatus()) || "UNDER_REVIEW".equals(m.getStatus()));

        // Get chapter status for submit button validation
        String chapterStatus = chapterRepository.getChapterStatus(chapterId);
        
        // Get series status for submit button validation
        String seriesStatus = chapterRepository.getSeriesStatus(chapterId);

        // Permission flags for JSP
        model.addAttribute("manuscript", manuscript);
        model.addAttribute("annotations", manuscriptRepository.listAnnotations(id));
        model.addAttribute("versionHistory", versionHistory);
        model.addAttribute("currentUser", user);
        model.addAttribute("isMangakaOwner", isMangakaOwner);
        model.addAttribute("isAssignedTantou", isAssignedTantou);
        model.addAttribute("isUnderReview", isUnderReview);
        model.addAttribute("isRejected", isRejected);
        model.addAttribute("isApproved", isApproved);
        model.addAttribute("isDraft", isDraft);
        model.addAttribute("isSubmitted", isSubmitted);
        model.addAttribute("hasActiveReviewCycle", hasActiveReviewCycle);
        model.addAttribute("chapterStatus", chapterStatus);
        model.addAttribute("seriesStatus", seriesStatus);
        
        // START REVIEW button: TANTOU_EDITOR assigned + SUBMITTED
        model.addAttribute("canStartReview", user.hasRole("TANTOU_EDITOR") && isAssignedTantou && isSubmitted);
        
        // Annotation button: TANTOU_EDITOR assigned + not approved
        model.addAttribute("canAddAnnotation", user.hasRole("TANTOU_EDITOR") && isAssignedTantou && !isApproved);
        
        // Approve/Reject buttons: TANTOU_EDITOR assigned + UNDER_REVIEW
        model.addAttribute("canApproveReject", user.hasRole("TANTOU_EDITOR") && isAssignedTantou && isUnderReview);
        
        // SUBMIT TO EDITOR button: MANGAKA owner + DRAFT/REJECTED + chapter COMPLETE + no active review cycle + series not CANCELLED
        model.addAttribute("canSubmitToEditor", isMangakaOwner && (isDraft || isRejected) 
            && "COMPLETE".equals(chapterStatus) && !hasActiveReviewCycle && !"CANCELLED".equals(seriesStatus));
        
        // EDIT button: MANGAKA owner + DRAFT or REJECTED
        model.addAttribute("canEdit", isMangakaOwner && (isDraft || isRejected));
        
        // DELETE button: MANGAKA owner + not APPROVED + not UNDER_REVIEW
        model.addAttribute("canDelete", isMangakaOwner && !isApproved && !isUnderReview);
        
        // RESUBMIT button: MANGAKA owner + REJECTED + revisionDeadline not expired
        model.addAttribute("canResubmit", isMangakaOwner && isRejected && manuscript.getRevisionDeadline() != null);
        
        return "manuscript/detail";
    }

    @RequestMapping(value = "/manuscripts/{id}/review", method = RequestMethod.GET)
    public String manuscriptReviewDeepLink(@PathVariable("id") long id, HttpSession session, Model model) {
        return manuscriptDetail(id, session, model);
    }

    @RequestMapping(value = "/manuscripts/{id}/approve", method = RequestMethod.POST)
    public String manuscriptApprove(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            if (manuscriptRepository.getManuscriptTantou(id) != user.getId()) {
                throw new IllegalArgumentException("Only assigned Tantou can approve");
            }
            manuscriptRepository.approve(id);
            return "redirect:/main/manuscripts/" + id;
        } catch (RuntimeException ex) {
            manuscriptDetail(id, session, model);
            model.addAttribute("error", ex.getMessage());
            return "manuscript/detail";
        }
    }

    @RequestMapping(value = "/manuscripts/{id}/reject", method = RequestMethod.POST)
    public String manuscriptReject(
            @PathVariable("id") long id,
            @RequestParam("feedback") String feedback,
            HttpSession session,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            if (manuscriptRepository.getManuscriptTantou(id) != user.getId()) {
                throw new IllegalArgumentException("Only assigned Tantou can reject");
            }
            if (feedback == null || feedback.trim().isEmpty()) {
                throw new IllegalArgumentException("Feedback is required for rejection (BR-40)");
            }
            ManuscriptSummary manuscript = manuscriptRepository.findById(id);
            manuscriptRepository.reject(id, feedback.trim());
            if (manuscript != null) {
                long mangakaId = manuscriptRepository.getChapterMangaka(manuscript.getChapterId());
                notificationService.notifyUser(
                        mangakaId,
                        "MANUSCRIPT_REJECTED",
                        "Manuscript rejected for chapter #" + manuscript.getChapterId() + ". Feedback: " + feedback.trim(),
                        id,
                        "MANUSCRIPT");
            }
            return "redirect:/main/manuscripts/" + id;
        } catch (RuntimeException ex) {
            manuscriptDetail(id, session, model);
            model.addAttribute("error", ex.getMessage());
            return "manuscript/detail";
        }
    }

    @RequestMapping(value = "/manuscripts/{id}/annotate", method = RequestMethod.POST)
    public String manuscriptAnnotate(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("pageNumber") int pageNumber,
            @RequestParam("content") String content,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            if (manuscriptRepository.getManuscriptTantou(id) != user.getId()) {
                throw new IllegalArgumentException("Only assigned Tantou can annotate");
            }
            manuscriptRepository.addAnnotation(id, user.getId(), pageNumber, content);
            return "redirect:/main/manuscripts/" + id;
        } catch (RuntimeException ex) {
            manuscriptDetail(id, session, model);
            model.addAttribute("error", ex.getMessage());
            return "manuscript/detail";
        }
    }

    @RequestMapping(value = "/manuscripts/{id}/start-review", method = RequestMethod.POST)
    public String manuscriptStartReview(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireRole(user, "TANTOU_EDITOR", "Only TANTOU_EDITOR can start review");
            if (manuscriptRepository.getManuscriptTantou(id) != user.getId()) {
                throw new IllegalArgumentException("Only assigned Tantou can start review");
            }
            manuscriptRepository.startReview(id);
            return "redirect:/main/manuscripts/" + id;
        } catch (RuntimeException ex) {
            manuscriptDetail(id, session, model);
            model.addAttribute("error", ex.getMessage());
            return "manuscript/detail";
        }
    }

    @RequestMapping(value = "/manuscripts/{id}/submit", method = RequestMethod.POST)
    public String manuscriptSubmitToEditor(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireRole(user, "MANGAKA", "Only MANGAKA can submit manuscript");
            ManuscriptSummary manuscript = manuscriptRepository.findById(id);
            if (manuscript == null) {
                throw new IllegalArgumentException("Manuscript not found");
            }
            long mangakaId = manuscriptRepository.getChapterMangaka(manuscript.getChapterId());
            if (user.getId() != mangakaId) {
                throw new IllegalArgumentException("Only owner can submit manuscript");
            }
            String status = manuscript.getStatus();
            if (!("DRAFT".equals(status) || "REJECTED".equals(status))) {
                throw new IllegalArgumentException("Manuscript must be DRAFT or REJECTED to submit");
            }
            manuscriptRepository.submitForReview(id);
            return "redirect:/main/manuscripts/" + id;
        } catch (RuntimeException ex) {
            manuscriptDetail(id, session, model);
            model.addAttribute("error", ex.getMessage());
            return "manuscript/detail";
        }
    }

    @RequestMapping(value = "/manuscripts/{id}/edit", method = RequestMethod.GET)
    public String manuscriptEdit(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        ManuscriptSummary manuscript = manuscriptRepository.findById(id);
        if (manuscript == null) {
            throw new IllegalArgumentException("Manuscript not found");
        }
        long mangakaId = manuscriptRepository.getChapterMangaka(manuscript.getChapterId());
        if (user.getId() != mangakaId) {
            throw new IllegalArgumentException("Only owner can edit manuscript");
        }
        String status = manuscript.getStatus();
        if (!("DRAFT".equals(status) || "REJECTED".equals(status))) {
            throw new IllegalArgumentException("Manuscript must be DRAFT or REJECTED to edit");
        }
        model.addAttribute("manuscript", manuscript);
        return "manuscript/edit";
    }

    @RequestMapping(value = "/manuscripts/{id}/edit", method = RequestMethod.POST)
    public String manuscriptUpdate(
            @PathVariable("id") long id,
            @RequestParam("fileUrl") String fileUrl,
            HttpSession session,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            ManuscriptSummary manuscript = manuscriptRepository.findById(id);
            if (manuscript == null) {
                throw new IllegalArgumentException("Manuscript not found");
            }
            long mangakaId = manuscriptRepository.getChapterMangaka(manuscript.getChapterId());
            if (user.getId() != mangakaId) {
                throw new IllegalArgumentException("Only owner can edit manuscript");
            }
            String status = manuscript.getStatus();
            if (!("DRAFT".equals(status) || "REJECTED".equals(status))) {
                throw new IllegalArgumentException("Manuscript must be DRAFT or REJECTED to edit");
            }
            manuscriptRepository.updateFileUrl(id, fileUrl);
            return "redirect:/main/manuscripts/" + id;
        } catch (RuntimeException ex) {
            manuscriptDetail(id, session, model);
            model.addAttribute("error", ex.getMessage());
            return "manuscript/detail";
        }
    }

    @RequestMapping(value = "/manuscripts/{id}/delete", method = RequestMethod.POST)
    public String manuscriptDelete(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            ManuscriptSummary manuscript = manuscriptRepository.findById(id);
            if (manuscript == null) {
                throw new IllegalArgumentException("Manuscript not found");
            }
            long mangakaId = manuscriptRepository.getChapterMangaka(manuscript.getChapterId());
            if (user.getId() != mangakaId) {
                throw new IllegalArgumentException("Only owner can delete manuscript");
            }
            String status = manuscript.getStatus();
            if ("APPROVED".equals(status) || "UNDER_REVIEW".equals(status)) {
                throw new IllegalArgumentException("Cannot delete APPROVED or UNDER_REVIEW manuscript");
            }
            manuscriptRepository.delete(id);
            return "redirect:/main/manuscripts";
        } catch (RuntimeException ex) {
            manuscriptDetail(id, session, model);
            model.addAttribute("error", ex.getMessage());
            return "manuscript/detail";
        }
    }

    @RequestMapping(value = "/manuscripts/create", method = RequestMethod.GET)
    public String manuscriptCreate(HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireRole(user, "MANGAKA", "Only MANGAKA can create manuscripts");
        model.addAttribute("chapters", chapterRepository.listAll());
        return "manuscript/create";
    }

    @RequestMapping(value = "/manuscripts/create", method = RequestMethod.POST)
    public String manuscriptCreateSubmit(
            HttpSession session,
            @RequestParam("chapterId") long chapterId,
            @RequestParam("fileUrl") String fileUrl,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireRole(user, "MANGAKA", "Only MANGAKA can create manuscripts");
            manuscriptRepository.submit(chapterId, fileUrl);
            return "redirect:/main/manuscripts";
        } catch (RuntimeException ex) {
            model.addAttribute("error", ex.getMessage());
            model.addAttribute("chapters", chapterRepository.listAll());
            return "manuscript/create";
        }
    }

    @RequestMapping(value = "/ranking/periods", method = RequestMethod.GET)
    public String rankingPeriods(HttpSession session, Model model) {
        requireUser(session);
        model.addAttribute("periods", rankingRepository.listPeriods());
        model.addAttribute("seriesList", productionRepository.listSeries());
        return "ranking/period";
    }

    @RequestMapping(value = "/ranking/periods/create", method = RequestMethod.POST)
    public String rankingCreate(
            HttpSession session,
            @RequestParam("name") String name,
            @RequestParam("startDate") String startDate,
            @RequestParam("endDate") String endDate,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireAdmin(user);
            rankingRepository.createPeriod(name, Date.valueOf(startDate), Date.valueOf(endDate));
            return "redirect:/main/ranking/periods";
        } catch (RuntimeException ex) {
            rankingPeriods(session, model);
            model.addAttribute("error", ex.getMessage());
            return "ranking/period";
        }
    }

    @RequestMapping(value = "/ranking/periods/{id}/close", method = RequestMethod.POST)
    public String rankingClose(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireAdmin(user);
            rankingRepository.closePeriod(id);
            return "redirect:/main/ranking/periods";
        } catch (RuntimeException ex) {
            rankingPeriods(session, model);
            model.addAttribute("error", ex.getMessage());
            return "ranking/period";
        }
    }

    @RequestMapping(value = "/ranking/periods/{id}/calculate", method = RequestMethod.POST)
    public String rankingCalculate(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireAdmin(user);
            rankingRepository.calculatePeriod(id);
            return "redirect:/main/ranking/periods/" + id + "/results";
        } catch (RuntimeException ex) {
            rankingPeriods(session, model);
            model.addAttribute("error", ex.getMessage());
            return "ranking/period";
        }
    }

    @RequestMapping(value = "/ranking/periods/{id}/entries", method = RequestMethod.POST)
    public String rankingSubmitEntry(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("seriesId") long seriesId,
            @RequestParam("voteCount") int voteCount,
            @RequestParam("readerCount") int readerCount,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            if (!user.hasRole("EDITORIAL_BOARD")) {
                throw new IllegalArgumentException("Only EDITORIAL_BOARD can submit entries");
            }
            rankingRepository.submitEntry(id, seriesId, user.getId(), voteCount, readerCount);
            return "redirect:/main/ranking/periods";
        } catch (RuntimeException ex) {
            rankingPeriods(session, model);
            model.addAttribute("error", ex.getMessage());
            return "ranking/period";
        }
    }

    @RequestMapping(value = "/ranking/periods/{id}/results", method = RequestMethod.GET)
    public String rankingResults(@PathVariable("id") long id, HttpSession session, Model model) {
        requireUser(session);
        model.addAttribute("period", rankingRepository.findPeriodById(id));
        model.addAttribute("results", rankingRepository.results(id));
        model.addAttribute("entries", rankingRepository.listEntries(id));
        return "ranking/results";
    }

    @RequestMapping(value = "/decisions", method = RequestMethod.GET)
    public String decisionSessions(HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        if (!user.hasRole("ADMIN") && !user.hasRole("EDITORIAL_BOARD")) {
            throw new IllegalArgumentException("Only ADMIN/EDITORIAL_BOARD can view decision sessions");
        }
        model.addAttribute("sessions", decisionRepository.listSessions());
        return "decision/session";
    }

    @RequestMapping(value = "/decisions/{id}", method = RequestMethod.GET)
    public String decisionDetail(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        if (!user.hasRole("ADMIN") && !user.hasRole("EDITORIAL_BOARD")) {
            throw new IllegalArgumentException("Only ADMIN/EDITORIAL_BOARD can view decision detail");
        }
        model.addAttribute("sessionDetail", decisionRepository.getSessionDetail(id));
        return "decision/session";
    }

    @RequestMapping(value = "/decisions/{id}/votes", method = RequestMethod.POST)
    public String decisionVote(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("decision") String decision,
            @RequestParam(value = "justification", required = false) String justification,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            if (!user.hasRole("EDITORIAL_BOARD")) {
                throw new IllegalArgumentException("Only EDITORIAL_BOARD can vote");
            }
            decisionRepository.castVote(id, user.getId(), decision, justification);
            return "redirect:/main/decisions/" + id;
        } catch (RuntimeException ex) {
            decisionDetail(id, session, model);
            model.addAttribute("error", ex.getMessage());
            return "decision/session";
        }
    }

    @RequestMapping(value = "/users", method = RequestMethod.GET)
    public String users(
            HttpSession session,
            @RequestParam(value = "created", required = false) Long created,
            @RequestParam(value = "username", required = false) String createdUsername,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdmin(user);
        model.addAttribute("users", userAdminRepository.listUsers());
        model.addAttribute("availableRoles", availableRoles());
        model.addAttribute("adminRoleLocked", userAdminRepository.hasAnyAdmin());
        if (created != null) {
            model.addAttribute("success", "User " + createdUsername + " created successfully");
            model.addAttribute("createdUserId", created);
        }
        return "user/list";
    }

    private String users(HttpSession session, Model model) {
        return users(session, null, null, model);
    }

    @RequestMapping(value = "/audit-logs", method = RequestMethod.GET)
    public String auditLogs(
            HttpSession session,
            @RequestParam(value = "actorId", required = false) Integer actorId,
            @RequestParam(value = "action", required = false) String action,
            @RequestParam(value = "entityType", required = false) String entityType,
            @RequestParam(value = "limit", defaultValue = "100") int limit,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdmin(user);
        int safeLimit = limit < 1 ? 100 : Math.min(limit, 500);
        model.addAttribute("auditLogs", auditLogRepository.search(actorId, action, entityType, safeLimit));
        model.addAttribute("actorId", actorId);
        model.addAttribute("action", action);
        model.addAttribute("entityType", entityType);
        model.addAttribute("limit", safeLimit);
        model.addAttribute("availableActions", auditLogRepository.listActions());
        return "audit/list";
    }

    @RequestMapping(value = "/users/new", method = RequestMethod.GET)
    public String userNew(HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdmin(user);
        model.addAttribute("editing", false);
        model.addAttribute("availableRoles", availableRoles());
        model.addAttribute("adminRoleLocked", userAdminRepository.hasAnyAdmin());
        model.addAttribute("selectedRolesCsv", "");
        return "user/form";
    }

    @RequestMapping(value = "/users/{id}/edit", method = RequestMethod.GET)
    public String userEdit(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdmin(user);
        Map<String, Object> row = userAdminRepository.getUser(id);
        if (row == null) {
            throw new IllegalArgumentException("User not found");
        }
        model.addAttribute("editing", true);
        model.addAttribute("editUser", row);
        model.addAttribute("availableRoles", availableRoles());
        model.addAttribute("adminRoleLocked", userAdminRepository.hasAnyAdmin());
        return "user/form";
    }

    @RequestMapping(value = "/users/create", method = RequestMethod.POST)
    public String userCreate(
            HttpSession session,
            @RequestParam("username") String username,
            @RequestParam("password") String password,
            @RequestParam("confirmPassword") String confirmPassword,
            @RequestParam("fullName") String fullName,
            @RequestParam("email") String email,
            @RequestParam(value = "roles", required = false) String[] roles,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireAdmin(user);
            validateCreateUser(username, password, confirmPassword, fullName, email, roles);
            long id = userAdminRepository.createUser(username, password, fullName, email);
            auditLogService.append(user, "USER_CREATED", "USER", id, auditLogService.jsonTwoPairs("username", username, "email", email));
            for (String role : roles) {
                String normalizedRole = role.trim().toUpperCase();
                userAdminRepository.addRole(id, normalizedRole);
                auditLogService.append(user, "USER_ROLE_ASSIGNED", "USER", id, auditLogService.jsonPair("role", normalizedRole));
            }
            notificationService.notifyUser(id, "ACCOUNT_CREATED", "Your MangaFlow account has been created.", 0, null);
            return "redirect:/main/users?created=" + id + "&username=" + username.trim();
        } catch (RuntimeException ex) {
            model.addAttribute("editing", false);
            model.addAttribute("error", ex.getMessage());
            model.addAttribute("formUsername", username);
            model.addAttribute("formFullName", fullName);
            model.addAttribute("formEmail", email);
            model.addAttribute("formPassword", password);
            model.addAttribute("selectedRoles", roles == null ? new String[0] : roles);
            model.addAttribute("selectedRolesCsv", rolesCsv(roles));
            model.addAttribute("availableRoles", availableRoles());
            model.addAttribute("adminRoleLocked", userAdminRepository.hasAnyAdmin());
            return "user/form";
        }
    }

    @RequestMapping(value = "/users/{id}/update", method = RequestMethod.POST)
    public String userUpdate(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("fullName") String fullName,
            @RequestParam("email") String email,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireAdmin(user);
            userAdminRepository.updateUser(id, fullName, email);
            auditLogService.append(user, "USER_UPDATED", "USER", id, auditLogService.jsonTwoPairs("fullName", fullName, "email", email));
            return "redirect:/main/users";
        } catch (RuntimeException ex) {
            model.addAttribute("editing", true);
            model.addAttribute("editUser", userAdminRepository.getUser(id));
            model.addAttribute("availableRoles", availableRoles());
            model.addAttribute("adminRoleLocked", userAdminRepository.hasAnyAdmin());
            model.addAttribute("error", ex.getMessage());
            return "user/form";
        }
    }

    @RequestMapping(value = "/users/{id}/status", method = RequestMethod.POST)
    public String userStatus(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("status") String status,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireAdmin(user);
            String normalizedStatus = status.trim().toUpperCase();
            userAdminRepository.updateStatus(id, normalizedStatus);
            auditLogService.append(user, "USER_STATUS_CHANGED", "USER", id, auditLogService.jsonPair("status", normalizedStatus));
            notificationService.notifyUser(id, "ACCOUNT_STATUS_CHANGED", "Your account status changed to " + normalizedStatus + ".", 0, null);
            return "redirect:/main/users";
        } catch (RuntimeException ex) {
            users(session, model);
            model.addAttribute("error", ex.getMessage());
            return "user/list";
        }
    }

    @RequestMapping(value = "/users/{id}/roles", method = RequestMethod.POST)
    public String userRole(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam(value = "role", required = false) String role,
            @RequestParam(value = "roles", required = false) String[] roles,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireAdmin(user);
            List<String> requestedRoles = selectedRoles(role, roles);
            if (requestedRoles.isEmpty()) {
                throw new IllegalArgumentException("Select at least one role");
            }
            validateAssignableRoles(id, requestedRoles);
            List<String> currentRoles = userAdminRepository.listRoles(id);
            for (String normalizedRole : requestedRoles) {
                userAdminRepository.addRole(id, normalizedRole);
                if (!currentRoles.contains(normalizedRole)) {
                    auditLogService.append(user, "USER_ROLE_ASSIGNED", "USER", id, auditLogService.jsonPair("role", normalizedRole));
                    notificationService.notifyUser(id, "ROLE_ASSIGNED", "Role " + normalizedRole + " was assigned to your account.", 0, null);
                }
            }
            return "redirect:/main/users";
        } catch (RuntimeException ex) {
            users(session, model);
            model.addAttribute("error", ex.getMessage());
            return "user/list";
        }
    }

    @RequestMapping(value = "/users/{id}/roles/remove", method = RequestMethod.POST)
    public String userRoleRemove(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("role") String role,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireAdmin(user);
            String normalizedRole = role.trim().toUpperCase();
            List<String> currentRoles = userAdminRepository.listRoles(id);
            userAdminRepository.removeRole(id, normalizedRole);
            if (currentRoles.contains(normalizedRole)) {
                auditLogService.append(user, "USER_ROLE_REMOVED", "USER", id, auditLogService.jsonPair("role", normalizedRole));
                notificationService.notifyUser(id, "ROLE_REMOVED", "Role " + normalizedRole + " was removed from your account.", 0, null);
            }
            return "redirect:/main/users";
        } catch (RuntimeException ex) {
            users(session, model);
            model.addAttribute("error", ex.getMessage());
            return "user/list";
        }
    }

    private AuthenticatedUser requireUser(HttpSession session) {
        Object auth = session.getAttribute("AUTH_USER");
        if (auth == null || !(auth instanceof AuthenticatedUser)) {
            throw new IllegalArgumentException("Unauthorized");
        }
        return (AuthenticatedUser) auth;
    }

    private void requireAdmin(AuthenticatedUser user) {
        if (user == null || !user.hasRole("ADMIN")) {
            throw new IllegalArgumentException("Only ADMIN can perform this action");
        }
    }

    private List<String> availableRoles() {
        return Arrays.asList("MANGAKA", "ASSISTANT", "TANTOU_EDITOR", "EDITORIAL_BOARD");
    }

    private String rolesCsv(String[] roles) {
        if (roles == null || roles.length == 0) {
            return "";
        }
        StringBuilder builder = new StringBuilder("|");
        for (String role : roles) {
            if (!isBlank(role)) {
                builder.append(role.trim().toUpperCase()).append("|");
            }
        }
        return builder.toString();
    }

    private List<String> selectedRoles(String role, String[] roles) {
        List<String> selected = new ArrayList<String>();
        if (!isBlank(role)) {
            addSelectedRole(selected, role);
        }
        if (roles != null) {
            for (String item : roles) {
                addSelectedRole(selected, item);
            }
        }
        return selected;
    }

    private void addSelectedRole(List<String> selected, String role) {
        if (isBlank(role)) {
            return;
        }
        String normalizedRole = role.trim().toUpperCase();
        if (!selected.contains(normalizedRole)) {
            selected.add(normalizedRole);
        }
    }

    private void validateCreateUser(String username, String password, String confirmPassword, String fullName, String email, String[] roles) {
        if (isBlank(username) || isBlank(password) || isBlank(confirmPassword) || isBlank(fullName) || isBlank(email)) {
            throw new IllegalArgumentException("All user fields are required");
        }
        if (!password.equals(confirmPassword)) {
            throw new IllegalArgumentException("Password confirmation does not match");
        }
        if (password.length() < 5) {
            throw new IllegalArgumentException("Password must be at least 5 characters");
        }
        if (!email.contains("@")) {
            throw new IllegalArgumentException("Email is invalid");
        }
        if (roles == null || roles.length == 0) {
            throw new IllegalArgumentException("Select at least one role");
        }
        if (containsRole(roles, "ADMIN") && userAdminRepository.hasAnyAdmin()) {
            throw new IllegalArgumentException("Only one ADMIN account is allowed");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private void validateAssignableRoles(long userId, List<String> roles) {
        if (roles.contains("ADMIN")
                && !userAdminRepository.hasRole(userId, "ADMIN")
                && userAdminRepository.hasAnyAdmin()) {
            throw new IllegalArgumentException("Only one ADMIN account is allowed");
        }
    }

    private boolean containsRole(String[] roles, String roleName) {
        if (roles == null) {
            return false;
        }
        for (String role : roles) {
            if (roleName.equalsIgnoreCase(role == null ? "" : role.trim())) {
                return true;
            }
        }
        return false;
    }
}
