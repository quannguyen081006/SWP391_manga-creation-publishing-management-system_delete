package manga.controller.web;

import manga.common.exception.ForbiddenException;
import manga.model.AuthenticatedUser;
import manga.model.ChapterSummary;
import manga.model.ManuscriptSummary;
import manga.model.Proposal;
import manga.model.SeriesSummary;
import manga.model.TaskSummary;
import manga.repository.ProductionRepository;
import manga.service.ProposalService;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class DashboardController {

    @Autowired
    private ProposalService proposalService;

    @Autowired
    private ProductionRepository productionRepository;

    @RequestMapping(value = {"/", "/dashboard"}, method = RequestMethod.GET)
    public String dashboard(HttpSession session, Model model) {
        AuthenticatedUser user = (AuthenticatedUser) session.getAttribute("AUTH_USER");

        List<Proposal> proposals = new ArrayList<Proposal>();
        if (user != null && (user.hasRole("MANGAKA") || user.hasRole("EDITORIAL_BOARD") || user.hasRole("TANTOU_EDITOR") || user.hasRole("ADMIN"))) {
            try {
                proposals = proposalService.listForUser(user);
            } catch (ForbiddenException ignored) {
                proposals = new ArrayList<Proposal>();
            }
        }

        List<SeriesSummary> seriesList = productionRepository.listSeries();
        List<TaskSummary> tasks = (user != null && user.hasRole("ASSISTANT"))
                ? productionRepository.listTasksByAssistant(user.getId())
                : productionRepository.listTasks();
        List<ManuscriptSummary> manuscripts = productionRepository.listManuscripts();
        List<ChapterSummary> chapters = productionRepository.listChapters();

        int openVotes = 0;
        int approved = 0;
        for (Proposal p : proposals) {
            if ("SUBMITTED".equalsIgnoreCase(p.getStatus()) || "VOTING".equalsIgnoreCase(p.getStatus())) {
                openVotes++;
            }
            if ("APPROVED".equalsIgnoreCase(p.getStatus())) {
                approved++;
            }
        }

        int activeTasks = 0;
        int submittedTasks = 0;
        int completedTasks = 0;
        int overdueTasks = 0;
        int pendingManuscripts = 0;

        LocalDate now = LocalDate.now();
        for (TaskSummary t : tasks) {
            String st = t.getStatus() == null ? "" : t.getStatus().toUpperCase();
            if ("PENDING".equals(st) || "IN_PROGRESS".equals(st)) {
                activeTasks++;
            }
            if ("SUBMITTED".equals(st)) {
                submittedTasks++;
            }
            if ("APPROVED".equals(st)) {
                completedTasks++;
            }
            if ("OVERDUE".equals(st) || (t.getDueDate() != null && t.getDueDate().toLocalDate().isBefore(now) && !"APPROVED".equals(st))) {
                overdueTasks++;
            }
        }

        for (ManuscriptSummary m : manuscripts) {
            if ("SUBMITTED".equalsIgnoreCase(m.getStatus()) || "UNDER_REVIEW".equalsIgnoreCase(m.getStatus())) {
                pendingManuscripts++;
            }
        }

        List<ChapterSummary> inProgressChapters = new ArrayList<ChapterSummary>();
        for (ChapterSummary c : chapters) {
            if ("IN_PROGRESS".equalsIgnoreCase(c.getStatus()) || "PLANNING".equalsIgnoreCase(c.getStatus()) || "EDITORIAL_REVIEW".equalsIgnoreCase(c.getStatus())) {
                inProgressChapters.add(c);
            }
            if (inProgressChapters.size() >= 5) {
                break;
            }
        }

        model.addAttribute("user", user);
        model.addAttribute("proposalCount", proposals.size());
        model.addAttribute("openVotes", openVotes);
        model.addAttribute("approvedCount", approved);
        model.addAttribute("roles", user == null ? null : user.getRoles());
        model.addAttribute("seriesCount", seriesList.size());
        model.addAttribute("overdueTasks", overdueTasks);
        model.addAttribute("pendingManuscripts", pendingManuscripts);
        model.addAttribute("inProgressChapters", inProgressChapters);
        model.addAttribute("activeTasks", activeTasks);
        model.addAttribute("submittedTasks", submittedTasks);
        model.addAttribute("completedTasks", completedTasks);

        return "dashboard/index";
    }
}
