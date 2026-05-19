package manga.controller.web;

import manga.model.AuthenticatedUser;
import manga.model.ManuscriptSummary;
import manga.model.Proposal;
import manga.model.TaskSummary;
import manga.repository.ProductionRepository;
import manga.service.ProposalService;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.http.HttpServletRequest;
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
public class MainController {

    @Autowired
    private AuthController authController;

    @Autowired
    private DashboardController dashboardController;

    @Autowired
    private ProposalService proposalService;

    @Autowired
    private ProductionRepository productionRepository;

    @RequestMapping(value = "", method = RequestMethod.GET)
    public String root() {
        return "redirect:/main/dashboard";
    }

    @RequestMapping(value = "/login", method = RequestMethod.GET)
    public String loginPage() {
        return authController.loginPage();
    }

    @RequestMapping(value = "/login", method = RequestMethod.POST)
    public String login(
            @RequestParam("username") String username,
            @RequestParam("password") String password,
            HttpServletRequest request,
            Model model) {
        return authController.login(username, password, request, model);
    }

    @RequestMapping(value = "/switch-role", method = RequestMethod.GET)
    public String switchRole(
            @RequestParam("username") String username,
            @RequestParam(value = "back", required = false) String back,
            HttpServletRequest request) {
        return authController.switchRole(username, back, request);
    }

    @RequestMapping(value = "/logout", method = RequestMethod.GET)
    public String logout(HttpServletRequest request) {
        return authController.logout(request);
    }

    @RequestMapping(value = "/dashboard", method = RequestMethod.GET)
    public String dashboard(HttpSession session, Model model) {
        return dashboardController.dashboard(session, model);
    }

    @RequestMapping(value = "/series", method = RequestMethod.GET)
    public String series(HttpSession session, Model model) {
        model.addAttribute("seriesList", productionRepository.listSeries());
        return "series/list";
    }

    @RequestMapping(value = "/chapters", method = RequestMethod.GET)
    public String chapters(HttpSession session, Model model) {
        return "chapter/list";
    }

    @RequestMapping(value = "/tasks", method = RequestMethod.GET)
    public String tasks(HttpSession session, Model model) {
        AuthenticatedUser user = (AuthenticatedUser) session.getAttribute("AUTH_USER");
        List<TaskSummary> tasks = visibleTasks(user, productionRepository.listTasks());
        int active = 0;
        int submitted = 0;
        int completed = 0;
        int overdue = 0;
        LocalDate now = LocalDate.now();

        for (TaskSummary task : tasks) {
            String st = task.getStatus() == null ? "" : task.getStatus().toUpperCase();
            if ("PENDING".equals(st) || "IN_PROGRESS".equals(st)) {
                active++;
            }
            if ("SUBMITTED".equals(st)) {
                submitted++;
            }
            if ("APPROVED".equals(st)) {
                completed++;
            }
            if ("OVERDUE".equals(st) || (task.getDueDate() != null && task.getDueDate().toLocalDate().isBefore(now) && !"APPROVED".equals(st))) {
                overdue++;
            }
        }

        model.addAttribute("tasks", tasks);
        model.addAttribute("activeTasks", active);
        model.addAttribute("submittedTasks", submitted);
        model.addAttribute("completedTasks", completed);
        model.addAttribute("overdueTasks", overdue);
        return "task/list";
    }

    @RequestMapping(value = "/manuscripts", method = RequestMethod.GET)
    public String manuscripts(HttpSession session, Model model) {
        List<ManuscriptSummary> manuscripts = productionRepository.listManuscripts();
        int pendingReview = 0;
        int urgent = 0;
        int breached = 0;

        for (ManuscriptSummary manuscript : manuscripts) {
            String st = manuscript.getStatus() == null ? "" : manuscript.getStatus().toUpperCase();
            if ("SUBMITTED".equals(st) || "UNDER_REVIEW".equals(st)) {
                pendingReview++;
            }
            if (manuscript.getReviewDeadline() != null) {
                long hoursLeft = (manuscript.getReviewDeadline().getTime() - System.currentTimeMillis()) / (1000L * 60L * 60L);
                if (hoursLeft < 0) {
                    breached++;
                } else if (hoursLeft <= 12) {
                    urgent++;
                }
            }
        }

        model.addAttribute("manuscripts", manuscripts);
        model.addAttribute("pendingReview", pendingReview);
        model.addAttribute("urgentManuscripts", urgent);
        model.addAttribute("slaBreached", breached);
        return "manuscript/list";
    }

    @RequestMapping(value = "/proposals", method = RequestMethod.GET)
    public String proposals(HttpSession session, Model model) {
        AuthenticatedUser user = (AuthenticatedUser) session.getAttribute("AUTH_USER");
        List<Proposal> proposals = proposalService.listForUser(user);
        model.addAttribute("proposals", proposals);
        model.addAttribute("user", user);
        model.addAttribute("isMangaka", user.hasRole("MANGAKA"));
        model.addAttribute("isBoard", user.hasRole("EDITORIAL_BOARD"));
        return "proposal/list";
    }

    @RequestMapping(value = "/proposals/create", method = RequestMethod.GET)
    public String createProposalPage(HttpSession session) {
        AuthenticatedUser user = (AuthenticatedUser) session.getAttribute("AUTH_USER");
        if (!user.hasRole("MANGAKA")) {
            return "redirect:/main/proposals";
        }
        return "proposal/create";
    }

    @RequestMapping(value = "/proposals/create", method = RequestMethod.POST)
    public String createProposal(
            HttpSession session,
            @RequestParam("title") String title,
            @RequestParam("genre") String genre,
            @RequestParam("synopsis") String synopsis,
            Model model) {
        AuthenticatedUser user = (AuthenticatedUser) session.getAttribute("AUTH_USER");
        try {
            long id = proposalService.createProposal(user, title, genre, synopsis);
            return "redirect:/main/proposals/" + id;
        } catch (IllegalArgumentException ex) {
            model.addAttribute("error", ex.getMessage());
            model.addAttribute("title", title);
            model.addAttribute("genre", genre);
            model.addAttribute("synopsis", synopsis);
            return "proposal/create";
        }
    }

    @RequestMapping(value = "/proposals/{id}", method = RequestMethod.GET)
    public String proposalDetail(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = (AuthenticatedUser) session.getAttribute("AUTH_USER");
        Proposal proposal = proposalService.getDetail(user, id);
        model.addAttribute("proposal", proposal);
        model.addAttribute("user", user);
        boolean canEditDraft = user.hasRole("MANGAKA") && proposal.getMangakaId() == user.getId() && "DRAFT".equalsIgnoreCase(proposal.getStatus());
        model.addAttribute("canEdit", canEditDraft);
        model.addAttribute("canSubmit", canEditDraft);
        model.addAttribute("canVote", user.hasRole("EDITORIAL_BOARD") && ("SUBMITTED".equalsIgnoreCase(proposal.getStatus()) || "VOTING".equalsIgnoreCase(proposal.getStatus())));
        return "proposal/detail";
    }

    @RequestMapping(value = "/proposals/{id}/submit", method = RequestMethod.POST)
    public String submitProposal(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = (AuthenticatedUser) session.getAttribute("AUTH_USER");
        try {
            proposalService.submitProposal(user, id);
            return "redirect:/main/proposals/" + id;
        } catch (IllegalArgumentException ex) {
            return proposalDetailWithError(id, session, model, ex.getMessage());
        }
    }

    @RequestMapping(value = "/proposals/{id}/vote", method = RequestMethod.POST)
    public String voteProposal(
            @PathVariable("id") long id,
            @RequestParam("voteType") String voteType,
            @RequestParam(value = "reason", required = false) String reason,
            HttpSession session,
            Model model) {
        AuthenticatedUser user = (AuthenticatedUser) session.getAttribute("AUTH_USER");
        try {
            proposalService.castVote(user, id, voteType, reason);
            return "redirect:/main/proposals/" + id;
        } catch (IllegalArgumentException ex) {
            return proposalDetailWithError(id, session, model, ex.getMessage());
        }
    }

    private String proposalDetailWithError(long id, HttpSession session, Model model, String error) {
        proposalDetail(id, session, model);
        model.addAttribute("error", error);
        return "proposal/detail";
    }

    private List<TaskSummary> visibleTasks(AuthenticatedUser user, List<TaskSummary> allTasks) {
        if (user == null || !user.hasRole("ASSISTANT")) {
            return allTasks;
        }
        List<TaskSummary> assigned = new ArrayList<TaskSummary>();
        for (TaskSummary task : allTasks) {
            if (task.getAssistantId() == user.getId()) {
                assigned.add(task);
            }
        }
        return assigned;
    }
}
