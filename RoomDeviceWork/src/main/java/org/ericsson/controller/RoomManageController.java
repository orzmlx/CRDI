package org.ericsson.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.ericsson.service.room.IRoomService;
import org.ericsson.util.ResultRest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@Api("机房管理")
@RestController
@RequestMapping("RoomManage")
public class RoomManageController {
    @Autowired
    private IRoomService RoomService;

    @PostMapping("/queryRoom")
    @ApiOperation(value = "查询机房列表", httpMethod="POST")
    public ResultRest queryRoom() {
        //入参的参数校验
        ResultRest output = null;
        try{
            output = ResultRest.ok(RoomService.list());
        }catch (Exception e){
            return ResultRest.fail("查看机房列表错误，错误原因："+e.getMessage());
        }
        //响应结果
        return output;
    }
}
