package org.ericsson.controller.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.apache.commons.compress.utils.Lists;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class PhotoBody {
    //机房表的主键ID
    private Integer roomId;
    //照片文件
    private List<MultipartFile> photoFileList;
    //照片文件
    private List<MultipartFile> videoFileList;

    //图片/视频的主键Id
    private Integer photoVideoId;

    public List<MultipartFile> getPhotoFileList() {
        if (photoFileList == null) {
            return Lists.newArrayList();
        }
        List<MultipartFile> fileList = Lists.newArrayList();
        for (MultipartFile file : photoFileList) {
            if(file.getOriginalFilename() == null || "".equals(file.getOriginalFilename())){
                continue;
            }
            fileList.add(file);
        }
        return fileList;
    }

    public List<MultipartFile> getVideoFileList() {
        if (videoFileList == null) {
            return Lists.newArrayList();
        }
        List<MultipartFile> fileList = Lists.newArrayList();
        for (MultipartFile file : videoFileList) {
            if(file.getOriginalFilename() == null || "".equals(file.getOriginalFilename())){
                continue;
            }
            fileList.add(file);
        }
        return fileList;
    }
}
