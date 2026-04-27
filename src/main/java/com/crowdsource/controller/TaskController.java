package com.crowdsource.controller;

import com.crowdsource.common.Result;
import com.crowdsource.dto.ApplicationDTO;
import com.crowdsource.dto.TaskDTO;
import com.crowdsource.dto.TaskQueryDTO;
import com.crowdsource.service.TaskService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    /**
     * POST /api/tasks
     * 发布任务（发单人）
     */
    @PostMapping
    public Result<?> publish(@Valid @RequestBody TaskDTO dto) {
        return Result.success(taskService.publishTask(dto));
    }

    /**
     * GET /api/tasks
     * 分页查询任务列表（支持关键词/类型/预算/标签筛选）
     */
    @GetMapping
    public Result<?> list(TaskQueryDTO query) {
        return Result.success(taskService.listTasks(query));
    }

    /**
     * GET /api/tasks/{id}
     * 任务详情
     */
    @GetMapping("/{id}")
    public Result<?> detail(@PathVariable Long id) {
        return Result.success(taskService.getTaskDetail(id));
    }

    /**
     * GET /api/tasks/recommend
     * 推荐任务（按接单人技术栈匹配）
     */
    @GetMapping("/recommend")
    public Result<?> recommend(@RequestParam(defaultValue = "1") int page,
                               @RequestParam(defaultValue = "10") int size) {
        return Result.success(taskService.recommendTasks(page, size));
    }

    /**
     * POST /api/tasks/{id}/apply
     * 申请接单
     */
    @PostMapping("/{id}/apply")
    public Result<?> apply(@PathVariable Long id, @RequestBody ApplicationDTO dto) {
        taskService.applyTask(id, dto.getMessage(), dto.getPrice());
        return Result.success();
    }

    /**
     * POST /api/tasks/applications/{applicationId}/handle
     * 发单人处理申请（accept=true/false）
     */
    @PostMapping("/applications/{applicationId}/handle")
    public Result<?> handleApplication(@PathVariable Long applicationId,
                                       @RequestParam boolean accept) {
        taskService.handleApplication(applicationId, accept);
        return Result.success();
    }

    /**
     * POST /api/tasks/{id}/complete
     * 发单人标记任务完成
     */
    @PostMapping("/{id}/complete")
    public Result<?> complete(@PathVariable Long id) {
        taskService.completeTask(id);
        return Result.success();
    }
}
