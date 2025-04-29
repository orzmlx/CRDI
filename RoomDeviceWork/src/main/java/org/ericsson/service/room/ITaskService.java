package org.ericsson.service.room;

import com.baomidou.mybatisplus.extension.service.IService;
import org.ericsson.entity.room.Task;

public interface ITaskService extends IService<Task> {

    void saveTask(Task task) throws Exception;
}
