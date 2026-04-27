package com.crowdsource.mapper;

import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface TaskTagMapper {

    @Insert("INSERT IGNORE INTO task_tag(task_id, tag_id) VALUES(#{taskId}, #{tagId})")
    void insert(@Param("taskId") Long taskId, @Param("tagId") Long tagId);

    @Delete("DELETE FROM task_tag WHERE task_id = #{taskId}")
    void deleteByTaskId(@Param("taskId") Long taskId);
}
