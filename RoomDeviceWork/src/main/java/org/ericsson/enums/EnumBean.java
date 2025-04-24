package org.ericsson.enums;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class EnumBean {
    private String code;
    private String name;
}
