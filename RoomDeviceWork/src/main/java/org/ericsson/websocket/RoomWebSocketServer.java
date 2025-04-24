package org.ericsson.websocket;

import cn.hutool.json.JSONArray;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.compress.utils.Lists;
import org.springframework.stereotype.Component;

import javax.websocket.*;
import javax.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.util.List;
import java.util.concurrent.CopyOnWriteArraySet;

@Slf4j
@Component
@ServerEndpoint(value="/ws/moos/message")
public class RoomWebSocketServer {
    //与某个客户端的连接会话，需要通过它来给客户端发送数据
    private Session session;

    //concurrent包的线程安全Set，用来存放每个客户端对应的WebSocket对象。
    private static CopyOnWriteArraySet<RoomWebSocketServer> webSocketSet = new CopyOnWriteArraySet<>();
    /**
     *  建立连接成功
     * @param session
     */
    @OnOpen
    public void onOpen(Session session){
        this.session=session;
        webSocketSet.add(this);
        //创建链接 默认消息推送
        onOpen_();
        log.info("【websocket消息】 有新的连接，总数{}",webSocketSet.size());
    }

    /**
     * 连接关闭
     */
    @OnClose
    public void onClose(){
        this.session=session;
        webSocketSet.remove(this);
        log.info("【websocket消息】 连接断开，总数{}",webSocketSet.size());
    }

    /**
     * 接收客户端消息
     * @param message
     */
    @OnMessage
    public void onMessage(Session session, String message){
        log.info("【websocket消息】 收到客户端发来的消息：{}",message);
    }

    /**
     * 配置错误信息处理
     * @param session
     * @param t
     */
    @OnError
    public void onError(Session session, Throwable t) {
        log.info("【websocket消息】出现未知错误：", t);
    }


    /**
     * 发送消息
     * @param messageJson
     */
    public void sendMessage(String messageJson){
        log.info("【websocket消息】 发送消息：{}", messageJson);
        for (RoomWebSocketServer webSocket:webSocketSet){
            try {
                webSocket.session.getBasicRemote().sendText(messageJson);
            } catch (IOException e) {
                log.error("推送消息到Monitor大屏异常，异常原因：", e);
            }
        }
    }

    public void onOpen_() {
        try{
            List<String> messageList = Lists.newArrayList();
            messageList.add("测试WebSocket消息");
            //推送消息到前台
            sendMessage(new JSONArray(messageList).toString());
        }catch (Exception e){
            log.error("WebSocket初始链接，推送消息异常，异常原因如下：", e);
        }

    }
}
