package manga.controller.web;

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
    private ProposalController proposalController;

    @Autowired
    private ProductionController productionController;

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
        return productionController.series(session, model);
    }

    @RequestMapping(value = "/chapters", method = RequestMethod.GET)
    public String chapters(HttpSession session, Model model) {
        return productionController.chapters(session, model);
    }

    @RequestMapping(value = "/tasks", method = RequestMethod.GET)
    public String tasks(HttpSession session, Model model) {
        return productionController.tasks(session, model);
    }

    @RequestMapping(value = "/manuscripts", method = RequestMethod.GET)
    public String manuscripts(HttpSession session, Model model) {
        return productionController.manuscripts(session, model);
    }

    @RequestMapping(value = "/proposals", method = RequestMethod.GET)
    public String proposals(HttpSession session, Model model) {
        return proposalController.list(session, model);
    }

    @RequestMapping(value = "/proposals/create", method = RequestMethod.GET)
    public String createProposalPage(HttpSession session) {
        return proposalController.createPage(session);
    }

    @RequestMapping(value = "/proposals/create", method = RequestMethod.POST)
    public String createProposal(
            HttpSession session,
            @RequestParam("title") String title,
            @RequestParam("genre") String genre,
            @RequestParam("synopsis") String synopsis,
            Model model) {
        return proposalController.create(session, title, genre, synopsis, model);
    }

    @RequestMapping(value = "/proposals/{id}", method = RequestMethod.GET)
    public String proposalDetail(@PathVariable("id") long id, HttpSession session, Model model) {
        return proposalController.detail(id, session, model);
    }

    @RequestMapping(value = "/proposals/{id}/submit", method = RequestMethod.POST)
    public String submitProposal(@PathVariable("id") long id, HttpSession session, Model model) {
        return proposalController.submit(id, session, model);
    }

    @RequestMapping(value = "/proposals/{id}/vote", method = RequestMethod.POST)
    public String voteProposal(
            @PathVariable("id") long id,
            @RequestParam("voteType") String voteType,
            @RequestParam(value = "reason", required = false) String reason,
            HttpSession session,
            Model model) {
        return proposalController.vote(id, voteType, reason, session, model);
    }
}
