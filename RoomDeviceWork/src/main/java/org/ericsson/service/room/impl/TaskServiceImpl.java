package org.ericsson.service.room.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.google.protobuf.ServiceException;

import lombok.extern.slf4j.Slf4j;

import org.apache.ibatis.exceptions.PersistenceException;
import org.ericsson.controller.request.PhotoBody;
import org.ericsson.entity.room.Task;
import org.ericsson.enums.FileTypeEnum;
import org.ericsson.enums.TaskStatusEnum;
import org.ericsson.exception.BusinessException;
import org.ericsson.exception.ErrorCode;
import org.ericsson.mapper.roomMapper.TaskMapper;
import org.ericsson.service.room.ITaskService;
import org.springframework.stereotype.Service;

import java.io.File;
import java.time.LocalDateTime;
@Slf4j
@Service
public class TaskServiceImpl extends ServiceImpl<TaskMapper, Task> implements ITaskService {


    @Override
    public String saveTask(PhotoBody photoBody) throws Exception {
        // 参数校验
        if (photoBody == null) {
            throw new IllegalArgumentException("PhotoBody cannot be null");
        }
        int photo_size = photoBody.getPhotoFileList().size();
        int video_size = photoBody.getVideoFileList().size();
        // 业务校验
        if (photo_size == 0 && video_size==0) {
            throw new BusinessException(ErrorCode.NO_VALID_FILES);
        }
        String taskType = FileTypeEnum.UNKNOWN;
        if (photo_size > 0 && video_size > 0) {
            // 任务类型为图片和视频
            taskType = FileTypeEnum.PHOTO_VIDEO;
        } else if (photo_size > 0) {
            // 任务类型为图片
            taskType = FileTypeEnum.PHOTO;
        } else if (video_size > 0) {
            // 任务类型为视频
            taskType = FileTypeEnum.VIDEO;
        }
        Task task = new Task();
        task.setRoomId(photoBody.getRoomId());

        task.setTask_remark(taskType);
        task.setCreateTime(LocalDateTime.now());
        task.setTaskStatus(TaskStatusEnum.TODO);
        task.setTaskName(photoBody.getRoomId());

        try {
            if (!save(task)) {
               // throw new PersistenceException("任务保存失败");
                log.error("任务保存失败");
                return null;
            }else {
                log.info("成功创建任务, 任务ID: {}", task.getTaskId());
                return task.getTaskId();  // 返回任务唯一标识
            }
        } catch (Exception e) {
            log.error("任务保存异常: {}", e.getMessage(), e);
            throw new BusinessException(ErrorCode.TASK_SAVE_ERROR);
        }


    }
}
