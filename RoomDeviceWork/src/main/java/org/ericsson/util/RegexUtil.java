package org.ericsson.util;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class RegexUtil {
    /**
     * 从content中匹配正则regexStr满足的第一个数据
     * */
    public static String compileRegex(String regexStr, String content) {
        Pattern pattern = Pattern.compile(regexStr);
        Matcher matcher = pattern.matcher(content);
        if(matcher.find()){return matcher.group();}
        return null;
    }
}
