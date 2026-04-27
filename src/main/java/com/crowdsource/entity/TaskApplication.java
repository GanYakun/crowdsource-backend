package com.crowdsource.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("task_application")
public class TaskApplication {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long taskId;
    private Long applicantId;
    private String message;
    private BigDecimal price;
    /** 1=待处理 2=已接受 3=已拒绝 */
    private Integer status;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
    
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}
