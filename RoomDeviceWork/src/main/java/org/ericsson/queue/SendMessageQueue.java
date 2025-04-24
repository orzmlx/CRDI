package org.ericsson.queue;

import lombok.extern.slf4j.Slf4j;
import org.ericsson.websocket.RoomWebSocketServer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.util.concurrent.LinkedBlockingQueue;

@Slf4j
@Component
public class SendMessageQueue implements ApplicationRunner {
//    private static LinkedBlockingQueue<SendMessage> sendMessageQueue = new LinkedBlockingQueue<>(1024);

    @Autowired
    private RoomWebSocketServer RoomWebSocket;

    @Override
    public void run(ApplicationArguments args) {
        //创建队列执行者
//        CreateQueueExec();
    }

//    public static void addSendMessageQueue(String taskId, String sonTaskId, String messageContent){
//        Date currentTime = DateUtil.getCurrentDate();
//        sendMessageQueue.add(SendMessage.builder().messageId(taskId+""+DateUtil.format(currentTime, "yyyyMMddHHmmss")).taskId(taskId).sonTaskId(sonTaskId).messageContent(messageContent).createTime(currentTime).build());
//    }
//    private void CreateQueueExec() {
//        new Thread(() -> {
//            while (true) {
//                try {
//                    SendMessage sendMessage = sendMessageQueue.take();
//                    //保存数据库
//                    SendMessageService.save(sendMessage);
//                    //查询最新的20条记录，作为消息推送
//                    List<SendMessage> sendMessageList = SendMessageService.list(Wrappers.lambdaQuery(SendMessage.class).orderByDesc(SendMessage::getCreateTime).last(" limit 20 "));
//                    List<String> messageList = sendMessageList.stream().map(SendMessage::getMessageContent).distinct().collect(Collectors.toList());
//                    //推送消息到大屏
//                    RoomWebSocket.sendMessage(new JSONArray(messageList).toString());
//                } catch (Exception e) {
//                    log.error("推送消息到大屏队列执行异常，原因如下：", e);
//                }
//            }
//        }).start();
//    }
}
