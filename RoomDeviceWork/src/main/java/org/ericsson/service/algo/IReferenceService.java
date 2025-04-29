package org.ericsson.service.algo;

import ai.onnxruntime.OnnxTensor;
import ai.onnxruntime.OrtException;
import org.ericsson.entity.inference.InferenceResult;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface IReferenceService  {
public InferenceResult getInferenceResultById(String id);

public List<InferenceResult> inference(OnnxTensor imageTensor) throws OrtException;

}
