package manga.controller.web;

import manga.model.AuthenticatedUser;
import manga.model.Proposal;
import manga.service.ProposalService;
import java.util.List;
import javax.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class ProposalController {

    @Autowired
    private ProposalService proposalService;

    @RequestMapping(value = "/proposals", method = RequestMethod.GET)
    public String list(HttpSession session, Model model) {
        AuthenticatedUser user = (AuthenticatedUser) session.getAttribute("AUTH_USER");
        List<Proposal> proposals = proposalService.listForUser(user);
        model.addAttribute("proposals", proposals);
        model.addAttribute("user", user);
        model.addAttribute("isMangaka", user.hasRole("MANGAKA"));
        model.addAttribute("isBoard", user.hasRole("EDITORIAL_BOARD"));
        return "proposal/list";
    }

    @RequestMapping(value = "/proposals/create", method = RequestMethod.GET)
    public String createPage(HttpSession session) {
        AuthenticatedUser user = (AuthenticatedUser) session.getAttribute("AUTH_USER");
        if (!user.hasRole("MANGAKA")) {
            return "redirect:/main/proposals";
        }
        return "proposal/create";
    }

    @RequestMapping(value = "/proposals/create", method = RequestMethod.POST)
    public String create(
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
    public String detail(@PathVariable("id") long id, HttpSession session, Model model) {
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
    public String submit(@PathVariable("id") long id, HttpSession session, Model model) {
        AuthenticatedUser user = (AuthenticatedUser) session.getAttribute("AUTH_USER");
        try {
            proposalService.submitProposal(user, id);
            return "redirect:/main/proposals/" + id;
        } catch (IllegalArgumentException ex) {
            return detailWithError(id, session, model, ex.getMessage());
        }
    }

    @RequestMapping(value = "/proposals/{id}/vote", method = RequestMethod.POST)
    public String vote(
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
            return detailWithError(id, session, model, ex.getMessage());
        }
    }

    private String detailWithError(long id, HttpSession session, Model model, String error) {
        detail(id, session, model);
        model.addAttribute("error", error);
        return "proposal/detail";
    }
}




