import { CommonNavBar } from '../components/CommonNavBar'
import { router } from '@kit.ArkUI';

@Entry
@Component
struct UserAgreementPage {
  build() {
    Column() {
      CommonNavBar({
        options: {
          showBack: true,
          onLeftClick: () =>{
            router.replaceUrl({ url: 'pages/PrivacySettingPage' })// 右侧按钮点击事件（可选）
          },
          title: '用户协议',
        }
      });

      Scroll() {
        Column() {
          // 标题
          Text('轻记用户协议')
            .fontSize(24)
            .fontColor('#000000')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 20 })
            .width('90%')
            .textAlign(TextAlign.Center)

          // 协议内容
          Column({ space: 25 }) {
            this.renderSection('一、服务条款的接受', [
              '欢迎使用轻记记账应用（以下简称"本应用"）。在使用本应用之前，请您仔细阅读本用户协议（以下简称"本协议"）。当您点击"我同意"按钮或开始使用本应用时，即表示您已充分理解并同意接受本协议的全部内容。'
            ])

            this.renderSection('二、服务说明', [
              '1. 本应用是一款基于HarmonyOS平台的智能记账应用，旨在帮助用户便捷地记录和管理个人财务信息。',
              '2. 本应用采用鸿蒙加密存储技术，确保您的数据安全。',
              '3. 本应用使用端侧AI处理，所有数据仅在本地处理，不会上传至服务器。'
            ])

            this.renderSection('三、用户行为规范', [
              '1. 您应当使用真实、准确的信息进行记账。',
              '2. 您不得利用本应用从事任何违法违规活动。',
              '3. 您应当妥善保管账户信息，对账户下的所有行为负责。'
            ])

            this.renderSection('四、知识产权', [
              '本应用的所有知识产权归开发者所有，未经许可不得复制、传播或用于其他商业目的。'
            ])

            this.renderSection('五、免责声明', [
              '1. 本应用不对因使用或无法使用本服务而产生的任何直接、间接、偶然、特殊或后果性损害承担责任。',
              '2. 本应用不保证服务的及时性、安全性和准确性。'
            ])

            this.renderSection('六、协议修改', [
              '我们有权随时修改本协议，修改后的协议将在本应用内公布。如您不同意修改后的协议，请停止使用本应用。'
            ])

            this.renderSection('七、联系我们', [
              '如有任何疑问，请通过应用内反馈功能联系我们。'
            ])

            Text('感谢您使用轻记！')
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