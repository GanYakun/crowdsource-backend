package com.crowdsource.controller;

import com.crowdsource.common.Result;
import com.crowdsource.dto.LoginDTO;
import com.crowdsource.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /**
     * POST /api/auth/login
     * 登录（微信/手机号）
     */
    @PostMapping("/login")
    public Result<?> login(@Valid @RequestBody LoginDTO dto) {
        return Result.success(authService.login(dto));
    }

    /**
     * POST /api/auth/sms/send
     * 发送短信验证码
     */
    @PostMapping("/sms/send")
    public Result<?> sendSms(@RequestParam String phone) {
        authService.sendSmsCode(phone);
        return Result.success();
    }
}
