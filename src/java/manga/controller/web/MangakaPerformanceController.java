package manga.controller.web;

import manga.model.AuthenticatedUser;
import manga.repository.EditorialCommentRepository;
import manga.repository.MangakaPerformanceRepository;
import manga.repository.PerformanceImportRecordRepository;
import manga.repository.PerformancePeriodRepository;
import manga.repository.PerformanceResultRepository;
import manga.service.CsvImportService;
import manga.service.MangakaPerformanceCalculationService;
import manga.common.util.SessionUserUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
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
    private PerformanceImportRecordRepository importRecordRepository;

    @Autowired
    private PerformanceResultRepository resultRepository;

    @Autowired
    private MangakaPerformanceCalculationService calculationService;

    @Autowired
    private CsvImportService csvImportService;

    @Autowired
    private EditorialCommentRepository editorialCommentRepository;

    @Autowired
    private MangakaPerformanceRepository mangakaPerformanceRepository;

    private void requireAdminOrEditorialBoard(AuthenticatedUser user) {
        if (!user.hasRole("ADMIN") && !user.hasRole("EDITORIAL_BOARD") && !user.hasRole("TANTOU_EDITOR")) {
            throw new IllegalArgumentException("Only ADMIN, EDITORIAL_BOARD and TANTOU_EDITOR can access analytics");
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
        List<Map<String, Object>> mangakaList = mangakaPerformanceRepository.listMangakaUsers();
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
            List<Map<String, Object>> mangakaList = mangakaPerformanceRepository.listMangakaUsers();
            model.addAttribute("periods", periods);
            model.addAttribute("mangakaList", mangakaList);
            model.addAttribute("error", ex.getMessage());
            return analyticsIndex(session, model);
        }
    }

    @RequestMapping(value = "/periods/{periodId}/upload", method = RequestMethod.POST)
    public String uploadCsv(@PathVariable("periodId") long periodId,
                            @RequestParam("csvFile") MultipartFile csvFile,
                            HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        requireAdmin(user);
        
        try {
            Map<String, Object> period = periodRepository.findPeriodById(periodId);
            if (!"OPEN".equalsIgnoreCase((String) period.get("status"))) {
                throw new IllegalArgumentException("CSV upload is only allowed for OPEN periods");
            }

            List<Map<String, Object>> mangakaList = mangakaPerformanceRepository.listMangakaUsers();
            Map<String, Long> mangakaNameToIdMap = csvImportService.buildMangakaNameToIdMap(mangakaList);
            
            CsvImportService.ImportResult result = csvImportService.parseAndValidateCsv(csvFile, mangakaNameToIdMap);
            
            if (result.failureCount > 0) {
                model.addAttribute("error", "CSV validation failed with " + result.failureCount + " errors");
                model.addAttribute("errors", result.errors);
            } else {
                importRecordRepository.deleteImportRecordsByPeriod(periodId);
                csvImportService.importValidRows(periodId, result.validRows, mangakaNameToIdMap);
                periodRepository.markAsImported(periodId);
                model.addAttribute("success", "CSV imported successfully. " + result.successCount + " records imported.");
            }
            
            List<Map<String, Object>> periods = periodRepository.listPeriods();
            model.addAttribute("periods", periods);
            model.addAttribute("mangakaList", mangakaList);
            model.addAttribute("currentUser", user);
            
            return "analytics/index";
        } catch (RuntimeException ex) {
            List<Map<String, Object>> periods = periodRepository.listPeriods();
            List<Map<String, Object>> mangakaList = mangakaPerformanceRepository.listMangakaUsers();
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
            List<Map<String, Object>> mangakaList = mangakaPerformanceRepository.listMangakaUsers();
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
            mangakaNames.put(mangakaId, mangakaPerformanceRepository.getMangakaName(mangakaId));
        }
        
        model.addAttribute("period", period);
        model.addAttribute("periods", periods);
        model.addAttribute("results", results);
        model.addAttribute("mangakaNames", mangakaNames);
        model.addAttribute("currentUser", user);
        
        return "analytics/period";
    }

    @RequestMapping(value = "/comments/{periodId}", method = RequestMethod.POST)
    public String submitEditorialComment(@PathVariable("periodId") long periodId,
                                         @RequestParam("mangakaId") long mangakaId,
                                         @RequestParam("comment") String comment,
                                         HttpSession session, Model model) {
        AuthenticatedUser user = requireUser(session);
        if (!user.hasRole("EDITORIAL_BOARD")) {
            throw new IllegalArgumentException("Only EDITORIAL_BOARD can submit editorial comments");
        }
        
        try {
            editorialCommentRepository.saveComment(periodId, mangakaId, user.getId(), comment);
            return "redirect:/main/analytics/mangaka/" + mangakaId + "?periodId=" + periodId;
        } catch (RuntimeException ex) {
            model.addAttribute("error", ex.getMessage());
            return mangakaDetail(mangakaId, periodId, session, model);
        }
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
                    mangakaNames.put(mangakaId, mangakaPerformanceRepository.getMangakaName(mangakaId));
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
                    mangakaNames.put(mangakaId, mangakaPerformanceRepository.getMangakaName(mangakaId));
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
                    mangakaNames.put(mangakaId, mangakaPerformanceRepository.getMangakaName(mangakaId));
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
        String mangakaName = mangakaPerformanceRepository.getMangakaName(mangakaId);
        List<Map<String, Object>> editorialComments = null;
        
        if (periodId != null) {
            Map<String, Object> period = periodRepository.findPeriodById(periodId);
            if ("CALCULATED".equalsIgnoreCase((String) period.get("status"))) {
                result = resultRepository.getResultByMangaka(periodId, mangakaId);
                editorialComments = editorialCommentRepository.getCommentsByPeriodAndMangaka(periodId, mangakaId);
            }
        }
        
        model.addAttribute("result", result);
        model.addAttribute("periods", periods);
        model.addAttribute("currentPeriodId", periodId);
        model.addAttribute("currentUser", user);
        model.addAttribute("mangakaName", mangakaName);
        model.addAttribute("mangakaId", mangakaId);
        model.addAttribute("editorialComments", editorialComments);
        
        return "analytics/detail";
    }
}
