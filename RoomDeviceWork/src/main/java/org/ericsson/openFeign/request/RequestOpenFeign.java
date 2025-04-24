package org.ericsson.openFeign.request;

import lombok.extern.slf4j.Slf4j;
import org.ericsson.entity.room.Task;
import org.ericsson.util.ResultRest;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class RequestOpenFeign {

    public ResultRest CreateTask(Task task){
        ResultRest result = null;
        try{
//            //封裝请求对象
//            MonitorTask monitorTask = task.parseMonitorTask();
//            log.info("接口【monitor/realtimeNetwork/createTask】请求参数【{}】", monitorTask);
//            //调用接口
//            result = MonitorFeignService.CreateTask(monitorTask);
//            log.info("接口【monitor/realtimeNetwork/createTask】输出结果【{}】", result);
        }catch (Exception e){
            log.error("Monitor创建指标监控任务【{}】异常，异常原因如下：", task.getTaskName(), e);
            result = ResultRest.fail("Monitor创建指标监控任务，异常原因："+e.getMessage());
        }
        return result;
    }
}
