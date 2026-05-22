package manga.controller.web;

import manga.model.AuthenticatedUser;
import manga.repository.PerformancePeriodRepository;
import manga.repository.PerformanceVoteRepository;
import manga.repository.PerformanceResultRepository;
import manga.service.MangakaPerformanceCalculationService;
import manga.common.util.SessionUserUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import javax.servlet.http.HttpSession;
import java.sql.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static manga.common.util.SessionUserUtil.requireUser;

@Controller
@RequestMapping("/main/analytics")
public class MangakaPerformanceController {

    @Autowired
    private PerformancePeriodRepository periodRepository;

    @Autowired
    private PerformanceVoteRepository voteRepository;

    @Autowired
    private PerformanceResultRepository resultRepository;

    @Autowired
    private MangakaPerformanceCalculationService calculationService;

    private void requireAdminOrEditorialBoard(AuthenticatedUser user) {
        if (!user.hasRole("ADMIN") && !user.hasRole("EDITORIAL_BOARD")) {
            throw new IllegalArgumentException("Only ADMIN and EDITORIAL_BOARD can access analytics");
        }
    }

    private void requireAdmin(AuthenticatedUser user) {
        if (!user.hasRole("ADMIN")) {
            throw new IllegalArgumentException("Only ADMIN can perform this action");
        }
    }

    @RequestMapping(value = "", method = RequestMethod.GET)
    public String analyticsIndex(HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdminOrEditorialBoard(user);
        
        List<Map<String, Object>> periods = periodRepository.listPeriods();
        List<Map<String, Object>> mangakaList = voteRepository.getMangakaList();
        model.addAttribute("periods", periods);
        model.addAttribute("mangakaList", mangakaList);
        model.addAttribute("currentUser", user);
        
        return "analytics/index";
    }

    @RequestMapping(value = "/periods/create", method = RequestMethod.POST)
    public String createPeriod(@RequestParam("name") String name,
                               @RequestParam("startDate") String startDate,
                               @RequestParam("endDate") String endDate,
                               HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdmin(user);
        
        try {
            periodRepository.createPeriod(name, Date.valueOf(startDate), Date.valueOf(endDate));
            return "redirect:/main/analytics";
        } catch (RuntimeException ex) {
            List<Map<String, Object>> periods = periodRepository.listPeriods();
            List<Map<String, Object>> mangakaList = voteRepository.getMangakaList();
            model.addAttribute("periods", periods);
            model.addAttribute("mangakaList", mangakaList);
            model.addAttribute("error", ex.getMessage());
            return analyticsIndex(session, model);
        }
    }

    @RequestMapping(value = "/periods/{periodId}/close", method = RequestMethod.POST)
    public String closePeriod(@PathVariable("periodId") long periodId, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdmin(user);
        
        try {
            periodRepository.closePeriod(periodId);
            return "redirect:/main/analytics";
        } catch (RuntimeException ex) {
            List<Map<String, Object>> periods = periodRepository.listPeriods();
            List<Map<String, Object>> mangakaList = voteRepository.getMangakaList();
            model.addAttribute("periods", periods);
            model.addAttribute("mangakaList", mangakaList);
            model.addAttribute("error", ex.getMessage());
            return analyticsIndex(session, model);
        }
    }

    @RequestMapping(value = "/periods/{periodId}/calculate", method = RequestMethod.POST)
    public String calculatePerformance(@PathVariable("periodId") long periodId, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdmin(user);
        
        try {
            calculationService.calculatePeriod(periodId);
            return "redirect:/main/analytics/period/" + periodId;
        } catch (Exception ex) {
            List<Map<String, Object>> periods = periodRepository.listPeriods();
            List<Map<String, Object>> mangakaList = voteRepository.getMangakaList();
            model.addAttribute("periods", periods);
            model.addAttribute("mangakaList", mangakaList);
            model.addAttribute("error", ex.getMessage());
            return analyticsIndex(session, model);
        }
    }

    @RequestMapping(value = "/periods/{periodId}/vote", method = RequestMethod.POST)
    public String submitMangakaVote(@PathVariable("periodId") long periodId,
                                     @RequestParam("mangakaId") long mangakaId,
                                     @RequestParam("popularityScore") int popularityScore,
                                     @RequestParam("reliabilityScore") int reliabilityScore,
                                     @RequestParam("qualityScore") int qualityScore,
                                     @RequestParam(value = "comment", required = false) String comment,
                                     HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        if (!user.hasRole("EDITORIAL_BOARD")) {
            throw new IllegalArgumentException("Only EDITORIAL_BOARD can submit mangaka votes");
        }
        
        try {
            voteRepository.submitVote(periodId, mangakaId, user.getId(), popularityScore, reliabilityScore, qualityScore, comment);
            return "redirect:/main/analytics/vote/" + periodId;
        } catch (RuntimeException ex) {
            List<Map<String, Object>> periods = periodRepository.listPeriods();
            List<Map<String, Object>> mangakaList = voteRepository.getMangakaList();
            model.addAttribute("periods", periods);
            model.addAttribute("mangakaList", mangakaList);
            model.addAttribute("error", ex.getMessage());
            return analyticsIndex(session, model);
        }
    }

    @RequestMapping(value = "/period/{periodId}", method = RequestMethod.GET)
    public String analyticsByPeriod(@PathVariable("periodId") long periodId, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdminOrEditorialBoard(user);
        
        Map<String, Object> period = periodRepository.findPeriodById(periodId);
        List<Map<String, Object>> periods = periodRepository.listPeriods();
        List<Map<String, Object>> results = resultRepository.getResultsByPeriod(periodId);
        
        Map<Long, String> mangakaNames = new HashMap<>();
        for (Map<String, Object> result : results) {
            long mangakaId = (Long) result.get("mangakaId");
            mangakaNames.put(mangakaId, voteRepository.getMangakaName(mangakaId));
        }
        
        model.addAttribute("period", period);
        model.addAttribute("periods", periods);
        model.addAttribute("results", results);
        model.addAttribute("mangakaNames", mangakaNames);
        model.addAttribute("currentUser", user);
        
        return "analytics/period";
    }

    @RequestMapping(value = "/vote/{periodId}", method = RequestMethod.GET)
    public String votePage(@PathVariable("periodId") long periodId, HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        if (!user.hasRole("EDITORIAL_BOARD")) {
            throw new IllegalArgumentException("Only EDITORIAL_BOARD can access voting page");
        }
        
        Map<String, Object> period = periodRepository.findPeriodById(periodId);
        if (!"OPEN".equalsIgnoreCase((String) period.get("status"))) {
            throw new IllegalArgumentException("Voting is only allowed for OPEN periods");
        }
        
        List<Map<String, Object>> mangakaList = voteRepository.getMangakaList();
        List<Map<String, Object>> votes = voteRepository.getVotesByPeriod(periodId);
        
        Map<Long, Map<String, Object>> votesByMangaka = new HashMap<>();
        for (Map<String, Object> vote : votes) {
            long mangakaId = (Long) vote.get("mangakaId");
            votesByMangaka.put(mangakaId, vote);
        }
        
        model.addAttribute("period", period);
        model.addAttribute("mangakaList", mangakaList);
        model.addAttribute("votesByMangaka", votesByMangaka);
        model.addAttribute("currentUser", user);
        
        return "analytics/vote";
    }

    @RequestMapping(value = "/popular", method = RequestMethod.GET)
    public String topPopularMangaka(@RequestParam(value = "periodId", required = false) Long periodId, 
                                     @RequestParam(value = "limit", required = false, defaultValue = "20") int limit,
                                     HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdminOrEditorialBoard(user);
        
        List<Map<String, Object>> periods = periodRepository.listPeriods();
        
        if (periodId == null && !periods.isEmpty()) {
            periodId = (Long) periods.get(0).get("id");
        }
        
        List<Map<String, Object>> results = null;
        Map<Long, String> mangakaNames = new HashMap<>();
        
        if (periodId != null) {
            Map<String, Object> period = periodRepository.findPeriodById(periodId);
            if (!"CALCULATED".equalsIgnoreCase((String) period.get("status"))) {
                model.addAttribute("error", "Results are not available yet. Period must be CALCULATED.");
            } else {
                results = resultRepository.getResultsByPeriodOrderByPopularity(periodId);
                if (results.size() > limit) {
                    results = results.subList(0, limit);
                }
                for (Map<String, Object> result : results) {
                    long mangakaId = (Long) result.get("mangakaId");
                    mangakaNames.put(mangakaId, voteRepository.getMangakaName(mangakaId));
                }
            }
        }
        
        model.addAttribute("results", results);
        model.addAttribute("periods", periods);
        model.addAttribute("currentPeriodId", periodId);
        model.addAttribute("currentUser", user);
        model.addAttribute("mangakaNames", mangakaNames);
        model.addAttribute("limit", limit);
        
        return "analytics/popular";
    }

    @RequestMapping(value = "/reliable", method = RequestMethod.GET)
    public String mostReliableMangaka(@RequestParam(value = "periodId", required = false) Long periodId,
                                        @RequestParam(value = "limit", required = false, defaultValue = "20") int limit,
                                        HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdminOrEditorialBoard(user);
        
        List<Map<String, Object>> periods = periodRepository.listPeriods();
        
        if (periodId == null && !periods.isEmpty()) {
            periodId = (Long) periods.get(0).get("id");
        }
        
        List<Map<String, Object>> results = null;
        Map<Long, String> mangakaNames = new HashMap<>();
        
        if (periodId != null) {
            Map<String, Object> period = periodRepository.findPeriodById(periodId);
            if (!"CALCULATED".equalsIgnoreCase((String) period.get("status"))) {
                model.addAttribute("error", "Results are not available yet. Period must be CALCULATED.");
            } else {
                results = resultRepository.getResultsByPeriodOrderByReliability(periodId);
                if (results.size() > limit) {
                    results = results.subList(0, limit);
                }
                for (Map<String, Object> result : results) {
                    long mangakaId = (Long) result.get("mangakaId");
                    mangakaNames.put(mangakaId, voteRepository.getMangakaName(mangakaId));
                }
            }
        }
        
        model.addAttribute("results", results);
        model.addAttribute("periods", periods);
        model.addAttribute("currentPeriodId", periodId);
        model.addAttribute("currentUser", user);
        model.addAttribute("mangakaNames", mangakaNames);
        model.addAttribute("limit", limit);
        
        return "analytics/reliable";
    }

    @RequestMapping(value = "/quality", method = RequestMethod.GET)
    public String highestQualityMangaka(@RequestParam(value = "periodId", required = false) Long periodId,
                                         @RequestParam(value = "limit", required = false, defaultValue = "20") int limit,
                                         HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdminOrEditorialBoard(user);
        
        List<Map<String, Object>> periods = periodRepository.listPeriods();
        
        if (periodId == null && !periods.isEmpty()) {
            periodId = (Long) periods.get(0).get("id");
        }
        
        List<Map<String, Object>> results = null;
        Map<Long, String> mangakaNames = new HashMap<>();
        
        if (periodId != null) {
            Map<String, Object> period = periodRepository.findPeriodById(periodId);
            if (!"CALCULATED".equalsIgnoreCase((String) period.get("status"))) {
                model.addAttribute("error", "Results are not available yet. Period must be CALCULATED.");
            } else {
                results = resultRepository.getResultsByPeriodOrderByQuality(periodId);
                if (results.size() > limit) {
                    results = results.subList(0, limit);
                }
                for (Map<String, Object> result : results) {
                    long mangakaId = (Long) result.get("mangakaId");
                    mangakaNames.put(mangakaId, voteRepository.getMangakaName(mangakaId));
                }
            }
        }
        
        model.addAttribute("results", results);
        model.addAttribute("periods", periods);
        model.addAttribute("currentPeriodId", periodId);
        model.addAttribute("currentUser", user);
        model.addAttribute("mangakaNames", mangakaNames);
        model.addAttribute("limit", limit);
        
        return "analytics/quality";
    }

    @RequestMapping(value = "/mangaka/{mangakaId}", method = RequestMethod.GET)
    public String mangakaDetail(@PathVariable("mangakaId") long mangakaId,
                                 @RequestParam(value = "periodId", required = false) Long periodId,
                                 HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdminOrEditorialBoard(user);
        
        List<Map<String, Object>> periods = periodRepository.listPeriods();
        
        if (periodId == null && !periods.isEmpty()) {
            periodId = (Long) periods.get(0).get("id");
        }
        
        Map<String, Object> result = null;
        String mangakaName = voteRepository.getMangakaName(mangakaId);
        
        if (periodId != null) {
            Map<String, Object> period = periodRepository.findPeriodById(periodId);
            if ("CALCULATED".equalsIgnoreCase((String) period.get("status"))) {
                result = resultRepository.getResultByMangaka(periodId, mangakaId);
            }
        }
        
        model.addAttribute("result", result);
        model.addAttribute("periods", periods);
        model.addAttribute("currentPeriodId", periodId);
        model.addAttribute("currentUser", user);
        model.addAttribute("mangakaName", mangakaName);
        model.addAttribute("mangakaId", mangakaId);
        
        return "analytics/detail";
    }
}
