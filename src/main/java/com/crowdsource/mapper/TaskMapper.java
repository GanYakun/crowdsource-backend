package com.crowdsource.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.crowdsource.dto.TaskQueryDTO;
import com.crowdsource.entity.Task;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface TaskMapper extends BaseMapper<Task> {
    /**
     * 按条件分页查询任务（支持标签过滤）
     */
    IPage<Task> selectTaskPage(Page<Task> page, @Param("q") TaskQueryDTO query);

    /**
     * 按接单人技术栈推荐任务
     */
    IPage<Task> recommendTasks(Page<Task> page, @Param("userId") Long userId);
}
