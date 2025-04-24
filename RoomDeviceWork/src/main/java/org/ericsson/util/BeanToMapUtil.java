package org.ericsson.util;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;

import java.beans.BeanInfo;
import java.beans.Introspector;
import java.beans.PropertyDescriptor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

@Slf4j
public class BeanToMapUtil {
    //Object转换成Map
    public static Map<String, Object> objectToMap(Object object) throws Exception {
        if (object == null) {
            return null;
        }
        Map<String, Object> map = new HashMap<String, Object>();
        try {
            Field[] declaredFields = object.getClass().getDeclaredFields();
            for (Field field : declaredFields) {
                field.setAccessible(true);
                if (field.get(object) != null && !"".equals(field.get(object).toString())) {
                    map.put(field.getName(), field.get(object));
                }
            }
        } catch (Exception e) {
            log.error("转map异常",e);
        }
        return map;
    }

    public static <T> T convertToObject(LinkedHashMap<String, Object> map, Class<T> clazz){
        ObjectMapper objectMapper = new ObjectMapper();
        T obj = objectMapper.convertValue(map, clazz);
        return obj;
    }
}