-- 启用生成 UUID 的扩展
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 用户表：支持手机号登录和邮箱登录两种模式
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  login_mode VARCHAR(20) NOT NULL, -- 'phoneSms' | 'emailPassword'
  phone VARCHAR(32),               -- 手机号登录使用，可为空
  email VARCHAR(255),              -- 邮箱登录使用，可为空
  password_hash VARCHAR(255),      -- 仅 emailPassword 模式使用
  nickname VARCHAR(100),           -- 用户昵称
  avatar_url TEXT,                 -- 头像URL（MinIO存储）
  bio TEXT,                        -- 个人简介
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 手机号唯一（忽略空值）
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_unique
  ON users (phone) WHERE phone IS NOT NULL;

-- 邮箱唯一（忽略空值）
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique
  ON users (email) WHERE email IS NOT NULL;

-- login_mode 索引
CREATE INDEX IF NOT EXISTS idx_users_login_mode
  ON users (login_mode);

-- 生成历史表：记录每次生成的结果
CREATE TABLE IF NOT EXISTS generation_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,           -- 生成类型：photobooth/enhance/filter/photoshoot/custom 等
  image_url TEXT NOT NULL,             -- 对象存储中的访问 URL
  prompt TEXT,                         -- 使用的提示词（可选）
  effect_id VARCHAR(100),             -- 具体效果ID，如 photobooth 的效果ID（可选）
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 按用户和时间查询的联合索引，便于分页
CREATE INDEX IF NOT EXISTS idx_generation_history_user_time
  ON generation_history(user_id, created_at DESC);
