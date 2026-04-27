package com.crowdsource.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("notification")
public class Notification {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    /** NEW_TASK / MATCH / APPLY_RESULT / TASK_UPDATE */
    private String type;
    private String title;
    private String content;
    private Long refId;
    private Integer isRead;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
