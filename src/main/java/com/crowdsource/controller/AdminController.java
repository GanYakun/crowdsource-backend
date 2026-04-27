package com.crowdsource.controller;

import com.crowdsource.common.Result;
import com.crowdsource.common.UserContext;
import com.crowdsource.service.TaskService;
import com.crowdsource.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final TaskService taskService;
    private final UserService userService;

    // ---- 任务管理 ----

    /**
     * GET /api/admin/tasks
     * 查看所有任务（可按状态筛选）
     */
    @GetMapping("/tasks")
    public Result<?> listTasks(@RequestParam(defaultValue = "1") int page,
                               @RequestParam(defaultValue = "10") int size,
                               @RequestParam(required = false) Integer status) {
        checkAdmin();
        return Result.success(taskService.adminListTasks(page, size, status));
    }

    /**
     * POST /api/admin/tasks/{id}/review
     * 审核任务（approve=true 通过，false 拒绝）
     */
    @PostMapping("/tasks/{id}/review")
    public Result<?> reviewTask(@PathVariable Long id, @RequestParam boolean approve) {
        checkAdmin();
        taskService.reviewTask(id, approve);
        return Result.success();
    }

    /**
     * POST /api/admin/tasks/{id}/offline
     * 下架任务
     */
    @PostMapping("/tasks/{id}/offline")
    public Result<?> offlineTask(@PathVariable Long id) {
        checkAdmin();
        taskService.offlineTask(id);
        return Result.success();
    }

    // ---- 用户管理 ----

    /**
     * GET /api/admin/users
     * 查看用户列表
     */
    @GetMapping("/users")
    public Result<?> listUsers(@RequestParam(defaultValue = "1") int page,
                               @RequestParam(defaultValue = "10") int size,
                               @RequestParam(required = false) Integer status) {
        checkAdmin();
        return Result.success(userService.listUsers(page, size, status));
    }

    /**
     * PUT /api/admin/users/{id}/status
     * 启用/禁用用户（status: 1=正常 2=禁用）
     */
    @PutMapping("/users/{id}/status")
    public Result<?> updateUserStatus(@PathVariable Long id, @RequestParam Integer status) {
        checkAdmin();
        userService.updateUserStatus(id, status);
        return Result.success();
    }

    private void checkAdmin() {
        if (!Integer.valueOf(1).equals(UserContext.getRole())) {
            throw new RuntimeException("无管理员权限");
        }
    }
}
