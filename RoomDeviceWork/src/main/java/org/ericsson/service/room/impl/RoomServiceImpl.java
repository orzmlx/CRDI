package org.ericsson.service.room.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.ericsson.entity.room.Room;
import org.ericsson.mapper.roomMapper.RoomMapper;
import org.ericsson.service.room.IRoomService;
import org.springframework.stereotype.Service;

@Service
public class RoomServiceImpl extends ServiceImpl<RoomMapper, Room> implements IRoomService {
}
