package org.ericsson.entity.inference;

import io.swagger.annotations.ApiModel;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.experimental.Accessors;

@Data
@ToString
@NoArgsConstructor
@AllArgsConstructor
@Accessors(chain = true)
@ApiModel(value = "模型推理结果")
//x, y, width, height, classId, maxClassProb
public class InferenceResult {
    private float x;
    private float y;
    private float width;
    private float height;
    private int classId;
    private float maxClassProb;
}
