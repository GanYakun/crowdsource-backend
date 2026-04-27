package com.crowdsource.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.math.BigDecimal;

@Data
public class ApplicationDTO {
    @NotNull
    private Long taskId;
    private String message;
    private BigDecimal price;
}
