package org.ericsson.exception;

public enum ErrorCode {
    // 通用错误码
    INTERNAL_ERROR("500", "系统内部错误"),
    INVALID_PARAM("400", "参数校验失败"),
    RESOURCE_NOT_FOUND("404", "资源不存在"),

    // 业务错误码（示例）
    TASK_CREATE_FAILED("T001", "任务创建失败"),
    FILE_UPLOAD_LIMIT("F001", "文件大小超过限制"),
    TASK_SAVE_ERROR("T002", "任务保存失败"),
    NO_VALID_FILES("T003","上传消息必须包含至少一个媒体文件");

    private final String code;
    private final String message;

    ErrorCode(String code, String message) {
        this.code = code;
        this.message = message;
    }

    public String getCode() { return code; }
    public String getMessage() { return message; }
}