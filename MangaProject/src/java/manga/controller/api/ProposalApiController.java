package manga.controller.api;

import manga.common.ApiResponse;
import manga.common.util.SessionUserUtil;
import manga.model.AuthenticatedUser;
import manga.model.Proposal;
import manga.service.ProposalService;
import java.util.List;
import java.util.Map;
import javax.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/proposals")
public class ProposalApiController {

    @Autowired
    private ProposalService proposalService;

    @RequestMapping(method = RequestMethod.GET)
    public ApiResponse<List<Proposal>> list(HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        return ApiResponse.ok(proposalService.listForUser(user), "Proposal list");
    }

    @RequestMapping(method = RequestMethod.POST)
    public ApiResponse<Proposal> create(
            HttpSession session,
            @RequestParam("title") String title,
            @RequestParam("genre") String genre,
            @RequestParam("synopsis") String synopsis) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        long id = proposalService.createProposal(user, title, genre, synopsis);
        return ApiResponse.ok(proposalService.getDetail(id), "Draft proposal created");
    }

    @RequestMapping(value = "/{id}", method = RequestMethod.GET)
    public ApiResponse<Proposal> detail(@PathVariable("id") long id, HttpSession session) {
        SessionUserUtil.requireUser(session);
        return ApiResponse.ok(proposalService.getDetail(id), "Proposal detail");
    }

    @RequestMapping(value = "/{id}", method = RequestMethod.PUT)
    public ApiResponse<Proposal> updateDraft(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("title") String title,
            @RequestParam("genre") String genre,
            @RequestParam("synopsis") String synopsis) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        proposalService.updateDraft(user, id, title, genre, synopsis);
        return ApiResponse.ok(proposalService.getDetail(id), "Draft proposal updated");
    }

    @RequestMapping(value = "/{id}/submit", method = RequestMethod.POST)
    public ApiResponse<Object> submit(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        proposalService.submitProposal(user, id);
        return ApiResponse.ok(null, "Proposal submitted for voting");
    }

    @RequestMapping(value = "/{id}/votes", method = RequestMethod.POST)
    public ApiResponse<Object> vote(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("voteType") String voteType,
            @RequestParam(value = "reason", required = false) String reason) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        proposalService.castVote(user, id, voteType, reason);
        return ApiResponse.ok(null, "Vote submitted");
    }

    @RequestMapping(value = "/{id}/votes", method = RequestMethod.GET)
    public ApiResponse<List<Map<String, Object>>> listVotes(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        return ApiResponse.ok(proposalService.listVotes(user, id), "Proposal votes");
    }
}


