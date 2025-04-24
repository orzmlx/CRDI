package org.ericsson.quartz;

import lombok.extern.slf4j.Slf4j;
import org.ericsson.constant.QuartzConstant;
import org.quartz.JobKey;
import org.quartz.Scheduler;
import org.quartz.SchedulerException;
import org.quartz.TriggerKey;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class RefreshJob implements CommandLineRunner {
    @Autowired
    protected Scheduler scheduler;

    public String getJobName(String taskId){
        return String.format(QuartzConstant.JOB_NAME_PREFIX, taskId);
    }

    public String getTriggerName(String taskId){
        return String.format(QuartzConstant.TRIGGER_NAME_PREFIX, taskId);
    }

    public boolean checkExists(String taskId) throws SchedulerException {
        if(scheduler.checkExists(TriggerKey.triggerKey(getTriggerName(taskId), QuartzConstant.JOB_GROUP_NAME))){
            return true;
        }
        return false;
    }

    public void removeJob(String taskId) throws Exception {
        if(scheduler.checkExists(TriggerKey.triggerKey(getTriggerName(taskId), QuartzConstant.JOB_GROUP_NAME))) {
            JobKey jobKey = JobKey.jobKey(getJobName(taskId), QuartzConstant.JOB_GROUP_NAME);
            TriggerKey triggerKey = TriggerKey.triggerKey(getTriggerName(taskId), QuartzConstant.JOB_GROUP_NAME);
            scheduler.pauseTrigger(triggerKey);//停止触发器
            scheduler.unscheduleJob(triggerKey);//移除触发器
            scheduler.deleteJob(jobKey);//删除触发器
            log.info("移除调度任务【{}】", taskId);
        }
    }

    @Override
    public void run(String... args) throws Exception {
        //默认启动Scheduler
        scheduler.start();
    }
}
