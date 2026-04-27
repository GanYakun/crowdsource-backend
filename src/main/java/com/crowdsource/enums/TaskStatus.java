package com.crowdsource.enums;

import lombok.Getter;

@Getter
public enum TaskStatus {
    PENDING_REVIEW(1, "待审核"),
    RECRUITING(2, "招募中"),
    IN_PROGRESS(3, "进行中"),
    COMPLETED(4, "已完成"),
    OFFLINE(5, "已下架");

    private final int code;
    private final String desc;

    TaskStatus(int code, String desc) {
        this.code = code;
        this.desc = desc;
    }
}
