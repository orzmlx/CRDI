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
@TableName(value = "room_task")
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Task {
    @TableId(value = "task_id", type = IdType.AUTO)
    private Integer taskId;
    @TableField(value = "task_name")
    private String taskName;
    @TableField(value = "task_status")
    private String taskStatus;
    @TableField(value = "create_time")
    @DateTimeFormat(pattern="yyyy-MM-dd HH:mm:ss")
    private Date createTime;
    @TableField(value = "task_remark")
    private String task_remark;
}
