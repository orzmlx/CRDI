package org.ericsson.constant;

import lombok.Data;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Data
@Component
public class ApplicationConstant {
    public static String curdir;
    public static String saveUrl;
    public static String imagesHttpUrl;
//    /*注入变量赋值*/
//    @Value("${CURDIR:/opt/runwork/room/}")
//    public void setCurdir(String value){ ApplicationConstant.curdir = value; }
    @Value("${images.save.url}")
    public void setSaveUrl(String value){
        ApplicationConstant.saveUrl = value;
    }
    @Value("${images.http.url}")
    public void setImagesHttpUrl(String value) {
        ApplicationConstant.imagesHttpUrl = value;
    }
}
