require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const crypto = require('crypto');
const Minio = require('minio');
const multer = require('multer');

const app = express();
const PORT = process.env.PORT || 3000;

// 万能验证码（仅开发阶段使用）
const MAGIC_SMS_CODE = process.env.MAGIC_SMS_CODE || '666666';

// 随机昵称生成器
function generateRandomNickname() {
  const surnames = ['李', '王', '张', '刘', '陈', '杨', '黄', '吴', '赵', '周', '徐', '孙', '马', '朱', '胡', '郭', '何', '林', '罗', '高'];
  const names = [
    '思远', '雨萱', '子轩', '欣怡', '浩然', '婉婷', '宇航', '诗涵', '俊杰', '梦琪',
    '晨曦', '悦心', '志强', '佳怡', '建国', '文静', '明辉', '雅琪', '伟杰', '慧敏',
    '天佑', '梓涵', '博文', '诗雨', '锦程', '馨怡', '昊天', '雨晴', '启航', '梦瑶',
    '晓东', '紫萱', '家豪', '若曦', '宏伟', '思琪', '瑞阳', '静怡', '振华', '诗婷'
  ];
  
  const surname = surnames[Math.floor(Math.random() * surnames.length)];
  const name = names[Math.floor(Math.random() * names.length)];
  
  return surname + name;
}

// 数据库连接池
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME || 'ai_image',
  user: process.env.DB_USER || 'ai_image_user',
  password: process.env.DB_PASSWORD || 'change_this_password',
});

// MinIO 客户端
const minioClient = new Minio.Client({
  endPoint: process.env.MINIO_ENDPOINT || 'localhost',
  port: Number(process.env.MINIO_PORT || 9000),
  useSSL: false,
  accessKey: process.env.MINIO_ACCESS_KEY || 'admin',
  secretKey: process.env.MINIO_SECRET_KEY || 'change_this_minio_password',
});

const MINIO_BUCKET = process.env.MINIO_BUCKET || 'ai-images';
// 对外访问 MinIO 的基础URL（Flutter 直接用这个访问图片）
const MINIO_PUBLIC_ENDPOINT =
  process.env.MINIO_PUBLIC_ENDPOINT || 'http://localhost:9200';

// 用于处理 multipart/form-data 上传的内存存储
const upload = multer({ storage: multer.memoryStorage() });

// 确保 bucket 允许匿名读取对象，方便客户端直接访问图片
async function ensureBucketPublicRead() {
  const policy = JSON.stringify({
    Version: '2012-10-17',
    Statement: [
      {
        Effect: 'Allow',
        Principal: { AWS: ['*'] },
        Action: ['s3:GetObject'],
        Resource: [`arn:aws:s3:::${MINIO_BUCKET}/*`],
      },
    ],
  });

  try {
    await minioClient.setBucketPolicy(MINIO_BUCKET, policy);
    console.log('[minio] setBucketPolicy public-read for bucket=%s', MINIO_BUCKET);
  } catch (err) {
    console.error('[minio] setBucketPolicy error:', err);
  }
}

app.use(cors());
app.use(express.json());

// 健康检查接口，用于确认后端容器是否正常运行
app.get('/health', (req, res) => {
  res.json({ status: 'ok', env: process.env.NODE_ENV || 'development' });
});

// 简单的 token 生成：仅开发调试用，真实环境请换成 JWT
function makeToken(user) {
  return `dev-token-${user.id}`;
}

// 从 Authorization 头里解析 token（格式：Bearer xxx）
function getTokenFromHeader(req) {
  const auth = req.headers['authorization'];
  if (!auth) return null;
  const parts = auth.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') return null;
  return parts[1];
}

// 简单从 token 中解析 userId（和 makeToken 对应）
function parseUserIdFromToken(token) {
  if (!token) return null;
  if (!token.startsWith('dev-token-')) return null;
  return token.replace('dev-token-', '');
}

// 简单认证中间件：从 dev-token 中解析 userId
async function authMiddleware(req, res, next) {
  const token = getTokenFromHeader(req);
  const userId = parseUserIdFromToken(token);

  if (!userId) {
    return res.status(401).json({ error: 'unauthorized' });
  }

  req.userId = userId;
  next();
}

// 注册接口
app.post('/auth/register', async (req, res) => {
  const { loginMode, phone, smsCode, email, password } = req.body || {};

  if (!loginMode) {
    return res.status(400).json({ error: 'loginMode is required' });
  }

  try {
    if (loginMode === 'phoneSms') {
      if (!phone) {
        return res.status(400).json({ error: 'phone is required for phoneSms mode' });
      }

      // 万能验证码，仅开发阶段
      if (!smsCode || smsCode !== MAGIC_SMS_CODE) {
        return res.status(400).json({ error: 'invalid smsCode' });
      }

      // 查询是否已有用户
      const existing = await pool.query(
        'SELECT * FROM users WHERE phone = $1 LIMIT 1',
        [phone]
      );

      let user;
      if (existing.rows.length > 0) {
        user = existing.rows[0];
      } else {
        const insert = await pool.query(
          'INSERT INTO users (login_mode, phone) VALUES ($1, $2) RETURNING *',
          ['phoneSms', phone]
        );
        user = insert.rows[0];
      }

      const token = makeToken(user);
      return res.json({
        userId: user.id,
        token,
        loginMode: user.login_mode,
        expiresIn: 30 * 24 * 60 * 60,
      });
    }

    if (loginMode === 'emailPassword') {
      if (!email || !password) {
        return res.status(400).json({ error: 'email and password are required for emailPassword mode' });
      }

      // 简单处理：直接存明文密码，仅开发环境使用
      const existing = await pool.query(
        'SELECT * FROM users WHERE email = $1 LIMIT 1',
        [email]
      );

      if (existing.rows.length > 0) {
        return res.status(400).json({ error: 'email already registered' });
      }

      const insert = await pool.query(
        'INSERT INTO users (login_mode, email, password_hash) VALUES ($1, $2, $3) RETURNING *',
        ['emailPassword', email, password]
      );

      const user = insert.rows[0];
      const token = makeToken(user);
      return res.json({
        userId: user.id,
        token,
        loginMode: user.login_mode,
        expiresIn: 30 * 24 * 60 * 60,
      });
    }

    return res.status(400).json({ error: 'unsupported loginMode' });
  } catch (err) {
    console.error('Register error:', err);
    return res.status(500).json({ error: 'internal_error' });
  }
});

// 登录接口
app.post('/auth/login', async (req, res) => {
  const { loginMode, phone, smsCode, email, password } = req.body || {};

  if (!loginMode) {
    return res.status(400).json({ error: 'loginMode is required' });
  }

  try {
    if (loginMode === 'phoneSms') {
      if (!phone) {
        return res.status(400).json({ error: 'phone is required for phoneSms mode' });
      }

      // 万能验证码，仅开发阶段
      if (!smsCode || smsCode !== MAGIC_SMS_CODE) {
        return res.status(400).json({ error: 'invalid smsCode' });
      }

      // 没有就自动注册一个
      const existing = await pool.query(
        'SELECT * FROM users WHERE phone = $1 LIMIT 1',
        [phone]
      );

      let user;
      if (existing.rows.length > 0) {
        user = existing.rows[0];
      } else {
        // 新用户注册，自动生成随机昵称
        const randomNickname = generateRandomNickname();
        const insert = await pool.query(
          'INSERT INTO users (login_mode, phone, nickname) VALUES ($1, $2, $3) RETURNING *',
          ['phoneSms', phone, randomNickname]
        );
        user = insert.rows[0];
        console.log(`[注册] 新用户 ${user.id} 自动昵称: ${randomNickname}`);
      }

      const token = makeToken(user);
      return res.json({
        userId: user.id,
        token,
        loginMode: user.login_mode,
        nickname: user.nickname,
        avatarUrl: user.avatar_url,
        bio: user.bio,
        expiresIn: 30 * 24 * 60 * 60,
      });
    }

    if (loginMode === 'emailPassword') {
      if (!email || !password) {
        return res.status(400).json({ error: 'email and password are required for emailPassword mode' });
      }

      const existing = await pool.query(
        'SELECT * FROM users WHERE email = $1 LIMIT 1',
        [email]
      );

      if (existing.rows.length === 0) {
        return res.status(400).json({ error: 'user_not_found' });
      }

      const user = existing.rows[0];
      if (user.password_hash !== password) {
        return res.status(400).json({ error: 'invalid_password' });
      }

      const token = makeToken(user);
      return res.json({
        userId: user.id,
        token,
        loginMode: user.login_mode,
        nickname: user.nickname,
        avatarUrl: user.avatar_url,
        bio: user.bio,
        expiresIn: 30 * 24 * 60 * 60,
      });
    }

    return res.status(400).json({ error: 'unsupported loginMode' });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ error: 'internal_error' });
  }
});

// 获取当前用户信息
app.get('/auth/profile', async (req, res) => {
  const token = getTokenFromHeader(req);
  const userId = parseUserIdFromToken(token);

  if (!userId) {
    return res.status(401).json({ error: 'unauthorized' });
  }

  try {
    const result = await pool.query('SELECT * FROM users WHERE id = $1 LIMIT 1', [userId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'user_not_found' });
    }

    const user = result.rows[0];
    return res.json({
      userId: user.id,
      loginMode: user.login_mode,
      phone: user.phone,
      email: user.email,
      nickname: user.nickname,
      avatarUrl: user.avatar_url,
      bio: user.bio,
      createdAt: user.created_at,
    });
  } catch (err) {
    console.error('Profile error:', err);
    return res.status(500).json({ error: 'internal_error' });
  }
});

// 获取用户统计数据
app.get('/user/stats', authMiddleware, async (req, res) => {
  const userId = req.userId;

  try {
    // 今日生成数
    const todayResult = await pool.query(
      `SELECT COUNT(*) as count FROM generation_history 
       WHERE user_id = $1 AND created_at >= CURRENT_DATE`,
      [userId]
    );

    // 本周生成数（周一到今天）
    const weekResult = await pool.query(
      `SELECT COUNT(*) as count FROM generation_history 
       WHERE user_id = $1 AND created_at >= date_trunc('week', CURRENT_DATE)`,
      [userId]
    );

    // 总生成数
    const totalResult = await pool.query(
      `SELECT COUNT(*) as count FROM generation_history 
       WHERE user_id = $1`,
      [userId]
    );

    return res.json({
      todayCount: parseInt(todayResult.rows[0].count, 10),
      weekCount: parseInt(weekResult.rows[0].count, 10),
      totalCount: parseInt(totalResult.rows[0].count, 10),
    });
  } catch (err) {
    console.error('Stats error:', err);
    return res.status(500).json({ error: 'internal_error' });
  }
});

// 更新用户资料
app.put('/user/profile', authMiddleware, async (req, res) => {
  const userId = req.userId;
  const { nickname, avatarUrl, bio } = req.body || {};

  try {
    // 构建动态更新字段
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (nickname !== undefined) {
      updates.push(`nickname = $${paramIndex}`);
      values.push(nickname);
      paramIndex++;
    }

    if (avatarUrl !== undefined) {
      updates.push(`avatar_url = $${paramIndex}`);
      values.push(avatarUrl);
      paramIndex++;
    }

    if (bio !== undefined) {
      updates.push(`bio = $${paramIndex}`);
      values.push(bio);
      paramIndex++;
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'no_fields_to_update' });
    }

    // 添加 updated_at
    updates.push(`updated_at = NOW()`);
    
    // 添加 userId 作为最后一个参数
    values.push(userId);

    const sql = `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING *`;
    
    console.log('[Profile Update] SQL:', sql);
    console.log('[Profile Update] Values:', values);

    const result = await pool.query(sql, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'user_not_found' });
    }

    const user = result.rows[0];
    return res.json({
      userId: user.id,
      loginMode: user.login_mode,
      phone: user.phone,
      email: user.email,
      nickname: user.nickname,
      avatarUrl: user.avatar_url,
      bio: user.bio,
      updatedAt: user.updated_at,
    });
  } catch (err) {
    console.error('Profile update error:', err);
    return res.status(500).json({ error: 'internal_error' });
  }
});

// 生成预签名上传 URL（真实接入 MinIO）
app.post('/storage/upload-url', authMiddleware, async (req, res) => {
  try {
    const { fileName, contentType } = req.body || {};

    if (!fileName) {
      return res.status(400).json({ error: 'fileName is required' });
    }

    console.log(
      '[upload-url] userId=%s fileName=%s contentType=%s',
      req.userId,
      fileName,
      contentType,
    );

    console.log('[upload-url] step=before bucketExists bucket=%s', MINIO_BUCKET);

    // 确保 bucket 存在
    const bucketExists = await minioClient.bucketExists(MINIO_BUCKET).catch(
      (err) => {
        console.error('[upload-url] bucketExists error:', err);
        if (err && err.code === 'NoSuchBucket') {
          return false;
        }
        throw err;
      }
    );

    console.log('[upload-url] step=after bucketExists exists=%s', bucketExists);

    if (!bucketExists) {
      await minioClient.makeBucket(MINIO_BUCKET, '');
      console.log(`Created MinIO bucket: ${MINIO_BUCKET}`);
    }

    // 确保 bucket 具备公共读取权限
    await ensureBucketPublicRead();

    // 生成对象 key
    const ext = fileName.includes('.') ? fileName.split('.').pop() : 'png';
    const objectKey = `users/${req.userId}/generated/${Date.now()}-${crypto
      .randomBytes(6)
      .toString('hex')}.${ext}`;

    // 生成预签名 PUT URL，默认1小时有效
    const expirySeconds = 60 * 60;

    console.log('[upload-url] step=before presignedPutObject objectKey=%s', objectKey);

    // 在 MinIO JS SDK 7.x 中，presignedPutObject 返回 Promise，这里直接 await
    const uploadUrlInternal = await minioClient.presignedPutObject(
      MINIO_BUCKET,
      objectKey,
      expirySeconds,
      { 'Content-Type': contentType || 'application/octet-stream' },
    );

    console.log('[upload-url] step=after presignedPutObject url=%s', uploadUrlInternal);

    // 这里直接使用 presignedPutObject 返回的完整 URL 作为上传地址，避免修改 host 破坏签名
    const uploadUrl = String(uploadUrlInternal);

    // 前端展示/下载时使用的文件访问URL（通过 MINIO_PUBLIC_ENDPOINT 暴露的端点）
    // 注意：这里不要对 objectKey 进行整体 encode，否则路径分隔符 / 会变成 %2F，MinIO 无法找到对象
    const fileUrl = `${MINIO_PUBLIC_ENDPOINT.replace(/\/$/, '')}/${
      MINIO_BUCKET
    }/${objectKey}`;

    return res.json({ uploadUrl, fileUrl, objectKey, contentType });
  } catch (err) {
    console.error('upload-url error:', err);
    return res.status(500).json({ error: 'internal_error' });
  }
});

// 直接上传文件到 MinIO（后端代上传）
app.post('/storage/upload-direct', authMiddleware, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'file is required' });
    }

    const originalName = req.file.originalname || 'image.png';
    const contentType = (req.body && req.body.contentType) || req.file.mimetype || 'application/octet-stream';

    console.log(
      '[upload-direct] userId=%s fileName=%s contentType=%s size=%d',
      req.userId,
      originalName,
      contentType,
      req.file.size,
    );

    // 确保 bucket 存在
    const bucketExists = await minioClient.bucketExists(MINIO_BUCKET).catch((err) => {
      console.error('[upload-direct] bucketExists error:', err);
      if (err && err.code === 'NoSuchBucket') {
        return false;
      }
      throw err;
    });

    if (!bucketExists) {
      await minioClient.makeBucket(MINIO_BUCKET, '');
      console.log(`[upload-direct] Created MinIO bucket: ${MINIO_BUCKET}`);
    }

    // 确保 bucket 具备公共读取权限
    await ensureBucketPublicRead();

    const ext = originalName.includes('.') ? originalName.split('.').pop() : 'png';
    const objectKey = `users/${req.userId}/generated/${Date.now()}-${crypto
      .randomBytes(6)
      .toString('hex')}.${ext}`;

    console.log('[upload-direct] putObject objectKey=%s', objectKey);

    await minioClient.putObject(
      MINIO_BUCKET,
      objectKey,
      req.file.buffer,
      {
        'Content-Type': contentType,
      },
    );

    const fileUrl = `${MINIO_PUBLIC_ENDPOINT.replace(/\/$/, '')}/${MINIO_BUCKET}/${objectKey}`;

    return res.json({ fileUrl, objectKey, contentType });
  } catch (err) {
    console.error('upload-direct error:', err);
    return res.status(500).json({ error: 'internal_error' });
  }
});

// 写入生成历史
app.post('/generation/history', authMiddleware, async (req, res) => {
  try {
    const { type, imageUrl, prompt, effectId } = req.body || {};

    if (!type || !imageUrl) {
      return res.status(400).json({ error: 'type and imageUrl are required' });
    }

    console.log(
      '[create-history] userId=%s type=%s imageUrl=%s effectId=%s',
      req.userId,
      type,
      imageUrl,
      effectId,
    );

    const insert = await pool.query(
      `INSERT INTO generation_history (user_id, type, image_url, prompt, effect_id)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, user_id, type, image_url, prompt, effect_id, created_at`,
      [req.userId, type, imageUrl, prompt || null, effectId || null]
    );

    const row = insert.rows[0];
    return res.json({
      id: row.id,
      userId: row.user_id,
      type: row.type,
      imageUrl: row.image_url,
      prompt: row.prompt,
      effectId: row.effect_id,
      createdAt: row.created_at,
    });
  } catch (err) {
    console.error('create history error:', err);
    return res.status(500).json({ error: 'internal_error' });
  }
});

// 查询当前用户的生成历史，支持分页
app.get('/generation/history', authMiddleware, async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const pageSize = Math.min(
      Math.max(parseInt(req.query.pageSize, 10) || 20, 1),
      50
    );

    const offset = (page - 1) * pageSize;

    const result = await pool.query(
      `SELECT id, user_id, type, image_url, prompt, effect_id, created_at
       FROM generation_history
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [req.userId, pageSize, offset]
    );

    const items = result.rows.map((row) => ({
      id: row.id,
      userId: row.user_id,
      type: row.type,
      imageUrl: row.image_url,
      prompt: row.prompt,
      effectId: row.effect_id,
      createdAt: row.created_at,
    }));

    let hasMore = false;
    if (items.length === pageSize) {
      const next = await pool.query(
        `SELECT 1 FROM generation_history WHERE user_id = $1 AND created_at < $2 LIMIT 1`,
        [req.userId, items[items.length - 1].createdAt]
      );
      hasMore = next.rows.length > 0;
    }

    return res.json({ items, page, pageSize, hasMore });
  } catch (err) {
    console.error('list history error:', err);
    return res.status(500).json({ error: 'internal_error' });
  }
});

app.listen(PORT, () => {
  console.log(`AI Image API listening on port ${PORT}`);
});
