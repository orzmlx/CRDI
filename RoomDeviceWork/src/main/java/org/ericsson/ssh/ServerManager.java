package org.ericsson.ssh;

import com.jcraft.jsch.*;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.io.IOUtils;

import java.io.*;
import java.util.Arrays;
import java.util.Vector;

@Slf4j
public class ServerManager {
    //异步执行,不需要结果
    public static void execCmdWithOutResult(Session session, String cmd) {
        log.info("开始执行命令：" + cmd);
        //处理执行的脚本
        ChannelExec channelExec = openChannelExec(session);
        if(channelExec == null){ return; }
        try {
            //开始执行
            channelExec.connect();
            channelExec.getExitStatus();
        } catch (JSchException e) {
            log.error("异步执行命令【{}】异常，详细错误如下", cmd, e);
        }
        closeChannelExec(channelExec);
    }

    //同步执行,需要获取执行完的结果
    public static String execCmdWithResult(Session session, String cmd) {
        log.info("开始执行命令：" + cmd);
        String result = "";
        //处理执行的脚本
        ChannelExec channelExec = openChannelExec(session);
        channelExec.setCommand(cmd);
        try {
            //开始执行
            channelExec.setInputStream(null);
            channelExec.setErrStream(System.err);
            InputStream in = channelExec.getInputStream();
            channelExec.connect();
            byte[] tmp = new byte[1024];
            while (true) {
                while (in.available() > 0) {
                    int i = in.read(tmp, 0, 1024);
                    if (i < 0)
                        break;
                    result += new String(tmp, 0, i);
                }
                if (channelExec.isClosed()) {
                    break;
                }
                try {
                    Thread.sleep(1000);
                } catch (Exception ee) {
                }
            }
            log.info("执行结果：【succeed】");
            log.info("执行结果：【{}】", result.trim());
        } catch (Exception e) {
            log.error("同步执行命令【{}】异常，详细错误如下", cmd, e);
        }
        closeChannelExec(channelExec);
        return result.trim();
    }

    /************************************************************* 打开通道 **/
    public static ChannelExec openChannelExec(Session session) {
        ChannelExec channelExec = null;
        try {
            channelExec = (ChannelExec) session.openChannel("exec");
        } catch (JSchException e) {
            log.error("获取Exec的Channel错误，详细错误如下：", e);
        }
        return channelExec;
    }
    public static void closeChannelExec(ChannelExec channelExec) {
        if (channelExec != null) {
            channelExec.disconnect();
        }
    }
    public static ChannelSftp openChannelSftp(Session session) {
        ChannelSftp channelSftp = null;
        try{
            Channel channel = session.openChannel("sftp");
            channel.connect();
            channelSftp = (ChannelSftp) channel;
        }catch (Exception e){
            log.error("获取sftp的Channel通道错误，详细错误如下：", e);
        }
        return channelSftp;
    }

    /************************************************************* 上传 **/
    public static boolean upload(Session session, String uploadFilePath, String targetDir, String fileName) throws Exception {
        //开始做上传操作
        ChannelSftp channelSftp = openChannelSftp(session);
        if(channelSftp == null){
            return false;
        }
        if(!isExist(channelSftp, targetDir)){
            log.info("目录【{}】不存在，创建目录", targetDir);
            if(!mkdirs(channelSftp, targetDir)){ return false; }
        }
        if(isExist(channelSftp, targetDir+"/"+fileName)){
            log.info("文件【{}】已经存在，不需要重复上传", targetDir+"/"+fileName);
            return true;
        }
        channelSftp.cd(targetDir.trim());
        //开始上传文件
        return upload(channelSftp, targetDir, uploadFilePath, fileName);
    }
    public static boolean uploadByDirectory(Session session, String directory, String targetDir) {
        //判断是否给了目标目录，没有则使用上传目录
        if(targetDir == null || "".equals(targetDir)){
            targetDir = directory;
        }
        //开始做上传操作
        ChannelSftp channelSftp = openChannelSftp(session);
        if(channelSftp == null){
            return false;
        }
        try{
            return uploadByDirectory(channelSftp, directory, targetDir);
        } finally {
            channelSftp.quit();
            channelSftp.exit();
            if (channelSftp != null){
                channelSftp.disconnect();
            }
        }
    }
    protected static boolean uploadByDirectory(ChannelSftp channelSftp, String directory, String targetDir) {
        boolean resultStatus = true;
        try {
            if(!isExist(channelSftp, targetDir)){
                log.info("目录【{}】不存在，创建目录", targetDir);
                if(!mkdirs(channelSftp, targetDir)){ return false; }
            }
            channelSftp.cd(targetDir.trim());

            File uploadBorderFile = new File(directory);
            File[] uploadFileArray = uploadBorderFile.listFiles();
            for (int i=0; i<uploadFileArray.length; i++){
                File uploadFile = uploadFileArray[i];
                if(uploadFile.isDirectory()){
                    if(!uploadByDirectory(channelSftp, uploadFile.getAbsolutePath(), targetDir+"/"+uploadFile.getName())){
                        resultStatus = false;
                        break;
                    }
                    continue;
                }
                if(!upload(channelSftp, targetDir, uploadFile.getAbsolutePath(), null)){
                    resultStatus = false;
                    break;
                };
            }
        } catch (Exception e){
            log.error("sftp上传目录【{}】错误，详细错误如下：", directory, e);
            resultStatus = false;
        }
        return resultStatus;
    }
    protected static boolean upload(ChannelSftp channelSftp, String targetDir, String uploadFilePath, String fileName) {
        boolean resultStatus = true;
        FileInputStream fileInputStream = null;
        File file = new File(uploadFilePath);
        try {
            if(!isExist(channelSftp, targetDir)){
                log.info("目录【{}】不存在，创建目录", targetDir);
                if(!mkdirs(channelSftp, targetDir)){ return false; }
            }
            if(!channelSftp.pwd().equals(targetDir.trim())){
                channelSftp.cd(targetDir.trim());
            }
            if(!file.exists()){
                return resultStatus;
            }
            fileInputStream = new FileInputStream(file);
            FileProgress progress = new FileProgress(file.length());
            channelSftp.put(fileInputStream, (fileName==null?file.getName():fileName), progress, ChannelSftp.OVERWRITE);
            return progress.getEnd();
        } catch (Exception e) {
            log.error("sftp上传文件【{}】错误，详细错误如下：", file.getAbsolutePath(), e);
            resultStatus = false;
        } finally {
            if(fileInputStream != null){ try{fileInputStream.close();}catch (Exception e){}}
        }

        return resultStatus;
    }
    public static boolean isExist(ChannelSftp channelSftp, String path) {
        try {
            channelSftp.stat(path);
            return true;
        } catch (SftpException e) {
            return false;
        }
    }
    public static boolean mkdirs(ChannelSftp channelSftp, String targetDir) {
        String[] folders = targetDir.split("/");
        try {
            channelSftp.cd("/");
            for (String folder: folders) {
                if (folder.length()>0) {
                    try {
                        channelSftp.cd(folder);
                    } catch (Exception e) {
                        channelSftp.mkdir(folder);
                        channelSftp.cd(folder);
                    }
                }
            }
            return true;
        } catch (SftpException e) {
            log.error("创建目录【{}】错误，详细错误如下：", targetDir, e);
        }
        return false;
    }


    /************************************************************* 下载 **/
    public static boolean downloadFile(Session session, String borderPath, String fileName, String downTargetBorder) throws Exception {
        //开始做上传操作
        ChannelSftp channelSftp = openChannelSftp(session);
        if(channelSftp == null){
            return false;
        }
        return downloadFile(channelSftp, borderPath, fileName, downTargetBorder);
    }
    protected static boolean downloadFile(ChannelSftp channelSftp, String borderPath, String fileName, String downTargetBorder) {
        boolean resultStatus = true;
        if(!new File(downTargetBorder).exists()){//目标目录不存在，则创建目录
            new File(downTargetBorder).mkdirs();
        }
        try {
            channelSftp.cd(borderPath);
            InputStream in = channelSftp.get(fileName);

            FileOutputStream out = new FileOutputStream(new File(downTargetBorder+"/"+fileName));
            IOUtils.copy(in, out);
            in.close();
            out.close();
        } catch (Exception e) {
            log.error("sftp下载目录【{}】错误，详细错误如下：", borderPath, e);
            resultStatus = false;
        } finally {
            channelSftp.quit();
            channelSftp.exit();
            if (channelSftp != null){
                channelSftp.disconnect();
            }
        }

        return resultStatus;
    }

    public static boolean downloadBorder(Session session, String borderPath, String downTargetBorder) throws Exception {
        //开始做上传操作
        ChannelSftp channelSftp = openChannelSftp(session);
        if(channelSftp == null){
            return false;
        }
        return downloadBorder(channelSftp, borderPath, downTargetBorder);
    }
    protected static boolean downloadBorder(ChannelSftp channelSftp, String borderPath, String downTargetBorder) {
        boolean resultStatus = true;
        if(!new File(downTargetBorder).exists()){//目标目录不存在，则创建目录
            new File(downTargetBorder).mkdirs();
        }
        try {
            Vector<ChannelSftp.LsEntry> fileAndFolderList = channelSftp.ls(borderPath);
            for (ChannelSftp.LsEntry item : fileAndFolderList) {
                if(item.getAttrs().isDir()){
                    continue;
                }
                InputStream in = channelSftp.get(borderPath+"/"+item.getFilename());

                FileOutputStream out = new FileOutputStream(new File(downTargetBorder+"/"+item.getFilename()));
                IOUtils.copy(in, out);
                in.close();
                out.close();
            }
        } catch (Exception e){
            log.error("sftp下载目录【{}】错误，详细错误如下：", borderPath, e);
            resultStatus = false;
        } finally {
            channelSftp.quit();
            channelSftp.exit();
            if (channelSftp != null){
                channelSftp.disconnect();
            }
        }

        return resultStatus;
    }

    public static Channel openChannelShell(Session session) {
        Channel channel = null;
        try {
            channel = session.openChannel("shell");
        } catch (JSchException e) {
            log.error("获取Shell的Channel错误，详细错误如下：", e);
        }


        return channel;
    }

    public static void execChannelShell(Channel channel, String shell) throws Exception {
        if (channel != null) {
            PrintStream stream = new PrintStream(channel.getOutputStream());
            stream.println(shell);
            stream.flush();
            if(shell.contains("su")){
                Thread.sleep(1000);
            }
            if("exit".equals(shell)){
                Thread.sleep(1000);
                stream.close();
            }
        }
    }

    public static String getOutput(Channel channel) throws Exception {
        String result = "";
        InputStream inputStream = channel.getInputStream();
        //循环读取
        byte[] buffer = new byte[1024];
        int i = 0;
        //如果没有数据来，线程会一直阻塞在这个地方等待数据。
        while ((i = inputStream.read(buffer)) != -1) {
            result += new String(Arrays.copyOfRange(buffer, 0, i));
        }
        log.info("执行结果：【{}】", result.trim());
        return result;
    }
}
