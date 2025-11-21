# Seed Data 测试账号

这些账号来自 `scp-backend/migrations/100_seed_sample_data.sql`，可以直接用于测试 web 应用。

## 供应商账号

### Fresh Farm Produce Co.
- **Owner**: `owner@freshfarm.com` / `password123`
- **Manager**: `manager@freshfarm.com` / `password123`
- **Sales Rep**: `sales1@freshfarm.com` / `password123`

### Ocean Fresh Seafood
- **Owner**: `owner@oceanfresh.com` / `password123`
- **Sales Rep**: `sales1@oceanfresh.com` / `password123`

### Premium Meats & Poultry
- **Owner**: `owner@premiummeats.com` / `password123`
- **Manager**: `manager@premiummeats.com` / `password123`

### Dairy Delights
- **Owner**: `owner@dairydelights.com` / `password123`
- **Sales Rep**: `sales1@dairydelights.com` / `password123`

### Beverage Solutions Inc.
- **Owner**: `owner@beveragesolutions.com` / `password123`

## 数据内容

每个供应商都有：
- **Products**: 多个产品（蔬菜、海鲜、肉类、乳制品、饮料等）
- **Orders**: 不同状态的订单（pending, accepted, completed, rejected）
- **Consumer Links**: 与消费者的关联
- **Conversations**: 与消费者的对话
- **Messages**: 消息记录
- **Complaints**: 投诉记录
- **Notifications**: 通知

## 使用说明

1. 使用上述任意账号登录
2. 登录后会自动跳转到对应的 dashboard
3. 可以查看和管理：
   - Products（产品）
   - Orders（订单）
   - Team Members（团队成员）
   - Consumer Links（消费者关联）
   - Conversations（对话）
   - Dashboard Stats（仪表板统计）

## 注意事项

- 所有账号密码都是：`password123`
- 登录时会自动尝试匹配正确的角色（owner/manager/sales_rep）
- 每个供应商的数据是独立的，只能看到自己供应商的数据

