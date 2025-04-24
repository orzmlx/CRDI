package org.ericsson.util;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.experimental.Accessors;

import java.io.Serializable;

@Data
@ToString
@NoArgsConstructor
@AllArgsConstructor
@Accessors(chain = true)
@ApiModel(value = "响应信息主体")
public class ResultRest<T> implements Serializable {
    private static final long serialVersionUID = 1L;

    /**
     * 成功标记
     */
    private static Integer SUCCESS = 200;
    /**
     * 失败标记
     */
    private static Integer FAIL = 500;

    @ApiModelProperty(value = "返回标记：成功标记=200，失败标记=500")
    private int code;

    @ApiModelProperty(value = "返回信息")
    private String msg;

    @ApiModelProperty(value = "数据")
    private T data;

    public static <T> ResultRest<T> ok() {
        return restResult(null, SUCCESS, null);
    }

    public static <T> ResultRest<T> ok(T data) {
        return restResult(data, SUCCESS, null);
    }

    public static <T> ResultRest<T> ok(T data, String msg) {
        return restResult(data, SUCCESS, msg);
    }

    public static <T> ResultRest<T> fail() {
        return restResult(null, FAIL, null);
    }

    public static <T> ResultRest<T> fail(String msg) {
        return restResult(null, FAIL, msg);
    }

    public static <T> ResultRest<T> fail(T data) {
        return restResult(data, FAIL, null);
    }

    public static <T> ResultRest<T> fail(T data, String msg) {
        return restResult(data, FAIL, msg);
    }

    private static <T> ResultRest<T> restResult(T data, int code, String msg) {
        ResultRest<T> apiResult = new ResultRest<>();
        apiResult.setCode(code);
        apiResult.setData(data);
        apiResult.setMsg(msg);
        return apiResult;
    }

    public void setCode(int code) {
        if(code == 0 || code == 200){
            this.code = 200;
        }else{
            this.code = 500;
        }
    }
}
