package com.crowdsource.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.crowdsource.entity.Tag;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.util.List;

@Mapper
public interface TagMapper extends BaseMapper<Tag> {
    @Select("SELECT t.* FROM tag t INNER JOIN task_tag tt ON t.id = tt.tag_id WHERE tt.task_id = #{taskId}")
    List<Tag> selectByTaskId(@Param("taskId") Long taskId);
}
