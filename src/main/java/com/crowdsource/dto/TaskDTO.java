package com.crowdsource.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
public class TaskDTO {
    @NotBlank
    private String title;
    
    @NotBlank
    private String description;
    
    @NotBlank
    private String type;
    
    @NotNull
    private BigDecimal budgetMin;
    
    @NotNull
    private BigDecimal budgetMax;
    
    private LocalDate deadline;
    
    /** 关联的标签ID列表 */
    private List<Long> tagIds;
}
