package org.ericsson.service.room;

import com.baomidou.mybatisplus.extension.service.IService;
import org.ericsson.controller.request.PhotoBody;
import org.ericsson.entity.room.Task;

public interface ITaskService extends IService<Task> {

    String saveTask(PhotoBody photoBody) throws Exception;
}
