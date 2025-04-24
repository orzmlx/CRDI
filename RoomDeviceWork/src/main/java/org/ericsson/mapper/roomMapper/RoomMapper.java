package org.ericsson.mapper.roomMapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.ericsson.entity.room.Room;

@Mapper
public interface RoomMapper extends BaseMapper<Room> {
}
