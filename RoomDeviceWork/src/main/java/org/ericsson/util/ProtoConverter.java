package org.ericsson.util;

import com.ericsson.protobuf.DetectionModel;
import org.ericsson.entity.inference.InferenceResult;

public class ProtoConverter {
    // Java对象转Protobuf
    public static DetectionModel.Detection toProto(InferenceResult obj) {
        return DetectionModel.Detection.newBuilder()
                .setXCenter(obj.getX())
                .setYCenter(obj.getY())
                .setWidth(obj.getWidth())
                .setHeight(obj.getHeight())
                .setClassId(obj.getClassId())
                .setConfidence(obj.getMaxClassProb())
                .build();
    }

    // Protobuf转Java对象
    public static InferenceResult fromProto(DetectionModel.Detection proto) {
        return new InferenceResult()
                .setX(proto.getXCenter())
                .setY(proto.getYCenter())
                .setWidth(proto.getWidth())
                .setHeight(proto.getHeight())
                .setClassId(proto.getClassId())
                .setMaxClassProb(proto.getConfidence());
    }
}