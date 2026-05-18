package manga.controller.api;

import manga.repository.ChapterRepository;
import manga.common.ApiResponse;
import manga.common.exception.ForbiddenException;
import manga.common.util.SessionUserUtil;
import manga.model.AuthenticatedUser;
import manga.model.ChapterSummary;
import java.sql.Date;
import java.util.List;
import javax.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class ChapterApiController {

    @Autowired
    private ChapterRepository chapterRepository;

    @RequestMapping(value = "/series/{seriesId}/chapters", method = RequestMethod.GET)
    public ApiResponse<List<ChapterSummary>> list(@PathVariable("seriesId") long seriesId, HttpSession session) {
        SessionUserUtil.requireUser(session);
        return ApiResponse.ok(chapterRepository.listBySeries(seriesId), "Chapters");
    }

    @RequestMapping(value = "/series/{seriesId}/chapters", method = RequestMethod.POST)
    public ApiResponse<ChapterSummary> create(
            @PathVariable("seriesId") long seriesId,
            HttpSession session,
            @RequestParam("chapterNumber") int chapterNumber,
            @RequestParam("title") String title,
            @RequestParam("publicationDate") String publicationDate) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can create chapter");

        long ownerId = chapterRepository.findSeriesOwnerMangaka(seriesId);
        if (ownerId != user.getId()) {
            throw new ForbiddenException("Only series owner can create chapter");
        }

        long id = chapterRepository.create(seriesId, chapterNumber, title, Date.valueOf(publicationDate));
        return ApiResponse.ok(chapterRepository.findById(id), "Chapter created");
    }

    @RequestMapping(value = "/chapters/{id}", method = RequestMethod.GET)
    public ApiResponse<ChapterSummary> detail(@PathVariable("id") long id, HttpSession session) {
        SessionUserUtil.requireUser(session);
        ChapterSummary chapter = chapterRepository.findById(id);
        if (chapter == null) {
            throw new IllegalArgumentException("Chapter not found");
        }
        return ApiResponse.ok(chapter, "Chapter detail");
    }

    @RequestMapping(value = "/chapters/{id}", method = RequestMethod.PUT)
    public ApiResponse<ChapterSummary> update(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("title") String title,
            @RequestParam("publicationDate") String publicationDate) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can update chapter");

        long ownerId = chapterRepository.findOwnerMangakaByChapter(id);
        if (ownerId != user.getId()) {
            throw new ForbiddenException("Only series owner can update chapter");
        }

        chapterRepository.updateChapterMetadata(id, title, Date.valueOf(publicationDate));
        return ApiResponse.ok(chapterRepository.findById(id), "Chapter updated");
    }

    @RequestMapping(value = "/chapters/{id}/submit-review", method = RequestMethod.POST)
    public ApiResponse<Object> submitReview(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can submit chapter for review");
        chapterRepository.submitForReview(id, user.getId());
        return ApiResponse.ok(null, "Chapter submitted for editorial review");
    }
}
