package org.ericsson.config;

import org.ericsson.constant.ApplicationConstant;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * 用于在测试期间，图片视频、访问宿主机本地路径
 * */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/room/images/**") // 访问路径前缀
                .addResourceLocations("file:" + ApplicationConstant.saveUrl+"/"); // 本地目录映射
    }
}
