package org.ericsson.exception;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

public class BusinessException extends BaseException {
    private static final long serialVersionUID = 1L;
    private final ErrorCode errorCode;
    private final LocalDateTime timestamp;
    private Map<String, Object> context = new HashMap<>();
    // 基础构造器
    public BusinessException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
        this.timestamp = LocalDateTime.now();
    }

}
