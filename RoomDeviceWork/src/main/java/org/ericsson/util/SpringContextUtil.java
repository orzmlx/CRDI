package org.ericsson.util;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.stereotype.Component;

import java.util.Locale;

@Slf4j
@Component
public class SpringContextUtil implements ApplicationContextAware {

    public static ApplicationContext applicationContext;

    @Override
    public void setApplicationContext(ApplicationContext applicationContext)
            throws BeansException {
        SpringContextUtil.applicationContext = applicationContext;
    }

    public static Object getBean(String name) {
        return applicationContext.getBean(name);
    }

    public static <T> T getBean(String name, Class<T> requiredType) {
        return applicationContext.getBean(name, requiredType);
    }

    public static boolean containsBean(String name) {
        return applicationContext.containsBean(name);
    }

    public static boolean isSingleton(String name) {
        return applicationContext.isSingleton(name);
    }

    public static Class<? extends Object> getType(String name) {
        return applicationContext.getType(name);
    }

    /**
     * @param beanName bean Id
     * @return 如果获取失败，则返回Null
     * @author Elwin ZHANG
     * 创建时间：2016年4月14日 上午9:52:55
     * 功能：通过BeanId获取Spring管理的对象
     */
    public static Object getObject(String beanName) {
        Object object = null;
        try {
            object = applicationContext.getBean(beanName);
        } catch (Exception e) {
            log.error(e.toString());
        }
        return object;
    }


    /**
     * @return
     * @author Elwin ZHANG
     * 创建时间：2017年3月7日 下午3:44:38
     * 功能：获取Spring的ApplicationContext
     */
    public static ApplicationContext getContext() {
        return applicationContext;
    }

    /**
     * @param clazz 要获取的Bean类
     * @return 如果获取失败，则返回Null
     * @author Elwin ZHANG
     * 创建时间：2016年4月14日 上午10:05:27
     * 功能：通过类获取Spring管理的对象
     */
    public static <T> T getObject(Class<T> clazz) {
        try {
            return applicationContext.getBean(clazz);
        } catch (Exception e) {
            log.error(e.toString());
        }
        return null;
    }

    /**
     * @param code 配置文件中消息提示的代码
     * @param locale 当前的语言环境
     * @return 当前语言对应的消息内容
     * @author Elwin ZHANG
     * 创建时间：2016年4月14日 上午10:34:25
     * 功能：获取当前语言对应的消息内容
     */
    public static String getMessage(String code, Locale locale){
        String message;
        try{
            message=applicationContext.getMessage(code, null, locale);
        }catch(Exception e){
            log.error(e.toString());
            message="";
        }
        return message;
    }

    /**
     * @author: chenliang
     * @time: 2019/6/27 16:05
     * @description:根据标记返回当前接口实现类
     */
    public static String[] getServices(Class<?> interfaceClass){
        return applicationContext.getBeanNamesForType(interfaceClass);
    }
}