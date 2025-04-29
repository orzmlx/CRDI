package org.ericsson.util;// 示例格式：20231015-1001-01-0001
// 说明：日期(8位) + 机器ID(4位) + 时间戳后4位 + 序列号(4位)

import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.atomic.AtomicInteger;
@Component
public class TaskIdGenerator {
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMdd");
    private static final String MACHINE_ID = "1001"; // 从配置中心或环境变量获取
    private static final AtomicInteger sequence = new AtomicInteger(0);

    public static String generate() {
        String date = LocalDate.now().format(DATE_FORMATTER);
        long timestampSuffix = System.currentTimeMillis() % 10000; // 取时间戳后4位
        int seq = sequence.getAndIncrement() % 10000; // 序列号循环
        return String.format("%s-%s-%04d-%04d", date, MACHINE_ID, timestampSuffix, seq);
    }
}