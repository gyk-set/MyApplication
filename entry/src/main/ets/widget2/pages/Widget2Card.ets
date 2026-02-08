@Entry
@Component
struct Widget2Card {
  readonly title: string = '轻记AI智能助手'
  readonly subTitle: string = '你的记账好帮手'
  readonly actionType: string = 'router'
  readonly abilityName: string = 'EntryAbility'
  readonly message: string = 'to_aiChatPage'

  /**
   * 卡片尺寸类型：
   * 'small' | 'medium' | 'large'
   * 实际项目中可以从 params 里取
   */
  readonly cardSize: string = 'medium'

  /**
   * 根据卡片大小计算字号
   */
  private getTitleFontSize(): string {
    if (this.cardSize === 'small') {
      return '6%'
    }
    if (this.cardSize === 'large') {
      return '10%'
    }
    return '8%' // medium
  }

  private getSubTitleFontSize(): string {
    if (this.cardSize === 'small') {
      return '3%'
    }
    if (this.cardSize === 'large') {
      return '5%'
    }
    return '4%' // medium
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {

      // 渐变背景（图片方案，Form 支持）
      Image($r('app.media.card_bg_blue'))
        .width('100%')
        .height('100%')

      Column({ space: '4%' }) {

        // 主标题
        Text(this.title)
          .fontSize(this.getTitleFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 副标题（≈ 主标题一半）
        Text(this.subTitle)
          .fontSize(this.getSubTitleFontSize())
          .fontColor(Color.White)
          .opacity(0.85)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('90%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
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
