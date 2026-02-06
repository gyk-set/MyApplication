import { CommonNavBar } from '../components/CommonNavBar'
import promptAction from '@ohos.promptAction';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct AboutPage {
  @State appVersion: string = '1.0.0'
  @State developerEmail: string = '3032964284@qq.com'

  build() {
    Column() {
      CommonNavBar({
        options: {
          showBack: true,
          onLeftClick: () =>{
            router.replaceUrl({ url: 'pages/SettingsPage' })// 右侧按钮点击事件（可选）
          },
          title: '关于我们',
        }
      });

      Scroll() {
        Column() {
          // 应用Logo和名称
          Column() {
            Image($r('app.media.logo1')) // 使用你的Logo图片
              .width(120)
              .height(120)
              .borderRadius(60)
              .margin({ bottom: 20 })

            Text('轻记记账')
              .fontSize(28)
              .fontColor('#000000')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 5 })

            Text(`版本 ${this.appVersion}`)
              .fontSize(16)
              .fontColor('#666666')
          }
          .width('100%')
          .padding(30)
          .backgroundColor('#FFFFFF')
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: 20 })

          // 应用简介
          Column() {
            Text('应用简介')
              .fontSize(18)
              .fontColor('#000000')
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 15 })

            Text('轻记记账是一款简单实用的记账应用，帮助您轻松管理个人财务，记录每一笔收支，分析消费习惯。')
              .fontSize(14)
              .fontColor('#666666')
              .lineHeight(22)
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 20 })

          // 功能特色
          Column() {
            Text('功能特色')
              .fontSize(18)
              .fontColor('#000000')
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 15 })

            Column({ space: 12 }) {
              this.renderFeature('💰 智能记账', '快速记录收支，自动分类统计')
              this.renderFeature('📊 数据统计', '可视化图表，清晰展示消费趋势')
              this.renderFeature('🔒 数据安全', '本地加密存储，保护隐私安全')
              this.renderFeature('📱 多端同步', '支持多设备数据同步')
            }
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 20 })

          // 联系方式
          Column() {
            Text('联系方式')
              .fontSize(18)
              .fontColor('#000000')
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 15 })

            Column({ space: 12 }) {
              this.renderContactItem('邮箱', this.developerEmail, () => {
                promptAction.showToast({ message: '邮箱: ' + this.developerEmail })
              })

              this.renderContactItem('官网', 'www.qingji.com', () => {
                promptAction.showToast({ message: '官网: www.qingji.com' })
              })

              this.renderContactItem('反馈', '应用内反馈', () => {
                promptAction.showToast({ message: '感谢您的反馈！' })
              })
            }
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 20 })

          // 版权信息
          Column() {
            Text('© 2024 轻记记账')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ bottom: 5 })

            Text('All Rights Reserved')
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('100%')
          .padding(20)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ bottom: 30 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // 渲染功能特色项
  @Builder
  renderFeature(title: string, description: string) {
    Row() {
      Column({ space: 2 }) {
        Text(title)
          .fontSize(16)
          .fontColor('#333333')

        Text(description)
          .fontSize(13)
          .fontColor('#666666')
      }
      .flexGrow(1)
    }
    .width('100%')
  }

  // 渲染联系方式项
  @Builder
  renderContactItem(label: string, value: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#333333')
        .width(60)

      Text(value)
        .fontSize(15)
        .fontColor('#007DFF')
        .flexGrow(1)
        .onClick(onClick)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }
}