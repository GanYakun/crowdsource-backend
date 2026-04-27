package com.crowdsource.controller;

import com.crowdsource.common.Result;
import com.crowdsource.common.UserContext;
import com.crowdsource.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    /**
     * GET /api/notifications
     * 获取通知列表
     */
    @GetMapping
    public Result<?> list(@RequestParam(defaultValue = "1") int page,
                          @RequestParam(defaultValue = "20") int size) {
        Long userId = UserContext.getUserId();
        return Result.success(notificationService.list(userId, page, size));
    }

    /**
     * GET /api/notifications/unread-count
     * 未读通知数量
     */
    @GetMapping("/unread-count")
    public Result<?> unreadCount() {
        return Result.success(notificationService.countUnread(UserContext.getUserId()));
    }

    /**
     * PUT /api/notifications/read
     * 标记已读（不传 id 则全部已读）
     */
    @PutMapping("/read")
    public Result<?> markRead(@RequestParam(required = false) Long id) {
        notificationService.markRead(UserContext.getUserId(), id);
        return Result.success();
    }
}
