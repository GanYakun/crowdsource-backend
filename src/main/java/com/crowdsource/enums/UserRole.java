package com.crowdsource.enums;

import lombok.Getter;

@Getter
public enum UserRole {
    ADMIN(1, "管理员"),
    PUBLISHER(2, "发单人"),
    WORKER(3, "接单人");

    private final int code;
    private final String desc;

    UserRole(int code, String desc) {
        this.code = code;
        this.desc = desc;
    }
}
