package org.ericsson.enums;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class TaskStatusEnum {
    private static Map<String, EnumBean> enumMap = new ConcurrentHashMap<>(1024);
    public static final String TODO="todo";//未开始
    public static final String EXECUTING="executing";//执行中
    public static final String COMPLETE="complete";//完成

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
        enumMap.put(COMPLETE, EnumBean.builder().code(COMPLETE).name("完成").build());
        //添加name获取枚举值
        enumMap.put("待分析", EnumBean.builder().code(TODO).name("待分析").build());
        enumMap.put("分析中", EnumBean.builder().code(EXECUTING).name("分析中").build());
        enumMap.put("完成", EnumBean.builder().code(COMPLETE).name("完成").build());
    }
}
