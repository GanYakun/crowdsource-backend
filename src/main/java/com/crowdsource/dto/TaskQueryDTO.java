package com.crowdsource.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

@Data
public class TaskQueryDTO {
    private String keyword;
    private String type;
    private BigDecimal budgetMin;
    private BigDecimal budgetMax;
    private List<Long> tagIds;
    private Integer status;
    private int page = 1;
    private int size = 10;
}
