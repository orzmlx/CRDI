package org.ericsson.exception;

public class BaseException extends RuntimeException{
    protected String code;
    public BaseException(String message){super(message);this.code="400";};

    public String getCode() {
        return code;
    }
    public void setCode(String code) {
        this.code = code;
    }
}
