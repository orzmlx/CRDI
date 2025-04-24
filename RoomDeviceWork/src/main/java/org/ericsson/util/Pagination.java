package org.ericsson.util;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class Pagination<T> {
    /**
     * 当前页数
     */
    private int pageNumber;
    /**
     * 总页数
     */
    private int totalPages;

    /**
     * 每页条数
     */
    private int pageSize;

    /**
     * 总条数
     */
    private long totalElements;

    /**
     * 忽略数据条数
     */
    private int offset;

    /**
     * 列表数据
     */
    private List<T> content = new ArrayList<>();

    public Pagination() {
    }

    public int getPageNumber() {
        return pageNumber == 0 ? 1 : pageNumber;
    }

    public int getOffset() {
        return pageSize * (getPageNumber() - 1);
    }

    public int getTotalPages() {
        return Double.valueOf(Math.ceil((double) totalElements / (double) pageSize)).intValue();
    }
}
