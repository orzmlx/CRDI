package org.ericsson.util;

import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;
import java.util.List;

public class DateUtil {

    //获取当前时间
    public static Date getCurrentDate() {
        return new Date();
    }



    /*********** 下面的是时间转字符串 */
    public static String format(Date date, String format) {
        SimpleDateFormat simpleDate = new SimpleDateFormat(format);
        return simpleDate.format(date);
    }

    public static String formatDate(Date date) {
        SimpleDateFormat simpleDate = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        return simpleDate.format(date);
    }

    /*********** 下面的是字符串转时间 */
    public static Date parseDate(String date) throws Exception {
        SimpleDateFormat simpleDate = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        return simpleDate.parse(date);
    }

    public static Date parse(String date, String format) throws Exception {
        SimpleDateFormat simpleDate = new SimpleDateFormat(format);
        return simpleDate.parse(date);
    }

    /*********** 时间转Cron */
    public static String getCron(Date date) {
        SimpleDateFormat format = new SimpleDateFormat("ss mm HH dd MM ? yyyy");
        String cronTmp = format.format(date);
        List<String> cronStrList = Arrays.asList(cronTmp.split(" "));
        String cron = "";
        for(String cronStr : cronStrList){
            if("?".equals(cronStr)){
                cron += "? ";
                continue;
            }
            cron += Integer.parseInt(cronStr)+" ";
        }
        return cron.trim();
    }
}
