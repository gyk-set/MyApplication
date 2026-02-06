import router from '@ohos.router';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Column() {
      // 顶部Logo区域
      Column() {
        // Logo图标
        Image($r('app.media.logo1'))  // 替换为你的Logo路径
          .width(120)
          .height(120)
          .margin({ bottom: 20 })
          .borderRadius(60) // 如果是圆形Logo

        // 可选标语
        Text('让记账更简单')
          .fontSize(16)
          .fontColor('#666666')
      }
      .height('30%')
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 主要内容区域
      Column() {
        // 应用名称
        Text('智能记账助手')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .margin({ bottom: 10 })

        // 价值主张
        Text('感受智能记账体验')
          .fontSize(18)
          .fontColor('#666666')
          .margin({ bottom: 80 })

        // 开始体验按钮
        Button('开始体验', { type: ButtonType.Capsule })
          .width(200)
          .height(50)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .onClick(() => {
            // 跳转到权限协议引导页
            router.replaceUrl({
              url: 'pages/LoginPage'
            });
          })
      }
      .height('40%')
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 底部信息区域
      Column() {
        Text('版本 1.0.0')
          .fontSize(12)
          .fontColor('#AAAAAA')
          .margin({ bottom: 5 })

        Text('© 2025 智能记账助手')
          .fontSize(12)
          .fontColor('#AAAAAA')
      }
      .height('30%')
      .width('100%')
      .justifyContent(FlexAlign.End)
      .alignItems(HorizontalAlign.Center)
      .padding({ bottom: 30 })
    }
    .width('100%')
    .height('100%')
  }
}