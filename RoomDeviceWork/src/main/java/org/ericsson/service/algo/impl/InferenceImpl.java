package org.ericsson.service.algo.impl;

import ai.onnxruntime.OnnxTensor;
import ai.onnxruntime.OrtEnvironment;
import ai.onnxruntime.OrtException;
import ai.onnxruntime.OrtSession;
import org.ericsson.entity.inference.InferenceResult;
import org.ericsson.service.algo.IReferenceService;
import org.ericsson.util.ImageUtils;
import org.opencv.core.Mat;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;


import java.nio.FloatBuffer;
import java.util.*;

@Service
public class InferenceImpl implements IReferenceService {
    // Implement the methods defined in IInferenceService here
    // For example:

    private int inputHeight = 1024;
    private int inputWidth = 1024;
    private int targetHeight = 640;
    private int targetWidth = 640;
    private static OrtEnvironment env = OrtEnvironment.getEnvironment();


    private OnnxTensor preprocessImage(MultipartFile file) throws Exception {
        Mat preprocessed = ImageUtils.preprocess(file, targetHeight);
        float[] inputData = new float[(int) preprocessed.total()];

        long[] inputShape = {1, 3, inputHeight, inputWidth}; // 输入形状 [batch, channels, height, width]
        OnnxTensor inputTensor = OnnxTensor.createTensor(env, FloatBuffer.wrap(inputData), inputShape);
        return inputTensor;

    }

    @Override
    public InferenceResult getInferenceResultById(String id) {
        // Implementation logic to retrieve inference result by ID
        return null; // Replace with actual implementation
    }

    //非极大值抑制（NMS）算法,删除重叠度大于阈值的框
    //参考https://github.com/tharushaudana/YOLO11S-TFLite-Android-Java/blob/master/app/src/main/java/com/tharusha/tfliteyolo/YOLODetector.java
    private List<InferenceResult> applyNMS(List<InferenceResult> detections, float iouThreshold) {
        Collections.sort(detections, new Comparator<InferenceResult>() {
            @Override
            public int compare(InferenceResult d1, InferenceResult d2) {
                return Float.compare(d2.getMaxClassProb(), d1.getMaxClassProb());
            }
        });

        List<InferenceResult> finalDetections = new ArrayList<>();

        while (!detections.isEmpty()) {
            InferenceResult bestDetection = detections.remove(0);
            finalDetections.add(bestDetection);

            detections.removeIf(d -> computeIoU(bestDetection, d) > iouThreshold);
        }

        return finalDetections;
    }

    private float computeIoU(InferenceResult box1, InferenceResult box2) {
        float x1 = Math.max(box1.getX(), box2.getX());
        float y1 = Math.max(box1.getY(), box2.getY());
        float x2 = Math.min(box1.getX() + box1.getWidth(), box2.getX() + box2.getWidth());
        float y2 = Math.min(box1.getY() + box1.getHeight(), box2.getY() + box2.getHeight());

        float intersection = Math.max(0, x2 - x1) * Math.max(0, y2 - y1);
        float box1Area = box1.getWidth() * box1.getHeight();
        float box2Area = box2.getWidth() * box2.getHeight();

        float union = box1Area + box2Area - intersection;
        return union > 0 ? intersection / union : 0;
    }
    @Override
    public List<InferenceResult> inference(OnnxTensor imageTensor) throws OrtException {
        OrtSession session = null;
        try {
             session = env.createSession("/Users/meiliuxi/Desktop/room_device-master/RoomDeviceWork/src/main/java/org/ericsson/algo/algomodel/bestModel.onnx", new OrtSession.SessionOptions());
             String inputName = session.getInputNames().iterator().next();
             String outputName = session.getOutputNames().iterator().next();

            // 4. 运行推理
            OrtSession.Result result = session.run(Collections.singletonMap(inputName, imageTensor));

            // 5. 解析输出
            if (result.get(outputName).isPresent()) {
                OnnxTensor outputTensor = (OnnxTensor) result.get(outputName).get(); // ✅ 正确提取 Optional
                float[][][] output = (float[][][]) outputTensor.getValue();
                // 假设 output 是形状为 [1][84][8400] 的输出张量
                int classNum = output[0].length; // 3
                int numChannels = output[0][0].length; // 21504
                int headNum  = numChannels / classNum;
                float confidenceThreshold = 0.5f;
                List<InferenceResult> detections = new ArrayList<>();
                // 6. 遍历每个检测框
                for (int i = 0; i < numChannels; i++) {

                    float centerX = output[0][0][i];
                    float centerY = output[0][1][i];
                    float width = output[0][2][i];
                    float height = output[0][3][i];
                    float objectness = output[0][4][i];

                    // 计算每个类别的置信度
                    float maxClassProb = 0;
                    int classId = -1;
                    for (int c = 0; c < classNum; c++) {
                        float classProb = output[0][5 + c][i];
                        float confidence = objectness * classProb;
                        if (confidence > maxClassProb) {
                            maxClassProb = confidence;
                            classId = c;
                        }
                    }

                    if (maxClassProb > confidenceThreshold) {
                        // 将中心点坐标转换为左上角坐标
                        float x = centerX - width / 2;
                        float y = centerY - height / 2;
                        detections.add(new InferenceResult(x, y, width, height, classId, maxClassProb));
                    }

                }
                return applyNMS(detections, 0.5f); // 应用 NMS
            } else {
                throw new OrtException("模型未返回输出张量");
            }
        } catch (OrtException e) {
            e.printStackTrace();
            throw new OrtException("推理失败: " + e.getMessage());
        }finally {
            // 7. 释放资源（反向关闭顺序）
            if (session != null) session.close();
            if (env != null) env.close();
        }
    }

}
