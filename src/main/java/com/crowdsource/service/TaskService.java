package com.crowdsource.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.crowdsource.common.PageResult;
import com.crowdsource.common.UserContext;
import com.crowdsource.dto.TaskDTO;
import com.crowdsource.dto.TaskQueryDTO;
import com.crowdsource.entity.*;
import com.crowdsource.enums.TaskStatus;
import com.crowdsource.mapper.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.CollectionUtils;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskMapper taskMapper;
    private final TagMapper tagMapper;
    private final TaskTagMapper taskTagMapper;
    private final TaskApplicationMapper applicationMapper;
    private final UserMapper userMapper;
    private final UserProfileMapper userProfileMapper;
    private final NotificationService notificationService;

    /**
     * 发布任务（发单人）
     */
    @Transactional
    public Long publishTask(TaskDTO dto) {
        Long userId = UserContext.getUserId();
        Task task = new Task();
        task.setPublisherId(userId);
        task.setTitle(dto.getTitle());
        task.setDescription(dto.getDescription());
        task.setType(dto.getType());
        task.setBudgetMin(dto.getBudgetMin());
        task.setBudgetMax(dto.getBudgetMax());
        task.setDeadline(dto.getDeadline());
        task.setStatus(TaskStatus.PENDING_REVIEW.getCode());
        taskMapper.insert(task);

        // 保存标签关联
        saveTaskTags(task.getId(), dto.getTagIds());

        return task.getId();
    }

    /**
     * 分页查询任务列表
     */
    public PageResult<Map<String, Object>> listTasks(TaskQueryDTO query) {
        Page<Task> page = new Page<>(query.getPage(), query.getSize());
        taskMapper.selectTaskPage(page, query);
        List<Map<String, Object>> list = page.getRecords().stream()
                .map(this::buildTaskVO)
                .collect(Collectors.toList());
        return PageResult.of(page.getTotal(), list);
    }

    /**
     * 任务详情
     */
    public Map<String, Object> getTaskDetail(Long taskId) {
        Task task = taskMapper.selectById(taskId);
        if (task == null) throw new RuntimeException("任务不存在");
        return buildTaskVO(task);
    }

    /**
     * 推荐任务（按接单人技术栈匹配）
     */
    public PageResult<Map<String, Object>> recommendTasks(int page, int size) {
        Long userId = UserContext.getUserId();
        Page<Task> p = new Page<>(page, size);
        taskMapper.recommendTasks(p, userId);
        List<Map<String, Object>> list = p.getRecords().stream()
                .map(this::buildTaskVO)
                .collect(Collectors.toList());
        return PageResult.of(p.getTotal(), list);
    }

    /**
     * 申请接单
     */
    @Transactional
    public void applyTask(Long taskId, String message, java.math.BigDecimal price) {
        Long userId = UserContext.getUserId();
        Task task = taskMapper.selectById(taskId);
        if (task == null || task.getStatus() != TaskStatus.RECRUITING.getCode()) {
            throw new RuntimeException("任务不存在或不在招募中");
        }
        // 检查是否已申请
        Long count = applicationMapper.selectCount(
                new LambdaQueryWrapper<TaskApplication>()
                        .eq(TaskApplication::getTaskId, taskId)
                        .eq(TaskApplication::getApplicantId, userId));
        if (count > 0) throw new RuntimeException("已申请过该任务");

        TaskApplication app = new TaskApplication();
        app.setTaskId(taskId);
        app.setApplicantId(userId);
        app.setMessage(message);
        app.setPrice(price);
        app.setStatus(1);
        applicationMapper.insert(app);

        // 通知发单人
        notificationService.send(task.getPublisherId(), "APPLY_RESULT",
                "有人申请了你的任务", "任务《" + task.getTitle() + "》收到新的接单申请", taskId);
    }

    /**
     * 发单人处理申请（接受/拒绝）
     */
    @Transactional
    public void handleApplication(Long applicationId, boolean accept) {
        Long userId = UserContext.getUserId();
        TaskApplication app = applicationMapper.selectById(applicationId);
        if (app == null) throw new RuntimeException("申请不存在");

        Task task = taskMapper.selectById(app.getTaskId());
        if (!task.getPublisherId().equals(userId)) throw new RuntimeException("无权操作");

        if (accept) {
            app.setStatus(2);
            applicationMapper.updateById(app);
            // 更新任务状态为进行中，绑定接单人
            task.setStatus(TaskStatus.IN_PROGRESS.getCode());
            task.setWorkerId(app.getApplicantId());
            taskMapper.updateById(task);
            // 通知接单人
            notificationService.send(app.getApplicantId(), "APPLY_RESULT",
                    "接单成功", "恭喜！你已成功接到任务《" + task.getTitle() + "》", task.getId());
        } else {
            app.setStatus(3);
            applicationMapper.updateById(app);
            notificationService.send(app.getApplicantId(), "APPLY_RESULT",
                    "申请未通过", "很遗憾，任务《" + task.getTitle() + "》的申请未通过", task.getId());
        }
    }

    /**
     * 完成任务
     */
    public void completeTask(Long taskId) {
        Long userId = UserContext.getUserId();
        Task task = taskMapper.selectById(taskId);
        if (task == null) throw new RuntimeException("任务不存在");
        if (!task.getPublisherId().equals(userId)) throw new RuntimeException("无权操作");
        task.setStatus(TaskStatus.COMPLETED.getCode());
        taskMapper.updateById(task);
        // 更新接单人完成数
        if (task.getWorkerId() != null) {
            UserProfile profile = userProfileMapper.selectOne(
                    new LambdaQueryWrapper<UserProfile>().eq(UserProfile::getUserId, task.getWorkerId()));
            if (profile != null) {
                profile.setOrderCount(profile.getOrderCount() + 1);
                userProfileMapper.updateById(profile);
            }
            notificationService.send(task.getWorkerId(), "TASK_UPDATE",
                    "任务已完成", "任务《" + task.getTitle() + "》已被标记为完成", taskId);
        }
    }

    // ---- 管理员接口 ----

    public PageResult<Map<String, Object>> adminListTasks(int page, int size, Integer status) {
        TaskQueryDTO query = new TaskQueryDTO();
        query.setStatus(status);
        query.setPage(page);
        query.setSize(size);
        return listTasks(query);
    }

    public void reviewTask(Long taskId, boolean approve) {
        Task task = taskMapper.selectById(taskId);
        if (task == null) {
            throw new RuntimeException("任务不存在");
        }
        task.setStatus(approve ? TaskStatus.RECRUITING.getCode() : TaskStatus.OFFLINE.getCode());
        taskMapper.updateById(task);
        // 通知发单人审核结果
        notificationService.send(task.getPublisherId(), "TASK_UPDATE",
                approve ? "任务审核通过" : "任务审核未通过",
                "你的任务《" + task.getTitle() + "》" + (approve ? "已通过审核，开始招募" : "未通过审核"),
                taskId);
    }

    public void offlineTask(Long taskId) {
        Task task = new Task();
        task.setId(taskId);
        task.setStatus(TaskStatus.OFFLINE.getCode());
        taskMapper.updateById(task);
    }

    // ---- 私有方法 ----

    private void saveTaskTags(Long taskId, List<Long> tagIds) {
        if (CollectionUtils.isEmpty(tagIds)) return;
        taskTagMapper.deleteByTaskId(taskId);
        tagIds.forEach(tagId -> taskTagMapper.insert(taskId, tagId));
    }

    private Map<String, Object> buildTaskVO(Task task) {
        List<Tag> tags = tagMapper.selectByTaskId(task.getId());
        User publisher = userMapper.selectById(task.getPublisherId());
        return Map.of(
                "task", task,
                "tags", tags,
                "publisherName", publisher != null ? publisher.getNickname() : ""
        );
    }
}
