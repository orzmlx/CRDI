package org.ericsson.exception;

public class BusinessException extends BaseException {
    public BusinessException(String message){super(message);code="500";}
}
