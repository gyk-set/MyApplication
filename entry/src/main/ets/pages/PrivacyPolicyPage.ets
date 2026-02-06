import { CommonNavBar } from '../components/CommonNavBar'
import { router } from '@kit.ArkUI';

@Entry
@Component
struct PrivacyAgreementPage {
  build() {
    Column() {
      CommonNavBar({
        options: {
          showBack: true,
          onLeftClick: () =>{
            router.replaceUrl({ url: 'pages/PrivacySettingPage' })// 右侧按钮点击事件（可选）
          },
          title: '隐私协议',
        }
      });

      Scroll() {
        Column() {
          // 标题
          Text('轻记隐私协议')
            .fontSize(24)
            .fontColor('#000000')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 20 })
            .width('90%')
            .textAlign(TextAlign.Center)

          // 协议内容
          Column({ space: 25 }) {
            this.renderSection('一、信息收集', [
              '1. 记账数据：您主动输入的收入、支出等记账信息。',
              '2. 设备信息：为保障账户安全，我们可能收集设备标识信息。',
              '3. 位置信息：仅在您授权的情况下，用于记录消费地点。'
            ])

            this.renderSection('二、信息使用', [
              '1. 我们使用您的记账数据为您提供记账、统计、分析等服务。',
              '2. 我们采用鸿蒙加密存储技术，确保您的数据安全。',
              '3. 我们使用端侧AI处理，所有数据仅在本地处理，不会上传至服务器。'
            ])

            this.renderSection('三、信息存储', [
              '1. 您的所有数据均存储在您的设备本地，采用加密存储。',
              '2. 我们不会将您的数据上传至任何服务器。',
              '3. 您可以通过应用内的备份功能，将数据备份到您指定的位置。'
            ])

            this.renderSection('四、信息保护', [
              '1. 我们采用业界领先的加密技术保护您的数据安全。',
              '2. 我们不会向任何第三方分享、出售或出租您的个人信息。',
              '3. 除非法律法规要求，我们不会向任何第三方披露您的信息。'
            ])

            this.renderSection('五、您的权利', [
              '1. 您有权随时查看、修改、删除您的记账数据。',
              '2. 您有权拒绝某些权限的授权，但这可能影响部分功能的使用。',
              '3. 您有权随时停止使用本应用并删除数据。'
            ])

            this.renderSection('六、儿童隐私保护', [
              '如果您是14周岁以下的儿童，请在监护人的陪同下阅读本协议，并在监护人的同意和指导下使用本应用。'
            ])

            this.renderSection('七、协议更新', [
              '我们可能会不定期更新本隐私协议，更新后的协议将在本应用内公布。'
            ])

            this.renderSection('八、联系我们', [
              '如有任何关于隐私的问题，请通过应用内反馈功能联系我们。'
            ])

            Text('感谢您对轻记的信任！')
              .fontSize(16)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
              .margin({ top: 10 })
          }
          .width('90%')
          .padding({ left: 20, right: 20, top: 20, bottom: 40 })
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
        }
        .width('100%')
        .padding({ top: 20, bottom: 40 })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // 渲染协议章节
  @Builder
  renderSection(title: string, contents: string[]) {
    Column({ space: 10 }) {
      Text(title)
        .fontSize(18)
        .fontColor('#000000')
        .fontWeight(FontWeight.Medium)
        .width('100%')

      ForEach(contents, (content: string, index: number) => {
        Text(content)
          .fontSize(14)
          .fontColor('#666666')
          .lineHeight(22)
          .width('100%')
      })
    }
    .width('100%')
  }
}