import router from '@ohos.router';  // ExplorePage.ets - 独立的探索页面组件
@Component
export struct duoyan { // 导出组件，供首页导入使用
  build() {
    Column() {
      Text("多样")
        .fontSize(20)
        .fontWeight(500)
        .margin({
          top: 50,
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}