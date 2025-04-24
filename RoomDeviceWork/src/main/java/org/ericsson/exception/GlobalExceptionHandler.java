package org.ericsson.exception;


import cn.hutool.json.JSONException;
import lombok.extern.slf4j.Slf4j;
import org.ericsson.util.ResultRest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.sql.SQLException;
import java.sql.SQLSyntaxErrorException;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(BusinessException.class)
    public ResultRest handlerBusinessException(BusinessException ex){
        log.error("业务异常【{}】", ex.getMessage());
        return ResultRest.fail("业务异常【"+ex.getMessage()+"】");
    }

    @ExceptionHandler(SQLSyntaxErrorException.class)
    public ResultRest handlerSQLException(SQLSyntaxErrorException ex){
        log.error("SQL错误【{}】", ex.getMessage());
        return ResultRest.fail("SQL语句错误【"+ex.getMessage()+"】");
    }


    @ExceptionHandler(SQLException.class)
    public ResultRest handlerSQLException(SQLException ex){
        log.error("SQL错误【{}】", ex.getMessage());
        return ResultRest.fail("SQL语句错误【"+ex.getMessage()+"】");
    }

    @ExceptionHandler(JSONException.class)
    public ResultRest handlerJSONException(JSONException ex){
        log.error("JSON转换异常【{}】", ex.getMessage());
        return ResultRest.fail("JSON转换错误【"+ex.getMessage()+"】");
    }

    @ExceptionHandler(BaseException.class)
    public ResultRest handlerBaseException(BaseException ex){
        log.error("主要异常");
        return ResultRest.fail("主要异常【"+ex.getMessage()+"】");
    }

    @ExceptionHandler(NullPointerException.class)
    public ResultRest handlerTypeMismatchException(NullPointerException ex){
        log.error("空指针异常，{}",ex);
        return ResultRest.fail("空指针错误【"+HttpStatus.INTERNAL_SERVER_ERROR.getReasonPhrase()+"】");
    }

    @ExceptionHandler(Exception.class)
    public ResultRest handlerUnexpectedServerException(Exception ex){
        log.error("系统处理异常,{}",ex.getMessage(),ex);
        return ResultRest.fail("系统处理异常【"+ex.getMessage()+"】");
    }
}
