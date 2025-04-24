package org.ericsson.service.room;

import com.baomidou.mybatisplus.extension.service.IService;
import org.ericsson.controller.request.PhotoBody;
import org.ericsson.entity.room.PhotoVideo;

import java.io.IOException;
import java.util.List;

public interface IPhotoVideoService extends IService<PhotoVideo> {
    List<PhotoVideo> queryPhoto(PhotoBody body) throws Exception;
    void uploadPhoto(PhotoBody body) throws Exception;
}
