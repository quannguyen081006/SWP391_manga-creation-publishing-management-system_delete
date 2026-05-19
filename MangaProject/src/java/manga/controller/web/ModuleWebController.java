package manga.controller.web;

import manga.model.AuthenticatedUser;
import manga.model.ChapterSummary;
import manga.model.ManuscriptSummary;
import manga.model.Proposal;
import manga.model.SeriesSummary;
import manga.model.TaskSummary;
import manga.repository.ChapterRepository;
import manga.repository.DecisionRepository;
import manga.repository.ManuscriptRepository;
import manga.repository.PageTaskRepository;
import manga.repository.ProductionRepository;
import manga.repository.RankingRepository;
import manga.repository.UserAdminRepository;
import manga.service.ProposalService;
import java.sql.Date;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import javax.servlet.http.HttpSession;
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

    @RequestMapping(value = "/proposals/{id}/edit", method = RequestMethod.GET)
    public String proposalEditPage(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        Proposal proposal = proposalService.getDetail(id);
        if (!user.hasRole("MANGAKA") || proposal.getMangakaId() != user.getId() || !"DRAFT".equalsIgnoreCase(proposal.getStatus())) {
            throw new IllegalArgumentException("Only DRAFT owner can edit proposal");
        }
        model.addAttribute("proposal", proposal);
        return "proposal/edit";
    }

    @RequestMapping(value = "/proposals/{id}/edit", method = RequestMethod.POST)
    public String proposalEdit(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("title") String title,
            @RequestParam("genre") String genre,
            @RequestParam("synopsis") String synopsis,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            proposalService.updateDraft(user, id, title, genre, synopsis);
            return "redirect:/main/proposals/" + id;
        } catch (RuntimeException ex) {
            Proposal proposal = proposalService.getDetail(id);
            model.addAttribute("proposal", proposal);
            model.addAttribute("error", ex.getMessage());
            return "proposal/edit";
        }
    }

    @RequestMapping(value = "/series/{id}", method = RequestMethod.GET)
    public String seriesDetail(@PathVariable("id") long id, HttpSession session, Model model) {
        requireUser(session);
        SeriesSummary found = null;
        for (SeriesSummary s : productionRepository.listSeries()) {
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

    @RequestMapping(value = "/chapters/{id}", method = RequestMethod.GET)
    public String chapterDetail(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        ChapterSummary chapter = chapterRepository.findById(id);
        if (chapter == null) {
            throw new IllegalArgumentException("Chapter not found");
        }
        model.addAttribute("chapter", chapter);
        model.addAttribute("tasks", pageTaskRepository.listByChapter(chapter.getId()));
        model.addAttribute("manuscripts", manuscriptRepository.listByChapter(chapter.getId()));
        model.addAttribute("canSubmitReview", user.hasRole("MANGAKA") && chapter.getCompletionPct() >= 100.0);
        return "chapter/detail";
    }

    @RequestMapping(value = "/chapters/{id}/submit-review", method = RequestMethod.POST)
    public String chapterSubmitReview(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            chapterRepository.submitForReview(id, user.getId());
            return "redirect:/main/chapters/" + id;
        } catch (RuntimeException ex) {
            chapterDetail(id, session, model);
            model.addAttribute("error", ex.getMessage());
            return "chapter/detail";
        }
    }

    @RequestMapping(value = "/tasks/{id}", method = RequestMethod.GET)
    public String taskDetail(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        TaskSummary task = pageTaskRepository.findById(id);
        if (task == null) {
            throw new IllegalArgumentException("Task not found");
        }
        model.addAttribute("task", task);
        model.addAttribute("canAssistantUpdate", user.hasRole("ASSISTANT") && user.getId() == task.getAssistantId());
        model.addAttribute("canMangakaReview", user.hasRole("MANGAKA") && pageTaskRepository.getTaskOwnerMangaka(id) == user.getId());
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
            pageTaskRepository.approveByMangaka(id);
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
            int rejectCount = pageTaskRepository.rejectByMangaka(id);
            if (rejectCount >= 3) {
                long tantouId = pageTaskRepository.getTaskTantouEditor(id);
                pageTaskRepository.createNotification(
                        tantouId,
                        "TASK_ESCALATED",
                        "Task #" + id + " reached 3 rejections and requires intervention.",
                        id,
                        "TASK");
            }
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

        model.addAttribute("manuscript", manuscript);
        model.addAttribute("annotations", manuscriptRepository.listAnnotations(id));
        model.addAttribute("canReview", user.hasRole("TANTOU_EDITOR") && manuscriptRepository.getManuscriptTantou(id) == user.getId());
        return "manuscript/detail";
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
    public String manuscriptReject(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            if (manuscriptRepository.getManuscriptTantou(id) != user.getId()) {
                throw new IllegalArgumentException("Only assigned Tantou can reject");
            }
            manuscriptRepository.reject(id);
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
    public String users(HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdmin(user);
        model.addAttribute("users", userAdminRepository.listUsers());
        return "user/list";
    }

    @RequestMapping(value = "/users/new", method = RequestMethod.GET)
    public String userNew(HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdmin(user);
        model.addAttribute("editing", false);
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
        return "user/form";
    }

    @RequestMapping(value = "/users/create", method = RequestMethod.POST)
    public String userCreate(
            HttpSession session,
            @RequestParam("username") String username,
            @RequestParam("password") String password,
            @RequestParam("fullName") String fullName,
            @RequestParam("email") String email,
            @RequestParam(value = "role", required = false) String role,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireAdmin(user);
            long id = userAdminRepository.createUser(username, password, fullName, email);
            if (role != null && !role.trim().isEmpty()) {
                userAdminRepository.addRole(id, role.trim().toUpperCase());
            }
            return "redirect:/main/users";
        } catch (RuntimeException ex) {
            model.addAttribute("editing", false);
            model.addAttribute("error", ex.getMessage());
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
            return "redirect:/main/users";
        } catch (RuntimeException ex) {
            model.addAttribute("editing", true);
            model.addAttribute("editUser", userAdminRepository.getUser(id));
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
            userAdminRepository.updateStatus(id, status.trim().toUpperCase());
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
            @RequestParam("role") String role,
            Model model) {
        AuthenticatedUser user = requireUser(session);
        try {
            requireAdmin(user);
            userAdminRepository.addRole(id, role.trim().toUpperCase());
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
}
