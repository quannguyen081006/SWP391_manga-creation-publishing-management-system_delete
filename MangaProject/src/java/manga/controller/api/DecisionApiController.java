package manga.controller.api;

import manga.common.ApiResponse;
import manga.common.exception.ForbiddenException;
import manga.common.util.SessionUserUtil;
import manga.repository.DecisionRepository;
import manga.model.AuthenticatedUser;
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
@RequestMapping("/api/v1/decisions")
public class DecisionApiController {

    @Autowired
    private DecisionRepository decisionRepository;

    @RequestMapping(method = RequestMethod.GET)
    public ApiResponse<List<Map<String, Object>>> list(HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        if (!user.hasRole("ADMIN") && !user.hasRole("EDITORIAL_BOARD")) {
            throw new ForbiddenException("Only ADMIN/EDITORIAL_BOARD can view decisions");
        }
        return ApiResponse.ok(decisionRepository.listSessions(), "Decision sessions");
    }

    @RequestMapping(value = "/{id}", method = RequestMethod.GET)
    public ApiResponse<Map<String, Object>> detail(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        if (!user.hasRole("ADMIN") && !user.hasRole("EDITORIAL_BOARD")) {
            throw new ForbiddenException("Only ADMIN/EDITORIAL_BOARD can view decision detail");
        }
        return ApiResponse.ok(decisionRepository.getSessionDetail(id), "Decision session detail");
    }

    @RequestMapping(value = "/{id}/votes", method = RequestMethod.POST)
    public ApiResponse<Object> vote(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("decision") String decision,
            @RequestParam(value = "justification", required = false) String justification) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "EDITORIAL_BOARD", "Only EDITORIAL_BOARD can vote decision");
        decisionRepository.castVote(id, user.getId(), decision, justification);
        return ApiResponse.ok(null, "Decision vote submitted");
    }
}
