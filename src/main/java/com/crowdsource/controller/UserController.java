package com.crowdsource.controller;

import com.crowdsource.common.Result;
import com.crowdsource.common.UserContext;
import com.crowdsource.dto.UserProfileDTO;
import com.crowdsource.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * GET /api/user/me
     * 获取当前用户信息
     */
    @GetMapping("/me")
    public Result<?> getMe() {
        return Result.success(userService.getCurrentUser());
    }

    /**
     * PUT /api/user/profile
     * 完善/更新用户资料（含选择角色）
     */
    @PutMapping("/profile")
    public Result<?> updateProfile(@RequestBody UserProfileDTO dto) {
        userService.updateProfile(dto);
        return Result.success();
    }
}
