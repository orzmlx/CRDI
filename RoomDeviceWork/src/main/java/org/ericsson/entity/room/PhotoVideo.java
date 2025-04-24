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
@TableName(value = "room_photo_video")
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class PhotoVideo {
    @TableId(value = "photo_video_id", type = IdType.AUTO)
    private Integer photoVideoId;
    @TableField(value = "task_id")
    private Integer taskId;
    @TableField(value = "room_id")
    private Integer roomId;
    @TableField(value = "file_type")
    private String fileType;
    @TableField(value = "file_path")
    private String filePath;
    @TableField(value = "identify_status")
    private String identifyStatus;  //未开始:todo 分析中:executing 成功:succeed 失败:failed
    @TableField(value = "identify_content")
    private String identifyContent;
    @TableField(value = "create_time")
    @DateTimeFormat(pattern="yyyy-MM-dd HH:mm:ss")
    private Date createTime;
    @TableField(value = "update_time")
    @DateTimeFormat(pattern="yyyy-MM-dd HH:mm:ss")
    private Date updateTime;
}
