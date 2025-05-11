package org.ericsson.enums;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class FileTypeEnum {
    private static Map<String, EnumBean> enumMap = new ConcurrentHashMap<>(1024);
    public static final String PHOTO="photo";//照片
    public static final String VIDEO="video";//视频
    public static final String PHOTO_VIDEO="photo_video";//照片和视频
    public static final String UNKNOWN="unknown";//未知

    public static EnumBean get(String key){
        return enumMap.get(key);
    }

    public static boolean containsKey(String key){
        return enumMap.containsKey(key);
    }

    static {
        //添加code获取枚举值
        enumMap.put(PHOTO, EnumBean.builder().code(PHOTO).name("照片").build());
        enumMap.put(VIDEO, EnumBean.builder().code(VIDEO).name("视频").build());
        enumMap.put(PHOTO_VIDEO, EnumBean.builder().code(PHOTO_VIDEO).name("照片和视频").build());
        //添加name获取枚举值
        enumMap.put("照片", EnumBean.builder().code(PHOTO).name("照片").build());
        enumMap.put("视频", EnumBean.builder().code(VIDEO).name("视频").build());
        enumMap.put("照片和视频", EnumBean.builder().code(PHOTO_VIDEO).name("照片和视频").build());
    }
}
