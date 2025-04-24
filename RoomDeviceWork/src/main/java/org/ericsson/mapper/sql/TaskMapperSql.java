package org.ericsson.mapper.sql;

public class TaskMapperSql {
    public String queryTask(String taskName, String taskState){
        StringBuffer querySql = new StringBuffer();
        //处理查询SQL
        querySql.append("SELECT");
        querySql.append("   *");
        querySql.append("FROM");
        querySql.append("   generator_task ");
        querySql.append("WHERE 1 = 1");
        if(taskName != null && !"".equals(taskName)){
            querySql.append("   AND task_name LIKE '%"+taskName+"%'");
        }
        if(taskState != null && !"".equals(taskState)){
            querySql.append("   AND task_state = '"+taskState+"'");
        }
        querySql.append("   ORDER BY create_time,update_time ");

        return querySql.toString();
    }
}
