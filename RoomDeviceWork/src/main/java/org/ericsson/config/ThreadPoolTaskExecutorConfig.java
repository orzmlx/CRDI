package org.ericsson.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;

@Configuration
@Slf4j
public class ThreadPoolTaskExecutorConfig {
    @Bean(name = "taskExecutor")
    public ScheduledExecutorService taskExecutor(){
        ScheduledExecutorService scheduled = Executors.newScheduledThreadPool(300);
        return scheduled;
    }
}
