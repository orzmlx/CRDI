package org.ericsson.entity.room;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;

import java.util.Date;

@Data
@TableName(value = "room")
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Room {
    @TableId(value = "room_id", type = IdType.AUTO)
    private Integer roomId;
    @TableField(value = "room_name")
    private String roomName;
    @TableField(value = "create_time")
    @DateTimeFormat(pattern="yyyy-MM-dd HH:mm:ss")
    private Date createTime;
}
