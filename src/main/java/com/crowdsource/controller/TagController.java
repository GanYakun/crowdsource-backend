package com.crowdsource.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.crowdsource.common.Result;
import com.crowdsource.entity.Tag;
import com.crowdsource.mapper.TagMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/tags")
@RequiredArgsConstructor
public class TagController {

    private final TagMapper tagMapper;

    /**
     * GET /api/tags
     * 获取所有标签（无需登录）
     */
    @GetMapping
    public Result<?> list(@RequestParam(required = false) String category) {
        LambdaQueryWrapper<Tag> wrapper = new LambdaQueryWrapper<>();
        if (category != null) wrapper.eq(Tag::getCategory, category);
        return Result.success(tagMapper.selectList(wrapper));
    }
}
