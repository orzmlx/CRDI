package org.ericsson;

import com.github.jeffreyning.mybatisplus.conf.EnableMPP;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.scheduling.annotation.EnableScheduling;

import javax.annotation.PostConstruct;
import java.util.TimeZone;

/**
 * All rights Reserved, Designed By www.ericsson.com
 *
 * @author liangchen
 * @version V1.0
 * @projectName Generator
 * @title GeneratorAutomation
 * @package org.eric.generator
 * @description
 * @date 2024/1/5 10:27
 * @copyright 2024 www.ericsson.com
 * 注意 本内容仅限于 爱立信（中国）通信有限公司，禁止外泄以及用于其他的商业
 */
@Slf4j
@EnableMPP
@EnableScheduling
@EnableFeignClients
@SpringBootApplication
public class RoomDeviceMain {

    //设置时区 相差8小时
    @PostConstruct
    void started() {
        TimeZone.setDefault(TimeZone.getTimeZone("GMT+8"));
    }

    public static void main(String[] args) {
        try {
            SpringApplication.run(RoomDeviceMain.class, args);
        }catch (Throwable e){
            log.error("主程序启动运行异常，停止程序，", e);
            System.exit(0);
        }
    }
}
