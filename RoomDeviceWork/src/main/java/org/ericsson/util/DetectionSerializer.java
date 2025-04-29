package org.ericsson.util;

public class DetectionSerializer {
    public byte[] serialize(DetectionModel.ImageDetections detections) {
        return detections.toByteArray();
    }

    // 反序列化
    public DetectionModel.ImageDetections deserialize(byte[] data) throws Exception {
        return DetectionModel.ImageDetections.parseFrom(data);
    }

    // 示例：构建检测结果
    public DetectionModel.ImageDetections buildSampleDetections() {
        DetectionModel.Detection detection1 = DetectionModel.Detection.newBuilder()
                .setClassId(1)
                .setConfidence(0.95f)
                .setXCenter(0.5f)
                .setYCenter(0.6f)
                .setWidth(0.2f)
                .setHeight(0.3f)
                .build();

        return DetectionModel.ImageDetections.newBuilder()
                .addDetections(detection1)
                .build();
    }
}
