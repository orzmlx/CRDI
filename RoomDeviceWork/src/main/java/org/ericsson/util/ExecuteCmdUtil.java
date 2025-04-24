package org.ericsson.util;

import lombok.extern.slf4j.Slf4j;

import java.io.BufferedReader;
import java.io.InputStreamReader;

@Slf4j
public class ExecuteCmdUtil {
    public static void exeCmd(String exeCmd) throws Exception {
        log.info("exeCmd：【{}】", exeCmd);
        try {
            String[] cmd = new String[]{"/bin/sh", "-c", exeCmd};
            Runtime.getRuntime().exec(cmd);
        } catch (Exception e) {
            throw e;
        }
    }

    public static String exeCmdResult(String exeCmd) {
        log.info("exeCmd：【{}】", exeCmd);
        try {
            String[] cmd = new String[]{"/bin/sh", "-c", exeCmd};
            Process ps = Runtime.getRuntime().exec(cmd);

            BufferedReader br = new BufferedReader(new InputStreamReader(ps.getInputStream()));
            StringBuffer sb = new StringBuffer();
            String line;
            while ((line = br.readLine()) != null) {
                sb.append(line).append("\n");
            }
            String result = sb.toString().trim();
            log.info("执行结果：【{}】", result);
            return result;
        } catch (Exception e) {
            log.error("执行命令【{}】出现错误，错误原因如下：", exeCmd);
        }
        return null;
    }

    public static String exeCmdResult(String exeCmd, boolean isPrintLog) {
        if(isPrintLog){ log.info("exeCmd：【{}】", exeCmd); }
        try {
            String[] cmd = new String[]{"/bin/sh", "-c", exeCmd};
            Process ps = Runtime.getRuntime().exec(cmd);

            BufferedReader br = new BufferedReader(new InputStreamReader(ps.getInputStream()));
            StringBuffer sb = new StringBuffer();
            String line;
            while ((line = br.readLine()) != null) {
                sb.append(line).append("\n");
            }
            String result = sb.toString().trim();
            if(isPrintLog){ log.info("执行结果：【{}】", result); }
            return result;
        } catch (Exception e) {
            log.error("执行命令【{}】出现错误，错误原因如下：", exeCmd);
        }
        return null;
    }

    public static String exeCmdResult(String exeCmd, long overtime) {//overtime的时间是毫秒
        log.info("exeCmd：【{}】", exeCmd);
        long startTime = System.currentTimeMillis();
        try {
            String[] cmd = new String[]{"/bin/sh", "-c", exeCmd};
            Process ps = Runtime.getRuntime().exec(cmd);

            BufferedReader br = new BufferedReader(new InputStreamReader(ps.getInputStream()));
            StringBuffer sb = new StringBuffer();
            String line;
            while ((line = br.readLine()) != null) {
                sb.append(line).append("\n");
                if((System.currentTimeMillis()-startTime)>overtime){//此判断预防进程吊死
                    exeCmdResult("ps -ef|grep '"+exeCmd+"' | grep -v grep | awk '{print $2}' | xargs kill -9");
                    throw new Exception("执行命令【"+exeCmd+"】超时，退出当前线程！");
                }
            }
            String result = sb.toString().trim();
            log.info("执行结果：【{}】", result);
            return result;
        } catch (Exception e) {
            log.error("执行命令【{}】出现错误，错误原因如下：", exeCmd);
        }
        return null;
    }
}