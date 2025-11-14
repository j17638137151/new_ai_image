# 图片资源管理

## 概述
本项目使用了来自 Unsplash 的高质量免费图片作为演示数据。所有图片都经过优化，尺寸为 400x400px，居中裁剪。

## 分类图片说明

### 🎨 Art Toy（艺术玩具）
- **内容**：手办、收藏品、艺术玩具
- **数量**：6张
- **风格**：现代艺术品、创意设计

### 💪 Muscle Filter（肌肉滤镜）
- **内容**：健身、运动、肌肉展示
- **数量**：6张
- **风格**：健身房、运动员、力量训练

### 💰 Old Money（复古奢华）
- **内容**：复古风格、经典服装、奢华生活
- **数量**：6张
- **风格**：优雅、经典、高端

### 🌅 Beach Sunset（海滩日落）
- **内容**：海滩风景、日落、自然美景
- **数量**：6张
- **风格**：温暖、宁静、自然

### 📱 相册分类（保持空数据）
- **Photobooth photos** 💕：由手机相册提供
- **Enhance** ✨：由手机相册提供（网格布局）

## 图片 URL 格式
```
https://images.unsplash.com/photo-{id}?w=400&h=400&fit=crop&crop=center
```

## 使用说明

### 更新图片
1. 浏览 [Unsplash](https://unsplash.com) 寻找合适的图片
2. 复制图片ID（URL中photo-后的部分）
3. 使用格式：`https://images.unsplash.com/photo-{ID}?w=400&h=400&fit=crop&crop=center`
4. 在 `category_model.dart` 中替换对应的URL

### 添加新分类
1. 在 `image_data_updater.dart` 中添加新的静态方法
2. 在 `CategoryModel.getDummyCategories()` 中添加新的分类
3. 确保图片风格与分类主题一致

## 版权说明
- 所有图片来自 [Unsplash](https://unsplash.com)
- Unsplash 提供免费的高质量图片
- 图片可用于商业和个人项目
- 无需获得许可，但鼓励署名

## 性能优化
- 所有图片都通过Unsplash的CDN优化
- 统一尺寸（400x400）确保布局一致性
- 居中裁剪保证图片主体内容完整
- 自动压缩和格式优化

## 备用方案
如果Unsplash图片加载失败，应用会：
1. 显示占位符图标
2. 保持布局完整性
3. 用户可以刷新重试

## 更新日志
- 2024-09-19：初始版本，添加4个分类的真实图片
- 保留2个分类为空，由相册功能提供
