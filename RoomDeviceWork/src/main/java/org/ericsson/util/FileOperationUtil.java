package org.ericsson.util;

import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.compress.utils.Lists;
import org.apache.http.entity.ContentType;
import org.ericsson.exception.BusinessException;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
public class FileOperationUtil {
    @SneakyThrows
    public static String getStream(String filePath) {
        BufferedReader reader = null;
        StringBuffer buffer = new StringBuffer();
        String s = null;
        try {
            reader = new BufferedReader(new FileReader(filePath));
            while ((s = reader.readLine()) != null) {
                buffer.append(s + "\n");
            }
            reader.close();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (reader != null) {
                reader.close();
            }
        }
        return buffer.toString();
    }

    public static Map<String, String> getFolderFile(String folderPath) {
        Map<String, String> filePathMap = new HashMap<String, String>();
        try {
            File folderFile = new File(folderPath);
            if (!folderFile.isDirectory()) {
                throw new Exception("指定的路径不是一个文件夹！");
            }
            File fileArray[] = folderFile.listFiles();
            for (int i = 0; i < fileArray.length; i++) {
                if (fileArray[i].renameTo(fileArray[i])) {
                    String fileName = fileArray[i].getName();
                    filePathMap.put(fileName.substring(0, fileName.lastIndexOf(".")), fileArray[i].getPath());
                }
            }
        } catch (Exception e) {
            e.fillInStackTrace();
        }
        return filePathMap;
    }

    public static Map<String, String> getFolderFile(String folderPath, String fileName_vague) {
        Map<String, String> filePathMap = new HashMap<String, String>();
        try {
            File folderFile = new File(folderPath);
            if (!folderFile.isDirectory()) {
                throw new Exception("指定的路径不是一个文件夹！");
            }
            File fileArray[] = folderFile.listFiles();
            for (int i = 0; i < fileArray.length; i++) {
                if (fileArray[i].renameTo(fileArray[i])) {
                    String fileName = fileArray[i].getName();
                    if(fileName.contains(fileName_vague)){
                        filePathMap.put(fileName.substring(0, fileName.lastIndexOf(".")), fileArray[i].getPath());
                    }
                }
            }
        } catch (Exception e) {
            e.fillInStackTrace();
        }
        return filePathMap;
    }

    public static Map<String, String> getFolderFile(String folderPath, String fileName_vague1, String fileName_vague2) {
        Map<String, String> filePathMap = new HashMap<String, String>();
        try {
            File folderFile = new File(folderPath);
            if (!folderFile.isDirectory()) {
                throw new Exception("指定的路径不是一个文件夹！");
            }
            File fileArray[] = folderFile.listFiles();
            for (int i = 0; i < fileArray.length; i++) {
                if (fileArray[i].renameTo(fileArray[i])) {
                    String fileName = fileArray[i].getName();
                    if(fileName.contains(fileName_vague1) && fileName.contains(fileName_vague2)){
                        filePathMap.put(fileName.substring(0, fileName.lastIndexOf(".")), fileArray[i].getPath());
                    }
                }
            }
        } catch (Exception e) {
            e.fillInStackTrace();
        }
        return filePathMap;
    }

    public static void moveFile(String filePath, String targetFolderPath, String newFileName) {
        try {
            File file = new File(filePath);
            if (file.isFile()) {
                File folderFile = new File(targetFolderPath);
                if (!folderFile.exists()) {
                    folderFile.mkdirs();
                }
                String fileName = file.getName();
                if (!"".equals(newFileName) && newFileName != null) {
                    fileName = newFileName;
                }
                Path path = Paths.get(filePath);
                Path targetPath = Paths.get(targetFolderPath+"/"+fileName);

                Files.move(path, targetPath, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (Exception e) {
            log.error("移动文件："+filePath+"失败！" + e.getMessage());
        }
    }

    public static void moveBorder(String fileBorderPath, String targetFolderPath) {
        try {
            File fileBorder = new File(fileBorderPath);
            if (fileBorder.exists() && !fileBorder.isFile()) {
                File bolderFileTarget = new File(targetFolderPath);
                if (!bolderFileTarget.exists()) {
                    bolderFileTarget.mkdirs();
                }
                for(File file : fileBorder.listFiles()){
                    Path path = Paths.get(file.getAbsolutePath());
                    Path targetPath = Paths.get(targetFolderPath+"/"+file.getName());
                    Files.move(path, targetPath, StandardCopyOption.REPLACE_EXISTING);
                }
            }
        } catch (Exception e) {
            log.error("移动目录："+fileBorderPath+"下的文件失败！" + e.getMessage());
        }
    }

    public static void copyFile(String filePath, String targetBorderPath) throws Exception{
        File file = new File(filePath);
        if (file.isFile()) {
            createFile(targetBorderPath, file.getName(), getStream(filePath));
        } else if (file.isDirectory()) {
            throw new Exception("需要复制的不是一个文件，退出复制");
        }
    }

    @SneakyThrows
    public static void createFile(String folderPath, String fileName, String fileContent) {
        FileWriter fileWriter = null;
        BufferedWriter bufferedWriter = null;
        try {
            File folderFile = new File(folderPath);
            if (!folderFile.exists()) {//判断文件夹是否存在
                folderFile.mkdirs();
            }

            //将内容写入文件
            File file = new File(folderPath+"/"+fileName);
            //如果存在这个文件就删除，否则就创建
            if(file.exists()){
                file.delete();
            }else{
                file.createNewFile();
            }

            //开始将内容写入文件
            fileWriter = new FileWriter(file, true);
            bufferedWriter = new BufferedWriter(fileWriter);
            bufferedWriter.write(fileContent);
            //内容提交
            bufferedWriter.flush();
        } catch (Exception e) {
            log.error("生成配置文件:"+fileName+"失败！");
            e.fillInStackTrace();
        } finally {
            if(bufferedWriter != null) {
                bufferedWriter.close();
            }
            if(fileWriter != null) {
                fileWriter.close();
            }
        }
    }

    public static void deleteFile(String filePath) {
        try {
            File file = new File(filePath);
            //如果存在这个文件就删除
            if(file.exists()){
                file.delete();
            }
        } catch (Exception e) {
            log.error("删除文件："+filePath+"失败！"+e.getMessage());
        }
    }

    public static void deleteDirectory(String dir) {
        // 如果dir不以文件分隔符结尾，自动添加文件分隔符
        if (!dir.endsWith(File.separator)) {
            dir = dir + File.separator;
        }
        File dirFile = new File(dir);
        // 如果dir对应的文件不存在，或者不是一个目录，则退出
        if ((!dirFile.exists()) || (!dirFile.isDirectory())) {
            log.error("删除目录失败：" + dir + "不存在！");
            return;
        }
        // 删除文件夹中的所有文件包括子目录
        File[] files = dirFile.listFiles();
        for (int i = 0; i < files.length; i++) {
            // 删除子文件
            if (files[i].isFile()) {
                deleteFile(files[i].getAbsolutePath());
            }
            // 删除子目录
            else if (files[i].isDirectory()) {
                deleteDirectory(files[i].getAbsolutePath());
            }
        }
        // 删除当前目录
        dirFile.delete();
    }

    public static MultipartFile createMultipartFile(String filePath){
        MultipartFile mFile = null;
        try {
            if(filePath == null || "".equals(filePath)){
                return mFile;
            }
            File file = new File(filePath);
            FileInputStream fileInputStream = new FileInputStream(file);

            String fileName = file.getName();
            fileName = fileName.substring((fileName.lastIndexOf("/") + 1));
            mFile =  new MockMultipartFile(fileName, fileName, ContentType.APPLICATION_OCTET_STREAM.toString(), fileInputStream);
        } catch (Exception e) {
            log.error("转MultipartFile异常，异常原因如下：", e);
            throw new BusinessException("文件转换异常，原因："+e.getMessage());
        }
        return mFile;
    }

    public static void saveFile(MultipartFile file, String filePath) throws IOException {
        FileOutputStream outputStream = null;
        try {
            outputStream = new FileOutputStream(filePath);
            //写入
            outputStream.write(file.getBytes());
            //提交
            outputStream.flush();
        } catch (Exception e) {
            log.error("保存文件【{}】异常，异常原因如下：", file.getOriginalFilename(), e);
            throw new BusinessException("保存文件【"+file.getOriginalFilename()+"】异常");
        } finally {
            if(outputStream != null){
                outputStream.close();
            }
        }
    }

    public static String readCsvFile(String filePath){
        return readCsvFile(filePath, ",");
    }
    @SneakyThrows
    public static String readCsvFile(String filePath, String delimiter){
        BufferedReader reader = null;
        List<String> rowList = Lists.newArrayList();
        String row = null;
        try {
            reader = new BufferedReader(new FileReader(filePath));
            while ((row = reader.readLine()) != null) {
                if("ip".equals(row.trim())){
                    continue;
                }
                rowList.add(row.trim());
            }
            reader.close();
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (reader != null) {
                reader.close();
            }
        }
        return String.join(delimiter, rowList);
    }

    public static void createBorder(String borderPath){
        File borderFile = new File(borderPath);
        if (!borderFile.exists()) {
            borderFile.mkdirs();
        }
    }
}
