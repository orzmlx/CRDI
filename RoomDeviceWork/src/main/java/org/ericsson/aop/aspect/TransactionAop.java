package org.ericsson.aop.aspect;

import com.baomidou.mybatisplus.core.toolkit.ArrayUtils;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Pointcut;
import org.ericsson.aop.annotation.MoreTransaction;
import org.ericsson.util.SpringContextUtil;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.DefaultTransactionDefinition;

import java.util.Stack;

@Slf4j
public class TransactionAop {
    @Pointcut("@annotation(org.ericsson.aop.annotation.MoreTransaction)")
    public void MoreTransaction() {
    }

    @Pointcut("execution(* org.ericsson.controller.*.*(..))")
    public void excudeController() {
    }

    @Around(value = "MoreTransaction()&&excudeController()&&@annotation(annotation)")
    public Object twiceAsOld(ProceedingJoinPoint thisJoinPoint, MoreTransaction annotation) throws Throwable {
        //存放事务管理器的栈
        Stack<DataSourceTransactionManager> dataSourceTransactionManagerStack = new Stack<>();
        //存放事务的状态，每一个DataSourceTransactionManager 对应一个 TransactionStatus
        Stack<TransactionStatus> transactionStatuStack = new Stack<>();

        try {
            //判断自定义注解@MoreTransaction 是否传入事务管理器的名字，将自定义注解的值对应的事务管理器入栈
            if (!openTransaction(dataSourceTransactionManagerStack, transactionStatuStack, annotation)) {
                return null;
            }
            //执行业务方法
            Object ret = thisJoinPoint.proceed();
            //如果没有异常，说明两个sql都执行成功，两个数据源的sql全部提交事务
            commit(dataSourceTransactionManagerStack, transactionStatuStack);
            return ret;
        } catch (Throwable e) {
            //业务代码发生异常，回滚两个数据源的事务
            rollback(dataSourceTransactionManagerStack, transactionStatuStack);
            log.error(String.format("MultiTransactionalAspect, method:%s-%s occors error:",
                    thisJoinPoint.getTarget().getClass().getSimpleName(), thisJoinPoint.getSignature().getName()), e);
            throw e;
        }
    }

    /**
     * 开启事务处理方法
     *
     * @param dataSourceTransactionManagerStack
     * @param transactionStatuStack
     * @param multiTransactional
     * @return
     */
    private boolean openTransaction(Stack<DataSourceTransactionManager> dataSourceTransactionManagerStack,
                                    Stack<TransactionStatus> transactionStatuStack, MoreTransaction multiTransactional) {
        // 获取需要开启事务的事务管理器名字
        String[] transactionMangerNames = multiTransactional.value();
        // 检查是否有需要开启事务的事务管理器名字
        if (ArrayUtils.isEmpty(multiTransactional.value())) {
            return false;
        }
        // 遍历事务管理器名字数组，逐个开启事务并将事务状态和管理器存入栈中
        for (String beanName : transactionMangerNames) {
            // 从Spring上下文中获取事务管理器
            DataSourceTransactionManager dataSourceTransactionManager =(DataSourceTransactionManager) SpringContextUtil.getBean(beanName);
            // 创建新的事务状态
            TransactionStatus transactionStatus = dataSourceTransactionManager
                    .getTransaction(new DefaultTransactionDefinition());
            // 将事务状态和事务管理器存入对应的栈中
            transactionStatuStack.push(transactionStatus);
            dataSourceTransactionManagerStack.push(dataSourceTransactionManager);
        }
        return true;
    }

    /**
     * 提交处理方法
     *
     * @param dataSourceTransactionManagerStack
     * @param transactionStatuStack
     */
    private void commit(Stack<DataSourceTransactionManager> dataSourceTransactionManagerStack,
                        Stack<TransactionStatus> transactionStatuStack) {
        // 循环，直到事务管理器栈为空
        while (!dataSourceTransactionManagerStack.isEmpty()) {
            // 从事务管理器栈和事务状态栈中分别弹出当前的事务管理器和事务状态
            // 提交当前事务状态
            dataSourceTransactionManagerStack.pop()
                    .commit(transactionStatuStack.pop());
        }
    }

    /**
     * 回滚处理方法
     * @param dataSourceTransactionManagerStack
     * @param transactionStatuStack
     */
    private void rollback(Stack<DataSourceTransactionManager> dataSourceTransactionManagerStack,
                          Stack<TransactionStatus> transactionStatuStack) {
        // 循环，直到事务管理器栈为空
        while (!dataSourceTransactionManagerStack.isEmpty()) {
            // 从事务管理器栈和事务状态栈中分别弹出当前的事务管理器和事务状态
            // 回滚当前事务状态
            dataSourceTransactionManagerStack.pop().rollback(transactionStatuStack.pop());
        }
    }
}
