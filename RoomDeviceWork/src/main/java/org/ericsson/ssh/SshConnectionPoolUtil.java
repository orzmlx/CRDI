package org.ericsson.ssh;

import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.pool2.KeyedObjectPool;
import org.apache.commons.pool2.KeyedPooledObjectFactory;
import org.apache.commons.pool2.PooledObject;
import org.apache.commons.pool2.impl.DefaultPooledObject;
import org.apache.commons.pool2.impl.GenericKeyedObjectPool;
import org.apache.commons.pool2.impl.GenericKeyedObjectPoolConfig;

import java.util.Properties;

@Slf4j
public class SshConnectionPoolUtil {
    private static KeyedObjectPool<ServerAccount, Session> pool;
    //连接超时时间
    private static final int connectionTimeOut = 60 * 1000;
    private static final int poolMaxActive = 10;
    private static final int poolMaxIdle = 100;
    private static final int poolMinIdle = 1;
    private static final int poolMaxWait = 15*1000;
    private static final int poolTimeBetweenEvictionRunsMillis = 10*60*1000;

    //初始化连接池
    protected static KeyedObjectPool<ServerAccount, Session> getConnectionPool() {
        if (pool == null) {
            synchronized (SshConnectionPoolUtil.class) {
                if (pool == null) {
                    GenericKeyedObjectPoolConfig config = new GenericKeyedObjectPoolConfig();
                    config.setLifo(false);
                    config.setMaxTotal(100); // 设置整个池的最大对象数量
                    config.setMaxTotalPerKey(poolMaxActive);//最大激活数
                    config.setMaxIdlePerKey(poolMaxIdle);//最大空闲数
                    config.setMinIdlePerKey(poolMinIdle);//最小空闲数
                    config.setMaxWaitMillis(poolMaxWait);//最大等待时间
                    config.setTestOnBorrow(true);//获取对象是否检测有效性
                    config.setTestOnReturn(true);//归还对象是否检测有效性
                    config.setTestWhileIdle(true);//不需要移除的对象是否检测有效性
                    config.setTimeBetweenEvictionRunsMillis(poolTimeBetweenEvictionRunsMillis);//检测时间间隔  单位ms
                    config.setMinEvictableIdleTimeMillis(10*60*1000);
                    pool = new GenericKeyedObjectPool(new SshConnectionPoolFactory(), config);
                }
            }
        }
        return pool;
    }

    public static Session getConnectionByServerAccount(ServerAccount serverAccount) throws Exception {
        return getConnectionPool().borrowObject(serverAccount);
    }

    //归还连接实例s
    public static void returnConnectionToPool(ServerAccount serverAccount, Session session) throws Exception {
        getConnectionPool().returnObject(serverAccount, session);
        getConnectionPool().clear(serverAccount);
    }

    //扫描连接池中当前可用实例数量
    public static void countConnectionNumForPool() {
        log.info("对象池当前激活实例总数量【{}】", getConnectionPool().getNumActive());
        log.info("对象池当前空闲实例总数量【{}】", getConnectionPool().getNumIdle());
    }

    /**
     * @Description 内部工厂类-对象池
     */
    @Slf4j
    public static class SshConnectionPoolFactory implements KeyedPooledObjectFactory<ServerAccount, Session> {
        @Override
        public PooledObject<Session> makeObject(ServerAccount key) throws Exception{
            Properties properties = new Properties();
            properties.put("StrictHostKeyChecking", "no");
            JSch jsch = new JSch();
            PooledObject<Session> pooledObject = null;
            try {
                Session session = jsch.getSession(key.getUserName(), key.getHost(), key.getPort());
                session.setPassword(key.getPassword());
                session.setTimeout(connectionTimeOut);
                session.setConfig(properties);
                session.connect();
                pooledObject = new DefaultPooledObject<>(session);
                log.info("ssh连接池正在创建新的session连接实例..."+key+":"+session);
            } catch (JSchException e) {
                log.error("ssh连接池创建新的session连接实例异常，原因如下", e);
            }
            return pooledObject;
        }

        @Override
        public void destroyObject(ServerAccount key, PooledObject<Session> pooledObject) throws Exception {
            log.info("ssh连接池中session连接实例正在被销毁..."+key+":"+pooledObject.getObject());
            pooledObject.getObject().disconnect();
        }

        @Override
        public boolean validateObject(ServerAccount key, PooledObject<Session> pooledObject) {
            if(pooledObject.getObject().isConnected()){
                try {
                    pooledObject.getObject().sendKeepAliveMsg();
                    return true;
                } catch (Exception e) {
                    log.info("ssh连接池中session连接实例已失效..."+key+":"+pooledObject.getObject()+":"+e.getMessage());
                    return false;
                }
            }
            return false;
        }

        @Override
        public void activateObject(ServerAccount key, PooledObject<Session> pooledObject) throws Exception {
            log.info("ssh连接池:正在获取session连接实例【{}:{}】", key.getHost(), key.getUserName());
        }

        @Override
        public void passivateObject(ServerAccount key, PooledObject<Session> pooledObject) throws Exception {
            log.info("ssh连接池:正在归还session连接实例【{}:{}】", key.getHost(), key.getUserName());
        }
    }
}
