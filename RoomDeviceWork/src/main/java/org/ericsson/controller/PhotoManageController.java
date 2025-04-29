package org.ericsson.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.ericsson.controller.request.PhotoBody;
import org.ericsson.service.room.IPhotoVideoService;
import org.ericsson.util.ResultRest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@Api("图片管理")
@RestController
@RequestMapping("PhotoManage")
public class PhotoManageController {
    @Autowired
    private IPhotoVideoService PhotoVideoService;
    @PostMapping("/uploadPhoto")
    @ApiOperation(value = "上传照片/视频", httpMethod="POST")
    public ResultRest uploadPhoto(PhotoBody photoBody) {
        //入参的参数校验
        if(photoBody.getPhotoFileList().size() <= 0 && photoBody.getVideoFileList().size() <= 0){ return ResultRest.fail("【照片文件和视频文件】不能同时为空"); }
        ResultRest output = null;
        try{
            PhotoVideoService.uploadPhoto(photoBody);
            //上传成功
            output = ResultRest.ok();
        }catch (Exception e){
            return ResultRest.fail("上传文件错误，错误原因："+e.getMessage());
        }
        //响应结果
        return output;
    }
    @GetMapping("/queryPhoto")
    @ApiOperation(value = "查询照片/视频列表", httpMethod="GET")
    public ResultRest queryPhoto(PhotoBody photoBody) {
        //入参的参数校验

        ResultRest output = null;
        try{
            output = ResultRest.ok(PhotoVideoService.queryPhoto(photoBody));
        }catch (Exception e){
            return ResultRest.fail("查看照片/视频列表错误，错误原因："+e.getMessage());
        }
        //响应结果
        return output;
    }

    @PostMapping("/queryIdentifyResult")
    @ApiOperation(value = "查询照片/视频的识别结果", httpMethod="POST")
    public ResultRest queryIdentifyResult(PhotoBody photoBody) {
        //入参的参数校验
        if(photoBody.getPhotoVideoId() == null || photoBody.getPhotoVideoId().intValue()<=0){ return ResultRest.fail("【照片/视频Id】不能为空"); }

        ResultRest output = null;
        try{
            output = ResultRest.ok(PhotoVideoService.getById(photoBody.getPhotoVideoId()));
        }catch (Exception e){
            return ResultRest.fail("查看识别结果错误，错误原因："+e.getMessage());
        }
        //响应结果
        return output;
    }
}
