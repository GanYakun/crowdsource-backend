package com.crowdsource.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("tag")
public class Tag {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String name;
    private String category;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
