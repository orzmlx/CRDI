//package org.ericsson.quartz;
//
//import com.baomidou.mybatisplus.core.toolkit.Wrappers;
//import lombok.extern.slf4j.Slf4j;
//import org.ericsson.constant.Constants;
//import org.ericsson.constant.QuartzConstant;
//import org.ericsson.entity.room.Task;
//import org.ericsson.enums.TaskStateEnum;
//import org.ericsson.enums.TaskTypeEnum;
//import org.ericsson.job.CreateApcpTaskJob;
//import org.ericsson.service.IUtilService;
//import org.ericsson.service.room.ITaskService;
//import org.ericsson.util.DateUtil;
//import org.quartz.JobBuilder;
//import org.quartz.JobDataMap;
//import org.quartz.JobDetail;
//import org.quartz.TriggerBuilder;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.scheduling.annotation.Scheduled;
//import org.springframework.stereotype.Component;
//
//import java.util.Date;
//import java.util.List;
//
//@Slf4j
//@Component
//public class RefreshRegularJob extends RefreshJob {
//    private Date currentDate = null;
//
//    @Autowired
//    private ITaskService TaskService;
//    @Autowired
//    private IUtilService UtilService;
//
//    @Override
//    public void run(String... args) throws Exception {
//        //默认启动Scheduler
//        super.run();
//        log.info("程序启动加载一次Job任务...开始");
//        execute();
//        log.info("程序启动加载一次Job任务...结束");
//    }
//
//    @Scheduled(cron = "10 0/5 * * * ?")
//    public void execute(){
//        try{
//            currentDate = DateUtil.getCurrentDate();
//            execute_1();
//            execute_2();
//            execute_3();
//        }catch (Exception e){
//            log.error("【{}】刷新固定时间触发任务异常，原因如下：", DateUtil.formatDate(currentDate), e);
//        }
//    }
//
//    //不重复执行的
//    private void execute_1() throws Exception {
//        List<Task> taskList = TaskService.list(Wrappers.lambdaQuery(Task.class).eq(Task::getTaskType, TaskTypeEnum.REGULAR_TIGGER).eq(Task::getYesNoRepeat, Constants.NO));
//        //循环遍历任务
//        for(Task task : taskList){
//            //第一：非正常运行
//            if(!TaskStateEnum.NORMAL.equals(task.getTaskState())){
//                removeJob(task.getTaskId());
//                continue;
//            }
//            //校验此任务是否已经存在
//            if(checkExists(task.getTaskId())){
//                continue;
//            }
//            //执行时间
//            Date execTime = DateUtil.parseDate(task.getExecTime());
//            //创建一个新的任务
//            createJob(task, execTime);
//        }
//    }
//    //重复执行，且为周几模式的
//    private void execute_2() throws Exception {
//        List<Task> taskList = TaskService.list(Wrappers.lambdaQuery(Task.class).eq(Task::getTaskType, TaskTypeEnum.REGULAR_TIGGER).eq(Task::getYesNoRepeat, Constants.YES).isNotNull(Task::getExecWeek).ne(Task::getExecWeek, ""));
//        //循环遍历任务
//        for(Task task : taskList){
//            //第一：非正常运行
//            if(!TaskStateEnum.NORMAL.equals(task.getTaskState())){
//                removeJob(task.getTaskId());
//                continue;
//            }
//            //校验此任务是否已经存在
//            if(checkExists(task.getTaskId())){
//                continue;
//            }
//            if(currentDate.getTime() > task.getEndTime().getTime()){
//                removeJob(task.getTaskId());
//                continue;
//            }
//            //获取执行时间
//            List<String> cronList = UtilService.getCronList(task.getExecWeekCron(), 1);
//            if(cronList.size() <= 0){
//                continue;
//            }
//            Date execTime = DateUtil.parseDate(cronList.get(0));
//            if(!(execTime.getTime() >= task.getStartTime().getTime() && execTime.getTime() <= task.getEndTime().getTime())){
//                log.error("任务【{}】已不再有效运行时间范围内", task.getTaskName());
//                continue;
//            }
//            //创建一个新的任务
//            createJob(task, execTime);
//        }
//    }
//    //重复执行，且为间隔几天运行的
//    private void execute_3() throws Exception {
//        List<Task> taskList = TaskService.list(Wrappers.lambdaQuery(Task.class).eq(Task::getTaskType, TaskTypeEnum.REGULAR_TIGGER).eq(Task::getYesNoRepeat, Constants.YES).isNotNull(Task::getIntervalDayNum).ne(Task::getIntervalDayNum, ""));
//        //循环遍历任务
//        for(Task task : taskList){
//            //第一：非正常运行
//            if(!TaskStateEnum.NORMAL.equals(task.getTaskState())){
//                removeJob(task.getTaskId());
//                continue;
//            }
//            //校验此任务是否已经存在
//            if(checkExists(task.getTaskId())){
//                continue;
//            }
//            if(currentDate.getTime() > task.getEndTime().getTime()){
//                removeJob(task.getTaskId());
//                continue;
//            }
//            //获取执行时间
//            Date startTime = task.getStartTime();
//            Date execTime_one = DateUtil.parseDate(DateUtil.format(startTime, "yyyy-MM-dd")+" "+ task.getExecHourMinute()+":00");
//            if(execTime_one.getTime() < startTime.getTime()){//当天的执行时间点，不在有效时间范围内，第一次触发时间点顺延到下一天
//                execTime_one = new Date(execTime_one.getTime()+24*3600*1000);
//            }
//            //在第一次执行时间点上，进行时间间隔的叠加
//            Date execTime = execTime_one;//默认为第一次执行时间
//            while (true){
//                if(execTime.getTime() > currentDate.getTime() || execTime.getTime() > task.getEndTime().getTime()){
//                    break;
//                }
//                execTime = new Date(execTime.getTime()+ task.getIntervalDayNum()*24*3600*1000);
//            }
//            if(!(execTime.getTime() >= task.getStartTime().getTime() && execTime.getTime() <= task.getEndTime().getTime())){
//                log.error("任务【{}】已不再有效运行时间范围内", task.getTaskName());
//                continue;
//            }
//            //创建一个新的任务
//            createJob(task, execTime);
//        }
//    }
//
//    public void createJob(Task task, Date execTime) throws Exception {
//        Date currentTime = DateUtil.getCurrentDate();
//        if(!(currentTime.getTime() <= execTime.getTime() && execTime.getTime()-currentTime.getTime()<=20*60*1000)){
//            log.info("任务【{}:{}】等待下次扫描加入调度", task.getTaskId(), task.getTaskName());
//            return;
//        }
//
//        //开始添加任务
//        JobDataMap jobDetailMap = new JobDataMap(); jobDetailMap.put(QuartzConstant.JOB_ID_KEY, task.getTaskId());
//        //Job参数
//        JobDetail jobDetail = JobBuilder.newJob(CreateApcpTaskJob.class).withIdentity(getJobName(task.getTaskId()), QuartzConstant.JOB_GROUP_NAME).usingJobData(jobDetailMap).build();
//        //添加到scheduler
//        this.scheduler.scheduleJob(jobDetail, TriggerBuilder.newTrigger().withIdentity(getTriggerName(task.getTaskId()), QuartzConstant.JOB_GROUP_NAME).startAt(execTime).build());
//        log.info("加入调度任务【{}:{}:{}】", task.getTaskId(), task.getTaskName(), task.getExecTime());
//    }
//}
//
