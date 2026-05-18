package manga.controller.api;

import manga.common.ApiResponse;
import manga.common.exception.ForbiddenException;
import manga.common.util.SessionUserUtil;
import manga.model.AuthenticatedUser;
import manga.model.SeriesSummary;
import manga.repository.ProductionRepository;
import java.util.List;
import javax.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/series")
public class SeriesApiController {

    @Autowired
    private ProductionRepository productionRepository;

    @RequestMapping(method = RequestMethod.GET)
    public ApiResponse<List<SeriesSummary>> list(HttpSession session) {
        SessionUserUtil.requireUser(session);
        return ApiResponse.ok(productionRepository.listSeries(), "Series list");
    }

    @RequestMapping(value = "/{id}", method = RequestMethod.GET)
    public ApiResponse<SeriesSummary> detail(@PathVariable("id") long id, HttpSession session) {
        SessionUserUtil.requireUser(session);
        List<SeriesSummary> list = productionRepository.listSeries();
        for (SeriesSummary s : list) {
            if (s.getId() == id) {
                return ApiResponse.ok(s, "Series detail");
            }
        }
        throw new IllegalArgumentException("Series not found");
    }

    @RequestMapping(value = "/{id}/assistants", method = RequestMethod.POST)
    public ApiResponse<Object> enrollAssistant(
            @PathVariable("id") long id,
            @RequestParam("assistantId") long assistantId,
            HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can enroll assistants");
        if (productionRepository.findSeriesOwnerMangaka(id) != user.getId()) {
            throw new ForbiddenException("Only series owner can enroll assistant");
        }
        productionRepository.enrollAssistant(id, assistantId);
        return ApiResponse.ok(null, "Assistant enrolled");
    }

    @RequestMapping(value = "/{id}/assistants/{assistantId}", method = RequestMethod.DELETE)
    public ApiResponse<Object> removeAssistant(
            @PathVariable("id") long id,
            @PathVariable("assistantId") long assistantId,
            HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can remove assistants");
        if (productionRepository.findSeriesOwnerMangaka(id) != user.getId()) {
            throw new ForbiddenException("Only series owner can remove assistant");
        }
        productionRepository.removeAssistant(id, assistantId);
        return ApiResponse.ok(null, "Assistant removed");
    }
}
