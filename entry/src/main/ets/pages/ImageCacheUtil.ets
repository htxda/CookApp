import image from '@ohos.multimedia.image';
import common from '@ohos.app.ability.common';

// 全局图片缓存Map，key为图片标识，value为PixelMap
const imageCache = new Map<string, image.PixelMap>();
// 缓存大小限制（最多缓存10张图片）
const MAX_CACHE_SIZE = 10;
// 获取应用上下文（需在组件中初始化）
let context: common.UIAbilityContext | undefined;

/**
 * 初始化缓存工具的上下文
 * @param ctx 应用上下文
 */
export function initImageCache(ctx: common.UIAbilityContext) {
  context = ctx;
}

/**
 * 从缓存加载图片（支持本地资源和网络图片）
 * @param imageRes 图片资源（如 $r('app.media.test') 或网络URL）
 * @returns 缓存的PixelMap
 */
export async function getCachedImage(imageRes: Resource | string): Promise<image.PixelMap> {
  // 生成唯一缓存key
  const cacheKey = typeof imageRes === 'string' ? imageRes : imageRes.id.toString();

  // 优先从缓存获取
  if (imageCache.has(cacheKey)) {
    return imageCache.get(cacheKey)!;
  }

  let pixelMap: image.PixelMap;
  try {
    if (typeof imageRes === 'string') {
      // 网络图片/本地路径
      const imageSource = image.createImageSource(imageRes);
      pixelMap = await imageSource.createPixelMap();
    } else {
      // 本地资源图片
      if (!context) {
        throw new Error('请先调用initImageCache初始化上下文');
      }
      // 读取本地资源文件（API 11+ 使用 getRawFileDescriptor）
      const fileDescriptor = await context.resourceManager.getRawFileDescriptor(imageRes.id.toString());
      const imageSource = image.createImageSource(fileDescriptor);
      pixelMap = await imageSource.createPixelMap();
      // 修复：低版本API中 RawFileDescriptor 没有 close()，无需手动关闭
    }
    // 存入缓存，控制缓存大小
    if (imageCache.size >= MAX_CACHE_SIZE) {
      // 移除最旧的缓存项
      const firstKey = imageCache.keys().next().value;
      imageCache.delete(firstKey);
    }
    imageCache.set(cacheKey, pixelMap);
  } catch (error) {
    console.error('加载图片失败:', error);
    // 加载失败时返回空PixelMap（也可替换为默认占位图）
    pixelMap = await image.createImageSource('').createPixelMap();
  }
  return pixelMap;
}

/**
 * 清理指定图片缓存
 * @param imageRes 图片资源
 */
export function clearImageCache(imageRes: Resource | string) {
  const cacheKey = typeof imageRes === 'string' ? imageRes : imageRes.id.toString();
  imageCache.delete(cacheKey);
}

/**
 * 清空所有图片缓存
 */
export function clearAllImageCache() {
  imageCache.clear();
}