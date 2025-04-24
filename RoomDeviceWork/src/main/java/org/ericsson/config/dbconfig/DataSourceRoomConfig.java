package org.ericsson.config.dbconfig;


import com.baomidou.mybatisplus.autoconfigure.MybatisPlusProperties;
import com.baomidou.mybatisplus.core.config.GlobalConfig;
import com.baomidou.mybatisplus.extension.spring.MybatisSqlSessionFactoryBean;
import com.github.jeffreyning.mybatisplus.base.MppSqlInjector;
import com.zaxxer.hikari.HikariDataSource;
import org.apache.ibatis.session.SqlSessionFactory;
import org.ericsson.constant.TransantionName;
import org.mybatis.spring.SqlSessionTemplate;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.PlatformTransactionManager;

@Configuration
@MapperScan(basePackages = "org.ericsson.mapper.roomMapper", sqlSessionFactoryRef = "sqlSessionFactoryRoom")
public class DataSourceRoomConfig {
    //多事务的使用：@MoreTransaction(value = {TransantionName.TRANSANTION_room, TransantionName.TRANSANTION_TWO})
    //@Primary：此注解标志主数据库

    public static final String MAPPER_LOCATION = "classpath*:mapper/roommapper/*.xml";

    //数据源
    @Bean(name = "dataSourceRoom")
    @Primary
    @ConfigurationProperties(prefix = "spring.datasource.room.hikari")
    public HikariDataSource dataSourceroom() {
        return new HikariDataSource();
    }

    //事务
    @Bean(name = TransantionName.TRANSANTION_ROOM)
    @Primary
    public PlatformTransactionManager transactionManagerroom(@Qualifier("dataSourceRoom") HikariDataSource dataSourceroom) {
        return new DataSourceTransactionManager(dataSourceroom);
    }

    @Bean(name = "sqlSessionTemplateRoom")
    @Primary
    public SqlSessionTemplate sqlSessionTemplateroom(@Qualifier("sqlSessionFactoryRoom") SqlSessionFactory sessionfactory) {
        return new SqlSessionTemplate(sessionfactory);
    }

    @Bean(name = "sqlSessionFactoryRoom")
    @Primary
    public SqlSessionFactory sqlSessionFactoryroom(@Qualifier("dataSourceRoom") HikariDataSource dataSourceRoom, MppSqlInjector mppSqlInjector, MybatisPlusProperties properties) throws Exception {
        final MybatisSqlSessionFactoryBean sessionFactoryBean = new MybatisSqlSessionFactoryBean();
        GlobalConfig globalConfig = properties.getGlobalConfig();
        globalConfig.setSqlInjector(mppSqlInjector);
        sessionFactoryBean.setGlobalConfig(globalConfig);
        sessionFactoryBean.setDataSource(dataSourceRoom);
        sessionFactoryBean.setMapperLocations(new PathMatchingResourcePatternResolver().getResources(DataSourceRoomConfig.MAPPER_LOCATION));
        return sessionFactoryBean.getObject();
    }
}
