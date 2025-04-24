package org.ericsson.job;

import lombok.extern.slf4j.Slf4j;
import org.ericsson.constant.QuartzConstant;
import org.ericsson.entity.room.Task;
import org.ericsson.service.room.ITaskService;
import org.ericsson.util.DateUtil;
import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Date;

@Slf4j
@Component
public class CreateApcpTaskJob implements Job {
    @Autowired
    private ITaskService TaskService;

    private Date currentTime;

    @Override
    public void execute(JobExecutionContext jobExecutionContext) throws JobExecutionException {
        Task task = null;
        try {
            String taskId = (String) jobExecutionContext.getJobDetail().getJobDataMap().get(QuartzConstant.JOB_ID_KEY);
            task = TaskService.getById(taskId);

            execute_(task);
        } catch (Exception e) {
            log.error("定时任务CreateApcpTask执行异常，异常原因如下：", e);
        }
    }

    public void execute_(Task task) {
        currentTime = DateUtil.getCurrentDate();
    }
}