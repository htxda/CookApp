import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 1. 定义数据接口
interface NoteItem {
  id: number;
  title: string;
  content: string;
  color: string;
  lastUpdate: string;
  isFavorite: boolean;
}

// LazyForEach数据源实现
class NotesDataSource {
  private notes: Array<NoteItem>;

  constructor(notes: Array<NoteItem>) {
    this.notes = notes;
  }

  totalCount(): number {
    return this.notes.length;
  }

  getData(index: number): NoteItem {
    return this.notes[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    // 数据变化监听
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    // 取消监听
  }
}

@Component
export struct jiludan {
  @State isEditing: boolean = false;
  @State showFavorites: boolean = false;
  @State selectedNote: NoteItem | null = null;
  @State notes: Array<NoteItem> = [];

  private pref: preferences.Preferences | null = null;
  private prefName: string = 'MyNoteStoreV3';
  private saveTimer: number | null = null;
  private saveDebounceDelay: number = 500; // 防抖延迟500ms

  // --- 渲染入口：在这里实现一体化背景 ---
  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 列表主界面容器
      Column() {
        this.NotesHeader()

        Scroll() {
          if (this.notes.length > 0) {
            // 性能优化：使用ForEach，但优化渲染逻辑
            Grid() {
              ForEach(this.notes, (item: NoteItem, index: number) => {
                GridItem() {
                  this.NoteCard(item)
                }
                .aspectRatio(0.8) // 固定宽高比
              }, (item: NoteItem) => item.id.toString())
            }
            .columnsTemplate('1fr 1fr') // 两列布局
            .rowsGap(15)
            .columnsGap(15)
            .padding({ left: 15, right: 15, top: 10, bottom: 120 })
          } else {
            Column() {
              LoadingProgress().width(50).color(Color.White).margin({ top: 100 })
              Text("正在同步数据...").fontColor(Color.Gray).margin({ top: 10 })
            }.width('100%')
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      // --- 【关键修改点1】：将背景图设置在最外层 Column 上，实现全屏一体化 ---
      .backgroundImage($r('app.media.beijin3'))
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
      .backgroundImageSize(ImageSize.Cover)
      .visibility((this.isEditing || this.showFavorites) ? Visibility.None : Visibility.Visible)

      // 2. 详情编辑页
      if (this.isEditing && this.selectedNote) {
        this .EditPageBuilder()
      }

      // 3. 收藏展示页
      if (this.showFavorites) {
        this.FavoritePageBuilder()
      }
    }
    .width('100%')
    .height('100%')
  }

  // --- 局部组件：移除局部背景设置 ---
  @Builder NotesHeader() {
    Column() {
      Row() {
        Image($r('app.media.jiludan'))
          .height(80) // 根据你原文字大小调整高度，通常 38-45 比较合适
          .objectFit(ImageFit.Contain) // 确保图片比例缩放不失真
        Blank()
        Row({ space: 10 }) {
          Button() { Text("❤️").fontSize(20) }.width(42).height(42).backgroundColor('#333').borderRadius(21)
          .onClick(() => { animateTo({ duration: 300 }, () => { this.showFavorites = true; }) })
          Button() { Text("+").fontSize(24).fontColor(Color.White) }.width(42).height(42).backgroundColor('#444').borderRadius(21)
          .onClick(() => this.addNewNote())
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 40, bottom: 10 })
    }
    // --- 【关键修改点2】：这里不再设置任何背景图或背景色，保持透明以透出底层全屏背景 ---
    .width('100%')
    .backgroundColor(Color.Transparent)
  }

  // --- 收藏界面：也应用同样的逻辑 ---
  @Builder FavoritePageBuilder() {
    Column() {
      Row() {
        Button() { Text("< 返回").fontSize(20).fontColor(Color.White) }
        .backgroundColor('#333').padding(10).borderRadius(20)
        .onClick(() => { animateTo({ duration: 300 }, () => { this.showFavorites = false; }) })
        Text("收藏内容").fontSize(24).fontWeight(FontWeight.Bold).fontColor(Color.White).margin({ left: 15 })
      }.width('100%').padding({ left: 20, top: 40, bottom: 20 })

      Scroll() {
        // 优化收藏页面布局
        Grid() {
          ForEach(this.notes.filter(n => n.isFavorite), (item: NoteItem, index: number) => {
            GridItem() {
              this.NoteCard(item)
            }
            .aspectRatio(0.8)
          }, (item: NoteItem) => "fav" + item.id.toString())
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(15)
        .columnsGap(15)
        .padding(15)
      }.layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    // --- 【关键修改点3】：收藏页也应用全屏一体背景 ---
    .backgroundImage($r('app.media.beijin3'))
    .backgroundImageSize(ImageSize.Cover)
    .zIndex(110)
  }

  // --- 其余逻辑（存储、卡片等）保持不变 ---

  aboutToAppear() { this.initPreferences(); }

  getCurrentTime(): string {
    const now = new Date();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    return `${month}/${day} ${hours}:${minutes}`;
  }

  async initPreferences() {
    try {
      let context = getContext(this) as common.UIAbilityContext;
      this.pref = await preferences.getPreferences(context, this.prefName);
      await this.loadFromLocal();
    } catch (err) { console.error("Preferences初始化失败"); }
  }

  async loadFromLocal() {
    if (!this.pref) return;
    try {
      let res = await this.pref.get('notes_data', '[]');
      let savedData = JSON.parse(res as string) as Array<NoteItem>;
      animateTo({ duration: 300 }, () => {
        this.notes = savedData.length > 0 ? savedData : [{
          id: Date.now(),
          title: '欢迎使用',
          content: '点击右上角 + 开始记录吧！',
          color: '#F9F5E3',
          lastUpdate: this.getCurrentTime(),
          isFavorite: false
        }];
      });
    } catch (e) { console.error("读取数据失败"); }
  }

  async saveToLocal() {
    if (!this.pref) return;
    
    // 性能优化：使用setTimeout避免阻塞UI线程
    setTimeout(async () => {
      try {
        await this.pref!.put('notes_data', JSON.stringify(this.notes));
        await this.pref!.flush();
      } catch (error) {
        console.error("保存数据失败:", error);
      }
    }, 0);
  }

  // 防抖保存方法
  private debounceSave() {
    if (this.saveTimer) {
      clearTimeout(this.saveTimer);
    }
    this.saveTimer = setTimeout(() => {
      this.saveToLocal();
      this.saveTimer = null;
    }, this.saveDebounceDelay);
  }

  addNewNote() {
    const colors = ['#FF8D5D', '#FFD351', '#F9F5E3', '#B2DFDB'];
    const randomColor = colors[Math.floor(Math.random() * colors.length)];
    const newNote: NoteItem = {
      id: Date.now(), title: '', content: '', color: randomColor,
      lastUpdate: this.getCurrentTime(), isFavorite: false
    };
    this.notes.unshift(newNote);
    this.selectedNote = newNote;
    this.saveToLocal();
    animateTo({ duration: 300 }, () => { this.isEditing = true; });
  }

  @Builder EditPageBuilder() {
    Column() {
      Row() {
        Button() { Text("< 返回").fontSize(18).fontColor(Color.Black) }
        .backgroundColor('#20000000').padding({ left: 15, right: 15, top: 8, bottom: 8 }).borderRadius(20)
        .onClick(() => { this.saveToLocal(); animateTo({ duration: 300 }, () => { this.isEditing = false; }); })
        Blank()
        Button() { Text("保存").fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White) }
        .padding({ left: 25, right: 25, top: 10, bottom: 10 })
        .backgroundColor(Color.Black).borderRadius(25).shadow({ radius: 10, color: '#30000000', offsetY: 4 })
        .onClick(() => {
          if (this.selectedNote) {
            this.selectedNote.lastUpdate = this.getCurrentTime();
            this.saveToLocal().then(() => { animateTo({ duration: 300 }, () => { this.isEditing = false; }); });
          }
        })
      }.width('100%').padding({ left: 20, right: 20, top: 40, bottom: 10 })

      Column() {
        TextInput({ text: this.selectedNote?.title, placeholder: "标题" })
          .fontSize(32).fontWeight(FontWeight.Bold).backgroundColor(Color.Transparent)
          .margin({ top: 20, bottom: 10 })
          .onChange((value: string) => {
            if (this.selectedNote) {
              this.selectedNote.title = value;
              // 性能优化：减少状态更新频率，使用防抖
              this.debounceSave();
            }
          })
        TextArea({ text: this.selectedNote?.content, placeholder: "写点什么..." })
          .fontSize(18).backgroundColor(Color.Transparent).layoutWeight(1)
          .onChange((value: string) => {
            if (this.selectedNote) {
              this.selectedNote.content = value;
              this.selectedNote.lastUpdate = this.getCurrentTime();
              // 性能优化：使用防抖保存
              this.debounceSave();
            }
          })
      }.padding({ left: 20, right: 20 }).layoutWeight(1)
    }
    .width('100%').height('100%')
    .backgroundColor(this.selectedNote?.color || '#F9F5E3')
    .zIndex(100)
  }

  @Builder NoteCard(item: NoteItem) {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Rect().width(30).height(3).radius(2).fill(Color.Black).opacity(0.1).margin({ top: 10, bottom: 10 })
        Row() {
          Text(item.title || '无标题记录').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).maxLines(1)
          if (item.isFavorite) Text("❤️").fontSize(14)
        }
        Text(item.content || '还没写任何内容...').fontSize(14).fontColor('#444').margin({ top: 10 }).maxLines(3).lineHeight(20)
        Blank()
        Text(item.lastUpdate).fontSize(10).fontColor('#888').width('100%').margin({ bottom: 5 })
      }
      .width('100%').height('100%').padding(15)
      .onClick(() => { this.selectedNote = item; animateTo({ duration: 300 }, () => { this.isEditing = true; }); })

      Button() { Text("...").fontColor('#333').fontSize(20).fontWeight(FontWeight.Bold) }
      .width(40).height(40).backgroundColor(Color.Transparent).margin({ right: 5, bottom: 5 })
      .bindMenu([
        { value: item.isFavorite ? '移除收藏' : '加入收藏', action: () => { item.isFavorite = !item.isFavorite; this.notes = [...this.notes]; this.saveToLocal(); }},
        { value: '删除', action: () => { this.notes = this.notes.filter(n => n.id !== item.id); this.saveToLocal(); }}
      ])
    }
    .width('48%').height(200).backgroundColor(item.color).borderRadius(25).margin({ bottom: 15 })
  }
}