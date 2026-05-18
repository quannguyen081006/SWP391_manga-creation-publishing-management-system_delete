package manga.controller.api;

import manga.common.ApiResponse;
import manga.common.util.SessionUserUtil;
import manga.model.AuthenticatedUser;
import manga.model.TaskSummary;
import manga.repository.PageTaskRepository;
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
public class PageTaskApiController {

    @Autowired
    private PageTaskRepository pageTaskRepository;

    @RequestMapping(value = "/chapters/{chapterId}/tasks", method = RequestMethod.GET)
    public ApiResponse<List<TaskSummary>> list(@PathVariable("chapterId") long chapterId, HttpSession session) {
        SessionUserUtil.requireUser(session);
        return ApiResponse.ok(pageTaskRepository.listByChapter(chapterId), "Task list");
    }

    @RequestMapping(value = "/chapters/{chapterId}/tasks", method = RequestMethod.POST)
    public ApiResponse<TaskSummary> create(
            @PathVariable("chapterId") long chapterId,
            HttpSession session,
            @RequestParam("assistantId") long assistantId,
            @RequestParam("pageRangeStart") int pageRangeStart,
            @RequestParam("pageRangeEnd") int pageRangeEnd,
            @RequestParam("taskType") String taskType,
            @RequestParam("dueDate") String dueDate) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can create task");

        long taskId = pageTaskRepository.create(
                chapterId,
                assistantId,
                pageRangeStart,
                pageRangeEnd,
                taskType,
                Date.valueOf(dueDate));
        return ApiResponse.ok(pageTaskRepository.findById(taskId), "Task created");
    }

    @RequestMapping(value = "/tasks/{id}", method = RequestMethod.GET)
    public ApiResponse<TaskSummary> detail(@PathVariable("id") long id, HttpSession session) {
        SessionUserUtil.requireUser(session);
        TaskSummary task = pageTaskRepository.findById(id);
        if (task == null) {
            throw new IllegalArgumentException("Task not found");
        }
        return ApiResponse.ok(task, "Task detail");
    }

    @RequestMapping(value = "/tasks/{id}", method = RequestMethod.PUT)
    public ApiResponse<TaskSummary> update(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("assistantId") long assistantId,
            @RequestParam("pageRangeStart") int pageRangeStart,
            @RequestParam("pageRangeEnd") int pageRangeEnd,
            @RequestParam("taskType") String taskType,
            @RequestParam("dueDate") String dueDate) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can update task");

        pageTaskRepository.updateTaskByMangaka(
                id,
                user.getId(),
                assistantId,
                pageRangeStart,
                pageRangeEnd,
                taskType,
                Date.valueOf(dueDate));

        return ApiResponse.ok(pageTaskRepository.findById(id), "Task updated");
    }

    @RequestMapping(value = "/tasks/{id}/status", method = RequestMethod.PATCH)
    public ApiResponse<Object> updateStatus(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("status") String status) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "ASSISTANT", "Only ASSISTANT can update task status");
        pageTaskRepository.updateStatusByAssistant(id, user.getId(), status.toUpperCase());
        return ApiResponse.ok(null, "Task status updated");
    }

    @RequestMapping(value = "/tasks/{id}/approve", method = RequestMethod.POST)
    public ApiResponse<Object> approve(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can approve task");
        long ownerId = pageTaskRepository.getTaskOwnerMangaka(id);
        if (ownerId != user.getId()) {
            throw new IllegalArgumentException("Only task owner Mangaka can approve");
        }
        pageTaskRepository.approveByMangaka(id);
        return ApiResponse.ok(null, "Task approved");
    }

    @RequestMapping(value = "/tasks/{id}/reject", method = RequestMethod.POST)
    public ApiResponse<Object> reject(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can reject task");
        long ownerId = pageTaskRepository.getTaskOwnerMangaka(id);
        if (ownerId != user.getId()) {
            throw new IllegalArgumentException("Only task owner Mangaka can reject");
        }

        int rejectCount = pageTaskRepository.rejectByMangaka(id);
        if (rejectCount >= 3) {
            long tantouId = pageTaskRepository.getTaskTantouEditor(id);
            pageTaskRepository.createNotification(
                    tantouId,
                    "TASK_ESCALATED",
                    "Task #" + id + " reached 3 rejections and requires intervention.",
                    id,
                    "TASK");
        }

        return ApiResponse.ok(null, "Task rejected");
    }
}




