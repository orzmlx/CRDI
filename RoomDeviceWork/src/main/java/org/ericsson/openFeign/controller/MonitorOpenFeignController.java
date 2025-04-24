package org.ericsson.openFeign.controller;

import lombok.extern.slf4j.Slf4j;
import org.ericsson.util.ResultRest;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
@RequestMapping("monitorOpenFeign")
public class MonitorOpenFeignController {

    @RequestMapping("/createTask")
    public ResultRest createTask(@RequestParam("taskId") String taskId){
        return ResultRest.ok();
    }
}
