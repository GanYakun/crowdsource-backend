package com.crowdsource.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginDTO {
    /** 登录类型: wechat / phone */
    @NotBlank
    private String loginType;

    /** 微信登录时传 code */
    private String code;

    /** 手机号登录时传手机号+验证码 */
    private String phone;
    private String smsCode;
}
