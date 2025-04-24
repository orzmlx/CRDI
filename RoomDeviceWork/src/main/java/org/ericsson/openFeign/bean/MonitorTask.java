package org.ericsson.openFeign.bean;

import com.baomidou.mybatisplus.annotation.TableField;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class MonitorTask {
    private String taskName;
    private String city;
    private String taskType;

    private String createUser;
    private String startTime;
    private String endTime;


    /** 观察指标配置 **/
    private String kpiTimeDim;//观察指标配置的运行周期（1分钟、5分钟、15分钟）
    private Integer kpiActivityTaskId;//大屏已存在的监控任务ID
    private String kpiSiteIp;//用,分隔
    private Integer kpiTemplateId;


    /** 条件任务触发执行需要的配置 **/
    private String yesNoRepeat;

    private Integer intervalDayNum;//间隔天数
    private String execWeek;//周几

    private String timeDim;
    private Integer timeInterval;
    private Integer exceedingTimes;
    private Integer activityTaskId;
    private String siteIp;//用,分隔
    private Integer coreTemplateId;

    private String contrastNameEns;
    private String contrastMode;
    private String contrastExpression;
    private String contrastThreshold;
    private String contrastSite;

    private String generatorTaskId;
}
