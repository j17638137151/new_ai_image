const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'ai_image',
  user: 'ai_image_user',
  password: 'change_this_password',
});

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

async function addNicknames() {
  try {
    // 获取所有没有昵称的用户
    const result = await pool.query(
      'SELECT id FROM users WHERE nickname IS NULL OR nickname = \'\''
    );
    
    console.log(`找到 ${result.rows.length} 个没有昵称的用户`);
    
    for (const row of result.rows) {
      const nickname = generateRandomNickname();
      await pool.query(
        'UPDATE users SET nickname = $1 WHERE id = $2',
        [nickname, row.id]
      );
      console.log(`用户 ${row.id} 设置昵称: ${nickname}`);
    }
    
    console.log('完成！');
  } catch (err) {
    console.error('错误:', err);
  } finally {
    await pool.end();
  }
}

addNicknames();
