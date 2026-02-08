@Entry
@Component
struct Widget1Card {
  /*
   * 主标题：快速记账
   */
  readonly title: string = '快速记账'
  /*
   * 副标题：点击进入开始记账
   */
  readonly subTitle: string = '点击进入开始记账'
  /*
   * 跳转类型
   */
  readonly actionType: string = 'router'
  /*
   * 入口Ability名称
   */
  readonly abilityName: string = 'EntryAbility'
  /*
   * 跳转传递参数
   */
  readonly message: string = 'to_recordPage'
  /*
   * 宽高百分比
   */
  readonly fullWidthPercent: string = '100%'
  readonly fullHeightPercent: string = '100%'

  build() {
    // Stack堆叠布局：背景图 + 文字层叠
    Stack({ alignContent: Alignment.Center }) {
      // 第一层：背景图
      Image($r('app.media.card_bg_jizhang'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill) // 关键：强制填满卡片，无留白
        .opacity(1)
        .borderRadius(16) // 和外层卡片圆角一致，避免背景图边角溢出

      // 第二层：文字内容
      Column({ space: 6 }) {
        // 主标题
        Text(this.title)
          .fontSize(22) // 主标题更突出
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .maxLines(1)

        // 副标题
        Text(this.subTitle)
          .fontSize(15) // ≈ 主标题 70%
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .maxLines(1)
      }
      .width('90%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    // 外层容器
    .width(this.fullWidthPercent)
    .height(this.fullHeightPercent)
    .backgroundColor($r('sys.color.comp_background_primary') || '#FFFFFF')
    .borderRadius(16)
    .padding(0) // 核心：去掉内边距，背景图完全贴边
    .margin(0) // 清除外边距，避免卡片整体偏移
    .onClick(() => {
      postCardAction(this, {
        action: this.actionType,
        abilityName: this.abilityName,
        // 传递参数，告诉主应用要打开 MainPage
        params: {
          info: this.message
        }
      });
    })
  }
}