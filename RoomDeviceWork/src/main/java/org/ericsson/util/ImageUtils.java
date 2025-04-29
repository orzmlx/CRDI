package org.ericsson.util;

import ai.onnxruntime.OnnxTensor;
import ai.onnxruntime.OrtEnvironment;
import nu.pattern.OpenCV;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.InputStream;
import java.nio.FloatBuffer;
import org.opencv.core.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.imgcodecs.Imgcodecs;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
@Component
public class ImageUtils {


    // YOLO 输入尺寸（根据模型要求调整）
    public static final int MODEL_INPUT_WIDTH = 1024;
    public static final int MODEL_INPUT_HEIGHT = 1024;
    public static final int CHANNELS = 3; // RGB 三通道



    static {
        // 加载 OpenCV 本地库（根据实际路径调整）
        OpenCV.loadLocally();
        // 若部署环境无本地库，可用以下方式动态加载：
        // nu.pattern.OpenCV.loadLocally();
    }

    /**
     * YOLO 预处理主方法
     * @param file 上传的图片文件
     * @param targetSize 模型输入尺寸（如 640）
     * @return 预处理后的张量数据（形状 [1, 3, H, W]）
     */
    public static Mat preprocess(MultipartFile file, int targetSize) throws IOException {
        // 1. 读取图片为 OpenCV Mat（BGR 格式）
        Mat image = readMultipartFileToMat(file);

        // 2. 调整尺寸并填充灰边
        Mat resized = resizeWithPadding(image, targetSize, new Scalar(114, 114, 114));

        // 3. 归一化到 [0,1] 并转换通道顺序为 RGB
        Mat normalized = normalizeAndSwapChannels(resized);

        // 4. 转换为 CHW 格式（OpenCV 默认 HWC）
        return convertHWCtoCHW(normalized);
    }

    /**
     * 将 MultipartFile 转换为 OpenCV Mat
     */
    private static Mat readMultipartFileToMat(MultipartFile file) throws IOException {
        byte[] bytes = file.getBytes();
        return Imgcodecs.imdecode(new MatOfByte(bytes), Imgcodecs.IMREAD_COLOR);
    }

    /**
     * 保持宽高比调整尺寸，填充灰边
     */
    private static Mat resizeWithPadding(Mat src, int targetSize, Scalar padColor) {
        // 计算缩放比例
        int srcH = src.rows();
        int srcW = src.cols();
        double scale = Math.min((double) targetSize / srcW, (double) targetSize / srcH);

        // 缩放后的尺寸
        int scaledW = (int) (srcW * scale);
        int scaledH = (int) (srcH * scale);

        // 缩放图像
        Mat resized = new Mat();
        Imgproc.resize(src, resized, new Size(scaledW, scaledH), 0, 0, Imgproc.INTER_LINEAR);

        // 创建填充后的图像
        Mat padded = new Mat(targetSize, targetSize, CvType.CV_8UC3, padColor);

        // 计算填充位置
        int dx = (targetSize - scaledW) / 2;
        int dy = (targetSize - scaledH) / 2;

        // 将缩放后的图像复制到填充区域
        resized.copyTo(padded.submat(new Rect(dx, dy, scaledW, scaledH)));
        return padded;
    }

    /**
     * 归一化到 [0,1] 并转换通道顺序为 RGB
     */
    private static Mat normalizeAndSwapChannels(Mat src) {
        // 转换为浮点型并归一化
        Mat normalized = new Mat();
        src.convertTo(normalized, CvType.CV_32FC3, 1.0 / 255.0);

        // BGR -> RGB
        Core.split(normalized, new ArrayList<Mat>() {{
            add(new Mat()); // R
            add(new Mat()); // G
            add(new Mat()); // B
        }});

        Mat rgb = new Mat();
        Core.merge(new ArrayList<Mat>() {{
            add(get(2)); // B -> R
            add(get(1)); // G -> G
            add(get(0)); // R -> B
        }}, rgb);

        return rgb;
    }

    /**
     * 将 HWC 格式转换为 CHW 格式
     */
    private static Mat convertHWCtoCHW(Mat hwc) {
        int h = hwc.rows();
        int w = hwc.cols();
        int c = hwc.channels();

        // 分离通道
        List<Mat> channels = new ArrayList<>();
        Core.split(hwc, channels);

        // 合并为 CHW 格式
        Mat chw = new Mat();
        for (Mat channel : channels) {
            chw.push_back(channel.reshape(1, h * w));
        }

        return chw.reshape(1, c).t(); // 最终形状 [1, c, h, w]
    }

    /**
     * 将 MultipartFile 转换为 YOLO 可识别的归一化张量
     */
    public static OnnxTensor processForYOLO(MultipartFile file,int target_width,int target_height) throws Exception {
        // 1. 将 MultipartFile 转为 BufferedImage
        InputStream inputStream = file.getInputStream();
        BufferedImage image = ImageIO.read(inputStream);
        inputStream.close();

        // 2. 调整尺寸并保持宽高比（填充灰边）
        BufferedImage resized = resizeWithPadding(image, target_width, target_height, new Color(114, 114, 114));

        // 3. 转换为浮点数组并归一化到 [0,1]
        float[] normalizedData = normalizePixels(resized);

        // 4. 构建 ONNX 张量
        OrtEnvironment env = OrtEnvironment.getEnvironment();
        return OnnxTensor.createTensor(
                env,
                FloatBuffer.wrap(normalizedData),
                new long[]{1, CHANNELS, target_width, target_height} // NCHW 格式
        );
    }

    /**
     * 调整图片尺寸并填充灰边（保持宽高比）
     */
    private static BufferedImage resizeWithPadding(BufferedImage source, int targetWidth, int targetHeight, Color padColor) {
        BufferedImage scaled = new BufferedImage(targetWidth, targetHeight, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = scaled.createGraphics();
        g.setColor(padColor);
        g.fillRect(0, 0, targetWidth, targetHeight);

        // 计算缩放比例
        double scale = Math.min(
                (double) targetWidth / source.getWidth(),
                (double) targetHeight / source.getHeight()
        );
        int scaledWidth = (int) (source.getWidth() * scale);
        int scaledHeight = (int) (source.getHeight() * scale);

        // 计算填充位置
        int x = (targetWidth - scaledWidth) / 2;
        int y = (targetHeight - scaledHeight) / 2;

        // 绘制缩放后的图像
        g.drawImage(source.getScaledInstance(scaledWidth, scaledHeight, Image.SCALE_SMOOTH), x, y, null);
        g.dispose();
        return scaled;
    }

    /**
     * 归一化像素值到 [0,1] 并转换为 CHW 顺序
     */
    private static float[] normalizePixels(BufferedImage image) {
        int width = image.getWidth();
        int height = image.getHeight();
        float[] data = new float[CHANNELS * width * height];
        int[] pixels = image.getRGB(0, 0, width, height, null, 0, width);

        for (int i = 0; i < pixels.length; i++) {
            int pixel = pixels[i];
            // 分解 RGB 通道（注意 OpenCV 模型可能需要 BGR 顺序）
            data[i * 3] = ((pixel >> 16) & 0xFF) / 255.0f; // R
            data[i * 3 + 1] = ((pixel >> 8) & 0xFF) / 255.0f;  // G
            data[i * 3 + 2] = (pixel & 0xFF) / 255.0f;         // B
        }
        return data;
    }
}
