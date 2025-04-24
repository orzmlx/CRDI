package org.ericsson.ssh;

import com.jcraft.jsch.Session;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Data
@Slf4j
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class ServerAccount {
    private String host;
    private int port;
    private String userName;
    private String password;

    @Override
    public int hashCode() {
        return (host+port+userName+password).hashCode();
    }

    @Override
    public boolean equals(Object obj) {
        ServerAccount serverAccount = (ServerAccount) obj;
        return (host+port+userName+password).equals(serverAccount.getHost()+serverAccount.getPort()+serverAccount.getUserName()+serverAccount.getPassword());
    }

    public Session getSession() {
        Session session = null;
        try {
            session = SshConnectionPoolUtil.getConnectionByServerAccount(this);
        } catch (Exception e) {
            log.error("ENM服务器【{}:{}】连接异常，异常原因如下：", this.host, this.userName, e);
            session = null;
        }

        return session;
    }

    public void returnConnectionToPool(Session session) {
        try {
            if(session != null){
                SshConnectionPoolUtil.countConnectionNumForPool();
                SshConnectionPoolUtil.returnConnectionToPool(this, session);
            }
        } catch (Exception e) {
            log.error("归还ENM连接实例【{}:{}】错误，错误原因如下：", this.host, this.userName, e);
        }
    }
}
