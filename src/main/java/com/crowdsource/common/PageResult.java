package com.crowdsource.common;

import lombok.Data;
import java.util.List;

@Data
public class PageResult<T> {
    private long total;
    private List<T> list;

    public static <T> PageResult<T> of(long total, List<T> list) {
        PageResult<T> page = new PageResult<>();
        page.setTotal(total);
        page.setList(list);
        return page;
    }
}
