import '../models/photoshoot_theme_model.dart';

/// 写真主题配置数据
class PhotoshootThemes {
  /// 获取所有写真主题
  static List<PhotoshootTheme> getAllThemes() {
    return [
      // 1. 健身模特写真
      const PhotoshootTheme(
        id: 'fitness_model',
        title: 'Fitness Model',
        emoji: '🏋️',
        description:
            'Professional fitness photography with perfect muscle definition',
        subtitle: 'Show your strength and dedication 💪',
        photoCount: 24,
        previewImages: [
          'assets/images/photoshoot/fitness_model/preview_1.jpg',
          'assets/images/photoshoot/fitness_model/preview_2.jpg',
          'assets/images/photoshoot/fitness_model/preview_3.jpg',
          'assets/images/photoshoot/fitness_model/preview_4.jpg',
          'assets/images/photoshoot/fitness_model/preview_5.jpg',
          'assets/images/photoshoot/fitness_model/preview_6.jpg',
        ],
        aiPrompt: '''
【CRITICAL】专业健身模特写真风格 - 极致力量美学转换：

🔥 EXTREME身体重塑要求：
- 肌肉线条必须DRAMATICALLY增强，每一条肌纤维都清晰可见
- 体脂率视觉效果降至8-12%，腹肌、背阔肌、三角肌极度突出
- 血管纹理HYPER-REALISTIC呈现，展现极致健美状态
- 身体比例按黄金比例重新塑造，肩宽腰细效果夸张化

💡 专业摄影技术规格：
- 使用85mm-135mm镜头效果，浅景深虚化背景
- Rembrandt lighting布光，45度角主光源创造立体阴影
- 高对比度black&white或cinematic color grading
- ISO 100, f/2.8光圈效果，确保肌肉纹理锐利

🎨 视觉风格强化：
- 参考Men's Health杂志封面级别的专业度
- 汗珠、肌肉光泽HYPER-DETAILED渲染
- 健身房器械作为前景虚化元素
- 动作捕捉：举重、拉伸、展示肌肉的power pose

🌟 氛围营造：
- 王者般的自信眼神，目光锐利有神
- 专业运动员的精神状态和气场
- 背景：现代化健身房或工业风格环境
- 整体色调：深色背景+高光突出，营造戏剧性效果

【OUTPUT REQUIREMENT】必须实现原图到专业健美模特的DRAMATIC transformation！
''',
      ),

      // 2. 海滩生活写真
      const PhotoshootTheme(
        id: 'beach_lifestyle',
        title: 'Beach Lifestyle',
        emoji: '🌊',
        description: 'Relaxed beach photography with golden hour vibes',
        subtitle: 'Capture your coastal moments 🌅',
        photoCount: 20,
        previewImages: [
          'assets/images/photoshoot/beach_lifestyle/preview_1.jpg',
          'assets/images/photoshoot/beach_lifestyle/preview_2.jpg',
          'assets/images/photoshoot/beach_lifestyle/preview_3.jpg',
          'assets/images/photoshoot/beach_lifestyle/preview_4.jpg',
          'assets/images/photoshoot/beach_lifestyle/preview_5.jpg',
          'assets/images/photoshoot/beach_lifestyle/preview_6.jpg',
        ],
        aiPrompt: '''
【CRITICAL】海滩度假写真风格 - 梦幻海岸线变身：

🌊 CINEMATIC海滩场景重构：
- 马尔代夫级别的crystal clear海水，渐变从翡翠绿到深蓝
- 细腻白沙滩质感，每一粒沙子都reflecting golden sunlight
- 椰林摇曳、海浪轻拍的HYPER-REALISTIC动态效果
- 远景：无人岛屿轮廓，营造私密度假村氛围

📸 黄金时刻摄影技术：
- Golden Hour完美timing（日落前30分钟）
- 使用50mm-85mm镜头，f/1.8-2.8大光圈背景虚化
- 逆光+反光板补光技术，创造rim lighting轮廓光
- 色温5500K-6500K，突出warm skin tone和cool ocean contrast

👙 度假风造型升级：
- 高端resort wear：designer bikini、flowing beach dress、boho accessories
- 肌肤呈现健康的bronze tan效果，自然光泽感
- 头发：beach waves自然卷曲，被海风轻抚的动感
- 妆容：dewy skin finish，自然裸妆with subtle highlight

🎭 情感表达深化：
- 眼神：dreamy and carefree，仿佛沉浸在完美假期中
- 姿态：lazy luxury poses，随意但优雅的body language
- 表情：genuine happiness，发自内心的放松微笑
- 互动：与海浪、沙滩、阳光的natural interaction

🎨 色彩美学强化：
- 主色调：turquoise blue + golden yellow + sandy beige
- 高饱和度but naturally balanced
- 胶片感color grading：略微overexposed的dreamy effect
- 对比度适中，保持柔和浪漫氛围

【OUTPUT REQUIREMENT】将普通照片转换为Vogue级别的海滩度假大片！
''',
      ),

      // 3. 都市时尚写真
      const PhotoshootTheme(
        id: 'urban_fashion',
        title: 'Urban Fashion',
        emoji: '🏙️',
        description: 'Modern city fashion with architectural backgrounds',
        subtitle: 'Express your urban style 🌆',
        photoCount: 18,
        previewImages: [
          'assets/images/photoshoot/urban_fashion/preview_1.jpg',
          'assets/images/photoshoot/urban_fashion/preview_2.jpg',
          'assets/images/photoshoot/urban_fashion/preview_3.jpg',
          'assets/images/photoshoot/urban_fashion/preview_4.jpg',
          'assets/images/photoshoot/urban_fashion/preview_5.jpg',
          'assets/images/photoshoot/urban_fashion/preview_6.jpg',
        ],
        aiPrompt: '''
【CRITICAL】都市时尚写真风格 - 摩登都市精英变身：

🏙️ METROPOLITAN场景重塑：
- 现代摩天大楼glass facade作为几何背景
- 利用building reflections创造mirror effect和depth
- Urban canyon效果：高楼林立中的光影corridor
- 夜景option：neon lights、city skyline、light trails动感

📱 时尚摄影技术进阶：
- 35mm-50mm广角镜头，捕捉都市grand scale
- f/2.8-4.0光圈，保持前景清晰+背景适度虚化  
- 使用available light：street lamps、building lights、golden hour
- High fashion photography风格：sharp contrast、dramatic shadows

👔 COUTURE造型升级：
- Designer pieces：Armani、Zara、COS minimalist aesthetic
- Color palette：monochromatic black/white/grey + accent color
- Accessories：statement jewelry、designer handbag、structured coat
- Grooming：sleek hair、bold makeup或clean minimal look

🎯 Editorial姿态指导：
- Power poses：confident stride、architectural lean、commanding presence  
- 眼神：piercing gaze，展现都市精英的determination
- Body language：angular、geometric、与建筑线条呼应
- Movement：walking shot、hair flip、coat flowing in urban wind

🎨 色彩分级强化：
- Cool tone dominance：steel blue、concrete grey、glass green
- High contrast black&white option for timeless elegance
- Cinematic color grading：teal&orange或desaturated luxury
- 质感强调：fabric texture、metal reflection、glass transparency

🌃 氛围营造深化：
- 都市丛林中的时尚icon感觉
- CEO/Creative Director级别的professional aura
- 与城市rhythm同步的dynamic energy
- Modern sophistication meets street smart attitude

【OUTPUT REQUIREMENT】打造Harper's Bazaar封面级别的都市时尚大片！
''',
      ),

      // 4. 复古胶片写真
      const PhotoshootTheme(
        id: 'vintage_film',
        title: 'Vintage Film',
        emoji: '📸',
        description: 'Nostalgic film photography with retro aesthetics',
        subtitle: 'Timeless vintage vibes 🎞️',
        photoCount: 22,
        previewImages: [
          'assets/images/photoshoot/vintage_film/preview_1.jpg',
          'assets/images/photoshoot/vintage_film/preview_2.jpg',
          'assets/images/photoshoot/vintage_film/preview_3.jpg',
          'assets/images/photoshoot/vintage_film/preview_4.jpg',
          'assets/images/photoshoot/vintage_film/preview_5.jpg',
          'assets/images/photoshoot/vintage_film/preview_6.jpg',
        ],
        aiPrompt: '''
【CRITICAL】复古胶片写真风格 - 时光穿越美学重现：

📷 AUTHENTIC胶片技术模拟：
- Kodak Portra 400胶片色彩特征：warm undertone、soft contrast
- 35mm film grain texture，natural imperfections和light leaks
- Slightly overexposed highlight，shadow detail保留film特色
- Vintage lens效果：slight vignetting、soft focus edges

🕰️ 时代场景重构：
- 60s-80s经典场景：vintage café、老式书店、retro diner
- 经典建筑：art deco、mid-century modern、老式霓虹招牌
- Props integration：vintage car、old telephone booth、retro furniture
- 街景：cobblestone streets、老式路灯、vintage shop fronts

👗 PERIOD-ACCURATE造型：
- 60s: A-line dresses、pillbox hats、cat-eye glasses、mod style
- 70s: flare jeans、peasant blouses、fringe details、earth tones
- 80s: power shoulders、bold patterns、statement jewelry、big hair
- Makeup: period-specific眼线、lip color、blush placement

🎭 复古情感表达：
- 眼神：nostalgic、dreamy、充满story的深邃感
- 姿态：classic portrait poses、elegant hand placement
- 表情：subtle smile、pensive look、timeless beauty
- Movement：graceful、deliberate、与时代rhythm同步

🎨 胶片色彩美学：
- Color palette: muted earth tones、faded pastels、sepia undertones
- Desaturated but warm：减少数字感，增加analog warmth
- Highlight rolloff：soft、natural、避免digital harshness  
- Shadow detail：保持film-like depth和dimension

📸 经典构图法则：
- Rule of thirds with vintage sensibility
- Natural framing：doorways、windows、architectural elements
- Depth of field：浅景深创造dreamy separation
- Candid moments：抓拍自然瞬间，避免过度posed

【OUTPUT REQUIREMENT】创造仿佛从家族相册中走出的timeless vintage portrait！
''',
      ),

      // 5. 清新自然写真
      const PhotoshootTheme(
        id: 'natural_fresh',
        title: 'Natural Fresh',
        emoji: '🌿',
        description: 'Pure and natural photography in outdoor settings',
        subtitle: 'Embrace natural beauty 🌸',
        photoCount: 26,
        previewImages: [
          'assets/images/photoshoot/natural_fresh/preview_1.jpg',
          'assets/images/photoshoot/natural_fresh/preview_2.jpg',
          'assets/images/photoshoot/natural_fresh/preview_3.jpg',
          'assets/images/photoshoot/natural_fresh/preview_4.jpg',
          'assets/images/photoshoot/natural_fresh/preview_5.jpg',
          'assets/images/photoshoot/natural_fresh/preview_6.jpg',
        ],
        aiPrompt: '''
【CRITICAL】清新自然写真风格 - 森系仙女美学升华：

🌿 BOTANICAL场景重塑：
- 梦幻森林setting：sunlight filtering through leaves创造dappled light
- Wildflower meadow：lavender fields、daisy chains、tall grass swaying
- 樱花季节：pink petals falling、soft focus background
- 清晨dewdrops on leaves，macro detail和bokeh effect

☀️ 自然光线艺术：
- Golden hour soft lighting：warm、diffused、flattering skin tone
- Backlighting透过头发创造halo effect
- Open shade下的even lighting，避免harsh shadows
- 使用reflector（天然：白色墙面、沙滩）提亮眼部

👕 ORGANIC造型美学：
- Flowing fabrics：linen、cotton、chiffon在微风中的movement
- Earth tone palette：cream、sage green、dusty pink、warm beige
- Minimalist accessories：delicate jewelry、flower crown、bare feet
- Hair：loose waves、braids with flowers、natural texture

🦋 纯真情感捕捉：
- 眼神：clear、bright、充满wonder和innocence  
- 笑容：genuine、spontaneous、发自内心的joy
- 姿态：relaxed、organic、与自然environment互动
- Movement：twirling、running、gentle gestures

🎨 清新色彩调色：
- High key lighting：bright、airy、minimal shadows
- Pastel color grading：soft pink、mint green、cream white
- Slightly desaturated for dreamy effect
- 避免heavy contrast，保持gentle transition

📷 自然摄影技法：
- 50mm-85mm镜头：natural perspective、flattering compression
- f/1.4-2.8大光圈：creamy bokeh、subject isolation
- 抓拍natural expressions和candid moments
- Environmental portraits：人与自然的harmonious integration

🌸 氛围营造强化：
- Fairy tale princess in enchanted forest感觉
- Pure、innocent、untouched by urban life
- Connection with nature：touching flowers、sitting in grass
- Ethereal beauty：仿佛woodland nymph的magical presence

【OUTPUT REQUIREMENT】打造Studio Ghibli动画般的梦幻自然系写真！
''',
      ),

      // 6. 专业商务写真
      const PhotoshootTheme(
        id: 'professional_business',
        title: 'Professional Business',
        emoji: '👔',
        description: 'Executive portraits with professional elegance',
        subtitle: 'Professional confidence 💼',
        photoCount: 16,
        previewImages: [
          'assets/images/photoshoot/professional_business/preview_1.jpg',
          'assets/images/photoshoot/professional_business/preview_2.jpg',
          'assets/images/photoshoot/professional_business/preview_3.jpg',
          'assets/images/photoshoot/professional_business/preview_4.jpg',
          'assets/images/photoshoot/professional_business/preview_5.jpg',
          'assets/images/photoshoot/professional_business/preview_6.jpg',
        ],
        aiPrompt: '''
【CRITICAL】专业商务写真风格 - 企业领袖形象重塑：

💼 EXECUTIVE场景构建：
- Corner office with floor-to-ceiling windows、city skyline view
- Modern conference room：glass table、leather chairs、minimalist design
- Corporate lobby：marble floors、contemporary art、sophisticated lighting
- 高端酒店business lounge：understated luxury、professional atmosphere

📸 企业级摄影技术：
- 85mm-135mm portrait lens：flattering compression、professional distance
- Rembrandt lighting setup：45-degree key light创造dimensional face sculpting
- Hair light和background light分离主体，增加depth
- f/2.8-5.6光圈：sharp focus on eyes、subtle background separation

👔 C-SUITE造型标准：
- Tailored suits：Italian cut、perfect fit、premium fabrics
- Color psychology：navy blue (trustworthy)、charcoal grey (authoritative)
- Accessories：Swiss watch、quality leather shoes、subtle tie pattern
- Grooming：professional haircut、clean shave或well-groomed facial hair

🎯 权威姿态指导：
- Power poses：confident stance、open body language、commanding presence
- Hand placement：purposeful、elegant、避免awkward positioning
- Eye contact：direct、penetrating、展现leadership confidence
- Facial expression：serious but approachable、intelligent、decisive

🎨 企业色彩美学：
- Monochromatic sophistication：blacks、whites、greys with accent colors
- High contrast for impact：sharp shadows、defined highlights
- Color grading：cool tones for professionalism、warm accents for approachability
- Texture emphasis：fabric weave、leather grain、metal finish

📊 商务摄影构图：
- Formal composition：centered、symmetrical、balanced
- Environmental context：incorporating office elements、technology、documents
- Multiple angles：headshot、three-quarter、full body professional poses
- Background management：clean、uncluttered、supports subject

💡 心理影响强化：
- CEO/President级别的executive presence
- 投资者presentation ready的professional image
- Fortune 500 company leadership team标准
- International business meeting appropriate appearance

🏢 品牌形象一致性：
- Corporate headshot quality：LinkedIn profile、company website ready
- Media interview appropriate：TV appearance、press release worthy
- Board meeting presence：commanding respect、inspiring confidence
- Client meeting impression：trustworthy、competent、successful

【OUTPUT REQUIREMENT】创造Forbes封面级别的企业领袖形象！
''',
      ),
    ];
  }

  /// 根据ID获取主题
  static PhotoshootTheme? getThemeById(String id) {
    try {
      return getAllThemes().firstWhere((theme) => theme.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取AI提示词
  static String getAIPrompt(String themeId) {
    return getThemeById(themeId)?.aiPrompt ?? '';
  }

  /// 检查主题是否存在
  static bool themeExists(String themeId) {
    return getAllThemes().any((theme) => theme.id == themeId);
  }
}
