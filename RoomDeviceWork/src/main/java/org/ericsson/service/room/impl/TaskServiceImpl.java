package org.ericsson.service.room.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.ericsson.entity.room.Task;
import org.ericsson.mapper.roomMapper.TaskMapper;
import org.ericsson.service.room.ITaskService;
import org.springframework.stereotype.Service;

@Service
public class TaskServiceImpl extends ServiceImpl<TaskMapper, Task> implements ITaskService {
}
