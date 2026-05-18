package manga.controller.api;

import manga.common.ApiResponse;
import manga.common.exception.ForbiddenException;
import manga.common.util.SessionUserUtil;
import manga.model.AuthenticatedUser;
import manga.repository.RankingRepository;
import java.sql.Date;
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
@RequestMapping("/api/v1/ranking")
public class RankingApiController {

    @Autowired
    private RankingRepository rankingRepository;

    @RequestMapping(value = "/periods", method = RequestMethod.GET)
    public ApiResponse<List<Map<String, Object>>> listPeriods(HttpSession session) {
        SessionUserUtil.requireUser(session);
        return ApiResponse.ok(rankingRepository.listPeriods(), "Ranking periods");
    }

    @RequestMapping(value = "/periods", method = RequestMethod.POST)
    public ApiResponse<Map<String, Object>> createPeriod(
            HttpSession session,
            @RequestParam("name") String name,
            @RequestParam("startDate") String startDate,
            @RequestParam("endDate") String endDate) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "ADMIN", "Only ADMIN can create ranking period");
        long id = rankingRepository.createPeriod(name, Date.valueOf(startDate), Date.valueOf(endDate));
        return ApiResponse.ok(rankingRepository.findPeriodById(id), "Ranking period created");
    }

    @RequestMapping(value = "/periods/{id}/close", method = RequestMethod.POST)
    public ApiResponse<Object> closePeriod(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "ADMIN", "Only ADMIN can close ranking period");
        rankingRepository.closePeriod(id);
        return ApiResponse.ok(null, "Ranking period closed");
    }

    @RequestMapping(value = "/periods/{id}/results", method = RequestMethod.GET)
    public ApiResponse<List<Map<String, Object>>> results(@PathVariable("id") long id, HttpSession session) {
        SessionUserUtil.requireUser(session);
        return ApiResponse.ok(rankingRepository.results(id), "Ranking results");
    }

    @RequestMapping(value = "/periods/{id}/calculate", method = RequestMethod.POST)
    public ApiResponse<Object> calculate(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "ADMIN", "Only ADMIN can trigger ranking calculation");
        rankingRepository.calculatePeriod(id);
        return ApiResponse.ok(null, "Ranking calculation completed");
    }

    @RequestMapping(value = "/periods/{id}/entries", method = RequestMethod.POST)
    public ApiResponse<Object> submitEntry(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("seriesId") long seriesId,
            @RequestParam("voteCount") int voteCount,
            @RequestParam("readerCount") int readerCount) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "EDITORIAL_BOARD", "Only EDITORIAL_BOARD can submit vote entries");
        rankingRepository.submitEntry(id, seriesId, user.getId(), voteCount, readerCount);
        return ApiResponse.ok(null, "Vote entry submitted");
    }

    @RequestMapping(value = "/periods/{id}/entries", method = RequestMethod.GET)
    public ApiResponse<List<Map<String, Object>>> listEntries(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        if (!user.hasRole("ADMIN") && !user.hasRole("EDITORIAL_BOARD")) {
            throw new ForbiddenException("Only ADMIN/EDITORIAL_BOARD can view vote entries");
        }
        return ApiResponse.ok(rankingRepository.listEntries(id), "Vote entries");
    }
}
