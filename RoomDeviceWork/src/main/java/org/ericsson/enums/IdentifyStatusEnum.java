package org.ericsson.enums;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class IdentifyStatusEnum {
    private static Map<String, EnumBean> enumMap = new ConcurrentHashMap<>(1024);
    public static final String TODO="todo";//待分析
    public static final String EXECUTING="executing";//分析中
    public static final String SUCCEED="succeed";//成功
    public static final String FAILED="failed";//失败

    public static EnumBean get(String key){
        return enumMap.get(key);
    }

    public static boolean containsKey(String key){
        return enumMap.containsKey(key);
    }

    static {
        //添加code获取枚举值
        enumMap.put(TODO, EnumBean.builder().code(TODO).name("待分析").build());
        enumMap.put(EXECUTING, EnumBean.builder().code(EXECUTING).name("分析中").build());
        enumMap.put(SUCCEED, EnumBean.builder().code(SUCCEED).name("成功").build());
        enumMap.put(FAILED, EnumBean.builder().code(FAILED).name("失败").build());
        //添加name获取枚举值
        enumMap.put("待分析", EnumBean.builder().code(TODO).name("待分析").build());
        enumMap.put("分析中", EnumBean.builder().code(EXECUTING).name("分析中").build());
        enumMap.put("成功", EnumBean.builder().code(SUCCEED).name("成功").build());
        enumMap.put("失败", EnumBean.builder().code(SUCCEED).name("失败").build());
    }
}
