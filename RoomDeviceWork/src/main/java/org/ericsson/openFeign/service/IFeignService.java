package org.ericsson.openFeign.service;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.stereotype.Component;

@Component
@FeignClient(value = "${monitor_feign_name:cp-monitor}")
//@FeignClient(name = "example", url = "http://serein20.e3.luyouxia.net:12210")
public interface IFeignService {
    //接收对象有文件时，参数consumes = MediaType.MULTIPART_FORM_DATA_VALUE
}

