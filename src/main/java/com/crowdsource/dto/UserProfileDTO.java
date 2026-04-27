package com.crowdsource.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

@Data
public class UserProfileDTO {
    private String nickname;
    private String avatar;
    private Integer role;
    private String realName;
    private String bio;
    private List<String> techStack;
    private List<Long> skillTags;
    private BigDecimal priceMin;
    private BigDecimal priceMax;
    private List<String> preferTypes;
}
