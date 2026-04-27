package com.crowdsource.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.crowdsource.config.JwtUtil;
import com.crowdsource.dto.LoginDTO;
import com.crowdsource.entity.User;
import com.crowdsource.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserMapper userMapper;
    private final JwtUtil jwtUtil;

    /** 内存存储短信验证码，key=phone, value=[code, expireTimestamp] */
    private final ConcurrentHashMap<String, long[]> smsCodeStore = new ConcurrentHashMap<>();
    private static final long SMS_EXPIRE_MS = 5 * 60 * 1000L;

    /**
     * 登录（微信/手机号），不存在则自动注册
     */
    public Map<String, Object> login(LoginDTO dto) {
        User user;
        if ("wechat".equals(dto.getLoginType())) {
            // TODO: 调用微信接口用 code 换取 openId
            String openId = mockGetOpenId(dto.getCode());
            user = getOrCreateByOpenId(openId);
        } else {
            // 验证短信验证码
            validateSmsCode(dto.getPhone(), dto.getSmsCode());
            user = getOrCreateByPhone(dto.getPhone());
        }

        String token = jwtUtil.generateToken(user.getId(), user.getRole());
        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("userId", user.getId());
        result.put("role", user.getRole());
        result.put("isNewUser", user.getNickname() == null || user.getNickname().startsWith("用户"));
        return result;
    }

    /**
     * 发送短信验证码（模拟）
     */
    public void sendSmsCode(String phone) {
        // TODO: 接入短信服务商
        String code = String.valueOf((int) ((Math.random() * 9 + 1) * 100000));
        long expire = Instant.now().toEpochMilli() + SMS_EXPIRE_MS;
        smsCodeStore.put(phone, new long[]{Long.parseLong(code), expire});
        System.out.println("【模拟短信】手机号 " + phone + " 验证码：" + code);
    }

    private void validateSmsCode(String phone, String inputCode) {
        long[] entry = smsCodeStore.get(phone);
        if (entry == null || Instant.now().toEpochMilli() > entry[1]) {
            throw new RuntimeException("验证码已过期，请重新获取");
        }
        if (!String.valueOf(entry[0]).equals(inputCode)) {
            throw new RuntimeException("验证码错误");
        }
        smsCodeStore.remove(phone);
    }

    private User getOrCreateByOpenId(String openId) {
        User user = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getOpenId, openId));
        if (user == null) {
            user = new User();
            user.setOpenId(openId);
            user.setNickname("用户" + openId.substring(openId.length() - 6));
            user.setRole(2);
            user.setStatus(1);
            userMapper.insert(user);
        }
        return user;
    }

    private User getOrCreateByPhone(String phone) {
        User user = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getPhone, phone));
        if (user == null) {
            user = new User();
            user.setPhone(phone);
            user.setNickname("用户" + phone.substring(phone.length() - 4));
            user.setRole(2);
            user.setStatus(1);
            userMapper.insert(user);
        }
        return user;
    }

    private String mockGetOpenId(String code) {
        // TODO: 替换为真实微信接口调用
        return "mock_openid_" + code;
    }
}
