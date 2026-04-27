package com.crowdsource.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.crowdsource.common.PageResult;
import com.crowdsource.common.UserContext;
import com.crowdsource.dto.UserProfileDTO;
import com.crowdsource.entity.User;
import com.crowdsource.entity.UserProfile;
import com.crowdsource.mapper.UserMapper;
import com.crowdsource.mapper.UserProfileMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final UserProfileMapper userProfileMapper;

    /**
     * 获取当前用户信息（含 profile）
     */
    public Map<String, Object> getCurrentUser() {
        Long userId = UserContext.getUserId();
        User user = userMapper.selectById(userId);
        UserProfile profile = userProfileMapper.selectOne(
                new LambdaQueryWrapper<UserProfile>().eq(UserProfile::getUserId, userId));
        Map<String, Object> result = new HashMap<>();
        result.put("user", user);
        result.put("profile", profile);
        return result;
    }

    /**
     * 完善用户信息（首次登录选择角色、填写资料）
     */
    @Transactional
    public void updateProfile(UserProfileDTO dto) {
        Long userId = UserContext.getUserId();
        User user = userMapper.selectById(userId);

        if (dto.getNickname() != null) user.setNickname(dto.getNickname());
        if (dto.getAvatar() != null) user.setAvatar(dto.getAvatar());
        if (dto.getRole() != null) user.setRole(dto.getRole());
        userMapper.updateById(user);

        UserProfile profile = userProfileMapper.selectOne(
                new LambdaQueryWrapper<UserProfile>().eq(UserProfile::getUserId, userId));
        if (profile == null) {
            profile = new UserProfile();
            profile.setUserId(userId);
        }
        profile.setRealName(dto.getRealName());
        profile.setBio(dto.getBio());
        profile.setTechStack(dto.getTechStack());
        profile.setSkillTags(dto.getSkillTags());
        profile.setPriceMin(dto.getPriceMin());
        profile.setPriceMax(dto.getPriceMax());
        profile.setPreferTypes(dto.getPreferTypes());

        if (profile.getId() == null) {
            userProfileMapper.insert(profile);
        } else {
            userProfileMapper.updateById(profile);
        }
    }

    // ---- 管理员接口 ----

    public PageResult<User> listUsers(int page, int size, Integer status) {
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        if (status != null) wrapper.eq(User::getStatus, status);
        wrapper.orderByDesc(User::getCreatedAt);
        Page<User> pageResult = userMapper.selectPage(new Page<>(page, size), wrapper);
        return PageResult.of(pageResult.getTotal(), pageResult.getRecords());
    }

    public void updateUserStatus(Long userId, Integer status) {
        User user = new User();
        user.setId(userId);
        user.setStatus(status);
        userMapper.updateById(user);
    }
}
