package org.ericsson.mapper.roomMapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.ericsson.entity.room.Task;

@Mapper
public interface TaskMapper extends BaseMapper<Task> {
//    @SelectProvider(value = TaskMapperSql.class, method = "queryTask")
}
