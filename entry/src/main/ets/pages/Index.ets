import { tansuo } from './tansuo';
import { xiuxiang } from './xiuxiang';
import { duoyan } from './duoyan';
import { jiludan } from './jiludan';

// 定义卡片数据接口
interface CardData {
  id: number;
  title: string;
  subTitle: string;
  image: Resource;
}

// 2. 定义导航项接口
interface NavItem {
  name: string;
  icon: Resource;
}


@Entry
@Component
struct RecipeApp {
  // --- 状态变量 ---
  @State isNavActive: boolean = false;
  @State currentIndex: number = 0;
  @State flyingIndex: number = -1;
  @State cardOffsets: number[] = [0, 0, 0];

  // --- 新增：防止动画叠加的状态 ---
  private isAnimating: boolean = false;
  private lastNavClickTime: number = 0;

  // --- 模拟数据 ---
  @State cards: CardData[] = [
    { id: 0, title: '红烧牛肉', subTitle: '精选五花，配以秘制酱汁...', image: $r('app.media.hsnr') },
    { id: 1, title: '螺蛳粉', subTitle: '酸辣鲜爽，地道柳州风味...', image: $r('app.media.lsf') },
    { id: 2, title: '香酥烤鸡', subTitle: '外焦里嫩，香气四溢...', image: $r('app.media.kj') }
  ]

  private navList: NavItem[] = [
    { name: '首页', icon: $r('app.media.luosifen') },
    { name: '多样', icon: $r('app.media.kaoji') },
    { name: '探索', icon: $r('app.media.baozi') },
    { name: '休闲', icon: $r('app.media.beef') }
  ]

  // --- 核心逻辑：翻牌动画（性能优化版） ---
  private lastSwapTime: number = 0;
  private swapDebounceDelay: number = 300; // 防抖延迟时间

  swapCard(index: number) {
    const currentTime = Date.now();
    
    // 防抖机制：避免快速连续点击
    if (currentTime - this.lastSwapTime < this.swapDebounceDelay || this.flyingIndex !== -1 || this.isAnimating) {
      return;
    }
    
    this.lastSwapTime = currentTime;

    // 优化动画逻辑：合并动画，减少嵌套
    this.flyingIndex = index;
    this.cardOffsets[index] = 200; // 优化飞出距离
    this.isAnimating = true;

    animateTo({
      duration: 150, // 进一步优化动画时长
      curve: Curve.EaseOut, // 使用更轻量的曲线
      onFinish: () => {
        // 优化状态更新：使用原地更新避免数组重新分配
        const temp = this.cards[0];
        this.cards[0] = this.cards[index];
        this.cards[index] = temp;
        
        this.flyingIndex = -1;
        this.cardOffsets[index] = 0;
        this.cardOffsets[0] = 80; // 优化起始偏移

        // 简化飞入动画
        animateTo({ 
          duration: 120, // 优化动画时长
          curve: Curve.EaseInOut
        }, () => {
          this.cardOffsets[0] = 0;
          this.isAnimating = false;
        })
      }
    }, () => {
      // 动画执行期间的状态变化
    })
  }

  // --- 优化导航栏点击处理 ---
  handleNavClick(index: number) {
    const currentTime = Date.now();
    
    // 加强防抖：防止快速连续点击
    if (currentTime - this.lastNavClickTime < 200 || this.isAnimating) {
      return;
    }
    
    this.lastNavClickTime = currentTime;
    this.isAnimating = true;

    if (!this.isNavActive) {
      // 场景1：导航栏未展开 → 展开+切换页面
      animateTo({ duration: 180, curve: Curve.EaseOut }, () => {
        this.isNavActive = true;
        this.currentIndex = index;
        this.isAnimating = false;
      })
    } else {
      // 场景2：导航栏已展开 → 切换页面
      if (index === 0 && this.currentIndex !== 0) {
        // 首页按钮的特殊处理：先收起导航栏，再切换页面
        animateTo({ duration: 120 }, () => {
          this.isNavActive = false;
        })
        
        // 延迟切换页面，确保动画流畅
        setTimeout(() => {
          this.currentIndex = index;
          this.isAnimating = false;
        }, 80)
      } else {
        // 其他按钮：直接切换页面
        animateTo({ duration: 150 }, () => {
          this.currentIndex = index;
          this.isAnimating = false;
        })
      }
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Stack() {
        if (this.currentIndex === 0) {
          Column() {
            Image($r('app.media.caipukapian'))
              .width(350) // 固定宽度（可根据需求调整，如180、220）
              .height(130) // 固定高度（匹配图片比例）
              .objectFit(ImageFit.Contain) // 保持图片比例，完整显示在容器内
              .margin({ top: 30 }) // 保留原上下边距，和原文字位置一致


            Stack() {
              ForEach(this.cards, (item: CardData, index: number) => {
                if (index === 0) {
                  this.MainCard(item)
                } else {
                  // 通过增大 offX 和 offY 来让外露部分更多
                  // index 1: 中层，加大偏移
                  // index 2: 底层，进一步加大偏移
                  this.CardItem(
                    item,
                    index === 1 ? 0.92 : 0.85,
                    index === 1 ? 35 : 70,   // X偏移加大 (原 15/30)
                    index === 1 ? 30 : 60,   // Y偏移加大 (原 18/35)
                    index === 1 ? 6 : 12,
                    index === 1 ? 2 : 1,
                    index
                  )
                }
              }, (item: CardData, index: number) => item.id.toString() + index)
            }
            .width('100%')
            .height(480) // 增加高度以容纳更大的 Y 轴偏移
            .offset({ x: -20, y: -30 }) // 整体左移更多 (原 -15)，以平衡向右外露的视觉感
          }
          .width('100%')
          .height('100%')
          .backgroundImage($r('app.media.beijin2')) // 背景图片
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
          .backgroundImageSize(ImageSize.Cover)    // 铺满容器
          .backgroundImagePosition(Alignment.Center) // 居中
          .backgroundColor('#F7F7F7CC')            // 浅灰色半透明遮罩
        }
        else if (this.currentIndex === 1) {
          duoyan()
        }
        // 探索页面（currentIndex=2 → 对应xiuxiang组件）
        else if (this.currentIndex === 2) {
          tansuo()
        }
        // 休闲页面（currentIndex=3 → 对应duoyan组件）
        else if (this.currentIndex === 3) {
          xiuxiang()
        }
        // 记录单页面（currentIndex=4 → 对应jiludan组件）
        else if (this.currentIndex === 4) {
          jiludan()
        }
      }
      .width('100%')
      .height('100%')
      .onClick(() => {
        if (!this.isAnimating) {
          animateTo({ duration: 150 }, () => { this.isNavActive = false })
        }
      })

      this.BottomNavigationBar()
    }
    .width('100%')
    .height('100%')
  }

  @Builder MainCard(data: CardData) {
    Column() {
      Image(data.image)
        .width('100%').height(240).borderRadius({ topLeft: 20, topRight: 20 })
        .objectFit(ImageFit.Cover).backgroundColor('#F0F0F0')
      Column() {
        Text(data.title).fontSize(22).fontWeight(FontWeight.Bold).width('100%')
        Text(data.subTitle).fontSize(14).fontColor('#999').margin({ top: 8 })
      }.padding(15)
    }
    .width(280).height(350).backgroundColor(Color.White).borderRadius(20)
    .zIndex(this.flyingIndex === 0 ? 1 : 5)
    .offset({ x: this.cardOffsets[0] })
    .shadow({ radius: 30, color: '#20000000', offsetX: 5, offsetY: 15 })
  }

  @Builder CardItem(data: CardData, scaleNum: number, offX: number, offY: number, angle: number, zIndexNum: number, arrayIndex: number) {
    Column() {
      Image(data.image)
        .width('100%').height(240).borderRadius({ topLeft: 20, topRight: 20 })
        .objectFit(ImageFit.Cover).opacity(0.4)
    }
    .width(280).height(350).backgroundColor(Color.White).borderRadius(20)
    .scale({ x: scaleNum, y: scaleNum })
    .offset({ x: offX + this.cardOffsets[arrayIndex], y: offY })
    .rotate({ z: 1, angle: angle })
    .zIndex(zIndexNum)
    .shadow({ radius: 20, color: '#10FF0000', offsetX: 10, offsetY: 10 })
    .onClick(() => {
      this.swapCard(arrayIndex)
    })
  }

  // --- 极度简化的导航栏实现，解决卡顿问题 ---
  @Builder BottomNavigationBar() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 简化背景实现，移除复杂变换
      Column()
        .width(this.isNavActive ? 600 : '92%')
        .height(this.isNavActive ? 600 : 65)
        .borderRadius(this.isNavActive ? 300 : 32)
        .linearGradient({ angle: 180, colors: [['#FF9D6F', 0.0], ['#E53935', 1.0]] })
        .offset({ y: this.isNavActive ? 500 : -8 })
        .onClick(() => {
          if (!this.isNavActive && !this.isAnimating) {
            this.isAnimating = true;
            animateTo({ duration: 160, curve: Curve.EaseOut }, () => { 
              this.isNavActive = true;
              this.isAnimating = false;
            })
          }
        })

      // 简化导航按钮布局
      Row() {
        ForEach(this.navList, (item: NavItem, index: number) => {
          Column() {
            Stack() {
              if (this.isNavActive && this.currentIndex === index) {
                Circle().width(52).height(52).fill('#97ec4545')
              }
              Image(item.icon).width(36).height(36).fillColor(Color.White)
            }.width(52).height(52)
            Text(item.name).fontSize(12).fontColor(Color.White).margin({ top: 1 })
          }
          .layoutWeight(1)
          .margin({
            right: (this.isNavActive && index === 1) ? 35 : 0,
            left: (this.isNavActive && index === 2) ? 35 : 0
          })
          .offset({ y: this.isNavActive ? (index === 0 || index === 3 ? 12 : 4) : 0 })
          .onClick(() => {
            this.handleNavClick(index);
          })
        })
      }
      .width(this.isNavActive ? '100%' : '92%')
      .height(this.isNavActive ? 90 : 70)
      .padding({ left: 6, right: 6, bottom: this.isNavActive ? 10 : 0 })
      .offset({ y: this.isNavActive ? 0 : -6 })

      // 简化记录单按钮实现
      if (this.isNavActive) {
        Column() {
          Column() {
            Image($r('app.media.foreground')).width(36).height(36)
            Text('记录单').fontSize(9).fontColor('#E53935').fontWeight(FontWeight.Bold)
          }
          .width(70).height(70).backgroundColor(Color.White).borderRadius(35)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            if (!this.isAnimating) {
              this.isAnimating = true;
              animateTo({ duration: 150 }, () => {
                this.currentIndex = 4;
                this.isAnimating = false;
              })
            }
          })
        }
        .offset({ y: -40 })
      }
    }
    .zIndex(10)
    .width('100%')
    .height(this.isNavActive ? 130 : 80)
  }
}