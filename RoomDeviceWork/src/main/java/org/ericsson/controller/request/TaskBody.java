package org.ericsson.controller.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.web.multipart.MultipartFile;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class TaskBody {
    /** 公共配置 **/
    private String taskName;//非空 任务名称
    private String city;//非空 任务地市（英文）
    private String taskType;//非空 任务类型（regular，condition）
    private String yesNoNotRisk;//非空 是否无风险脚本
    private String yesNoRepeat;//非空 是否重复执行
    private String createUser;//非空
    private MultipartFile mosFile;//非空 执行的mos文件
    private MultipartFile siteCellFile;//非空 站点小区文件

    /** 在APCP创建任务需要的配置 **/
    private Integer profileId;//非空 场景ID
    private String priority;//非空 优先级（紧急、优先、普通）
    private Integer overTime;//非空 超时时间（单位h）
    private Integer concurrency=30;//非空 并发数量
    public Integer getConcurrency() { return concurrency==null||"".equals(concurrency)?30:concurrency; }
    private String yesNoCheck;//非空 是否Check(Y/N)
    private String yesNoCvback;//非空 是否CV备份(Y/N)
    private String yesNoSeconedExec;//非空 是否二次执行(Y/N)
    private String errorKeywordId;//需要检查的错误关键字(用;分隔)

    /** 唯一场景:任务类型为regular且重复执行为N的配置 **/
    private String execTime;//执行时间 yyyy-MM-dd HH:mm:ss
    public String getExecTime() { return "".equals(execTime)?null:execTime; }


    /** （场景1:任务类型为condition，场景2:任务类型为regular且重复执行为Y）的配置 **/
    private String startTime;//任务有效开始时间
    public String getStartTime() { return "".equals(startTime)?null:startTime; }
    private String endTime;//任务有效结束时间
    public String getEndTime() { return "".equals(endTime)?null:endTime; }

    /** 任务重复执行的配置 **/
    private Integer intervalDayNum;//间隔天数 （场景1:任务类型为regular，场景2:任务类型为condition）且重复执行为Y，且执行方式为间隔天数
    private String execWeek;//周几 （场景1:任务类型为regular，场景2:任务类型为condition）且重复执行为Y，且执行方式为周几
    public String getExecWeek() { return "".equals(execWeek)?null:execWeek; }
    //此字段只有固定时间触发需要
    private String execHourMinute;//任务执行时间HH:mm 场景：任务类型为regular且重复执行为Y
    public String getExecHourMinute() { return "".equals(execHourMinute)?null:execHourMinute; }

    /** 观察指标配置 **/
    private String kpiTimeDim;//监控时间粒度（1分钟、5分钟、15分钟）
    private Integer kpiActivityTaskId;//大屏已存在的监控任务ID
    private MultipartFile kpiFile;//监控的站点列表文件
    private Integer kpiTemplateId;//监控的指标的模板ID

    /** 条件任务，指标监控的配置 **/
    private String timeDim;//监控时间粒度（1分钟、5分钟、15分钟）
    private Integer timeInterval;//时间区间
    private Integer exceedingTimes;//满足次数
    private Integer activityTaskId;//大屏已存在的监控任务ID
    private MultipartFile conditionFile;//监控的站点列表文件
    private Integer coreTemplateId;//监控的指标的模板ID

    /** 自定义指标对比配置 **/
    private String yesNoEnableCustomContrast;//是否开启自定义指标对比(Y/N)
    private String contrastNameEns;//对比指标
    private String contrastMode;//对比方式(占比:ratio, 差值:diff)
    private String contrastExpression;//比对符号(>、>=等)
    private String contrastThreshold;//对比门限(占比的时候为百分比)
    private MultipartFile contrastFile;//对比站点列表
}
