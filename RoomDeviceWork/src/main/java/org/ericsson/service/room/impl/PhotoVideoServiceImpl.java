package org.ericsson.service.room.impl;

import ai.onnxruntime.OnnxTensor;
import cn.hutool.core.lang.Console;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.compress.utils.Lists;
import org.ericsson.constant.ApplicationConstant;
import org.ericsson.controller.request.PhotoBody;
import org.ericsson.entity.inference.InferenceResult;
import org.ericsson.entity.room.PhotoVideo;
import org.ericsson.mapper.roomMapper.PhotoVideoMapper;
import org.ericsson.service.algo.IReferenceService;
import org.ericsson.service.room.IPhotoVideoService;
import org.ericsson.service.room.ITaskService;
import org.ericsson.util.FileOperationUtil;
import org.ericsson.util.ImageUtils;
import org.mybatis.logging.Logger;
import org.mybatis.logging.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import java.util.Date;
import java.util.List;
@Slf4j
@Service
public class PhotoVideoServiceImpl extends ServiceImpl<PhotoVideoMapper, PhotoVideo> implements IPhotoVideoService {


    @Autowired
    private ITaskService TaskService;
    @Autowired
    private IReferenceService referenceService;
    @Override
    public List<PhotoVideo> queryPhoto(PhotoBody body) throws Exception {
        if(body.getRoomId() == null){
            return super.list(Wrappers.lambdaQuery(PhotoVideo.class).orderByAsc(PhotoVideo::getCreateTime));
        }
        return super.list(Wrappers.lambdaQuery(PhotoVideo.class).eq(PhotoVideo::getRoomId, body.getRoomId()).orderByAsc(PhotoVideo::getCreateTime));
    }
    private InferenceResult imageInference(List<MultipartFile> photoFileList){
        for (MultipartFile multipartFile : photoFileList) {
            //上传文件到知道服务器的指定目录，存放静态文件
            //生成图片数据对象
            try {
                OnnxTensor imageTensor = ImageUtils.processForYOLO(multipartFile,1024,1024);
                List<InferenceResult> inferenceRes = referenceService.inference(imageTensor);
                Console.print("Inference Result: " + inferenceRes);


            } catch (Exception e) {
                e.printStackTrace();
            }

        }
        return null;
    }
    @Override
    @Transactional
    public void uploadPhoto(PhotoBody body) throws Exception{
        Date currentDate = new Date();
        //获取图片列表、视频列表
        List<MultipartFile> photoFileList = body.getPhotoFileList();
        List<MultipartFile> videoFileList = body.getVideoFileList();
        //图片视频对象列表
        List<PhotoVideo> photoVideoList = Lists.newArrayList();
        // 目录不存在，则创建
        String photoSaveBorder = ApplicationConstant.saveUrl+"/photo";
        FileOperationUtil.createBorder(photoSaveBorder);
        String videoSaveBorder = ApplicationConstant.saveUrl+"/video/";
        FileOperationUtil.createBorder(videoSaveBorder);
        log.info("收到图片数量:{}", photoFileList.size());
        log.info("收到视频数量:{}", videoFileList.size());
       // imageInference(photoFileList);
        //遍历图片，添加到图片视频列表
//        for(MultipartFile multipartFile : photoFileList){
//            //上传文件到知道服务器的指定目录，存放静态文件
//            //生成图片数据对象
//            PhotoVideo photoVideo = new PhotoVideo();
//            photoVideo.setRoomId(body.getRoomId());
//            photoVideo.setIdentifyStatus(IdentifyStatusEnum.TODO);
//            photoVideo.setFileType(FileTypeEnum.PHOTO);
//            photoVideo.setFilePath(ApplicationConstant.imagesHttpUrl+"/photo/"+multipartFile.getOriginalFilename());
//            photoVideo.setCreateTime(currentDate);
//            photoVideo.setUpdateTime(currentDate);
//            //添加到图片视频对象列表
//            photoVideoList.add(photoVideo);
//            //保存文件
//            FileOperationUtil.saveFile(multipartFile, photoSaveBorder+"/"+multipartFile.getOriginalFilename());
//        }
//        //遍历视频，添加到图片视频列表
//        for(MultipartFile multipartFile : videoFileList){
//            //上传文件到知道服务器的指定目录，存放静态文件
//            //生成图片数据对象
//            PhotoVideo photoVideo = new PhotoVideo();
//            photoVideo.setRoomId(body.getRoomId());
//            photoVideo.setFileType(FileTypeEnum.VIDEO);
//            photoVideo.setIdentifyStatus(IdentifyStatusEnum.TODO);
//            photoVideo.setFilePath(ApplicationConstant.imagesHttpUrl+"/video/"+multipartFile.getOriginalFilename());
//            photoVideo.setCreateTime(currentDate);
//            photoVideo.setUpdateTime(currentDate);
//            //添加到图片视频对象列表
//            photoVideoList.add(photoVideo);
//            //保存文件
 //          FileOperationUtil.saveFile(multipartFile, videoSaveBorder+"/"+multipartFile.getOriginalFilename());
//        }
        //生成当次任务
//        Task task = new Task();
//        task.setTaskName("图片视频识别_"+ DateUtil.format(currentDate, "yyyyMMddHHmmss"));
//        task.setTaskStatus(TaskStatusEnum.TODO);
//        task.setCreateTime(currentDate);
//        //保存数据
//        TaskService.save(task);
//
//        //根据任务名称，查询任务ID
//        Task task_ = TaskService.getOne(Wrappers.lambdaQuery(Task.class).eq(Task::getTaskName, task.getTaskName()));
//        //循环，添加任务ID
//        for (PhotoVideo photoVideo : photoVideoList) {
//            photoVideo.setTaskId(task_.getTaskId());
//        }
//        //保存数据
//        super.saveBatch(photoVideoList);
    }
}
