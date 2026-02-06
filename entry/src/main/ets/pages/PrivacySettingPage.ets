import { CommonNavBar } from '../components/CommonNavBar'
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

@Entry
@Component
struct PrivacySettingPage {
  @State isDataCollection: boolean = true
  @State isPushNotification: boolean = true
  @State isAnalytics: boolean = false
  @State isLocationService: boolean = false

  build() {
    Column() {
      CommonNavBar({
        options: {
          showBack: true,
          onLeftClick: () =>{
            router.replaceUrl({ url: 'pages/SettingsPage' })// 右侧按钮点击事件（可选）
          },
          title: '隐私设置',
        }
      });

      Scroll() {
        Column() {
          // 隐私设置标题
          Column() {
            Text('隐私偏好设置')
              .fontSize(20)
              .fontColor('#000000')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })

            Text('管理您的隐私偏好设置')
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .padding(20)
          .margin({ bottom: 20 })

          // 设置项列表
          Column() {
            // 数据收集
            this.renderSettingItem(
              '数据收集',
              '允许应用收集使用数据以改进体验',
              this.isDataCollection,
              (value) => {
                this.isDataCollection = value
                promptAction.showToast({ message: value ? '已开启数据收集' : '已关闭数据收集' })
              }
            )

            // 推送通知
            this.renderSettingItem(
              '推送通知',
              '接收应用通知和提醒',
              this.isPushNotification,
              (value) => {
                this.isPushNotification = value
                promptAction.showToast({ message: value ? '已开启推送通知' : '已关闭推送通知' })
              }
            )

            // 分析统计
            this.renderSettingItem(
              '分析统计',
              '允许应用分析使用情况',
              this.isAnalytics,
              (value) => {
                this.isAnalytics = value
                promptAction.showToast({ message: value ? '已开启分析统计' : '已关闭分析统计' })
              }
            )

            // 位置服务
            this.renderSettingItem(
              '位置服务',
              '记录消费地点信息',
              this.isLocationService,
              (value) => {
                this.isLocationService = value
                promptAction.showToast({ message: value ? '已开启位置服务' : '已关闭位置服务' })
              }
            )

            // 分隔线
            Divider()
              .strokeWidth(1)
              .color('#E0E0E0')
              .margin({ top: 20, bottom: 20 })

            // 隐私政策按钮
            Row() {
              Text('隐私政策')
                .fontSize(16)
                .fontColor('#333333')
                .flexGrow(1)

              Image($r('app.media.icon_privacy'))
                .width(20)
                .height(20)
                .margin({ left: 10 })
            }
            .width('100%')
            .padding({ top: 15, bottom: 15 })
            .onClick(() => {
              promptAction.showToast({ message: '查看隐私政策' })
              // 可以跳转到隐私政策页面
               router.replaceUrl({ url: 'pages/PrivacyPolicyPage' })
            })

            // 用户协议按钮
            Row() {
              Text('用户协议')
                .fontSize(16)
                .fontColor('#333333')
                .flexGrow(1)

              Image($r('app.media.User_Avatar'))
                .width(20)
                .height(20)
                .margin({ left: 10 })
            }
            .width('100%')
            .padding({ top: 15, bottom: 15 })
            .onClick(() => {
              promptAction.showToast({ message: '查看用户协议' })
              // 可以跳转到用户协议页面
               router.replaceUrl({ url: 'pages/UserAgreementPage' })
            })

            // 清除数据按钮
            Button('清除所有数据', { type: ButtonType.Normal })
              .width('100%')
              .height(50)
              .fontSize(16)
              .fontColor('#FF6B35')
              .backgroundColor(Color.Transparent)
              .borderColor('#FF6B35')
              .borderWidth(1)
              .borderRadius(8)
              .margin({ top: 20 })
              .onClick(() => {
                this.showClearDataDialog()
              })
          }
          .width('90%')
          .padding({ left: 20, right: 20, top: 20, bottom: 20 })
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // 渲染设置项
  @Builder
  renderSettingItem(title: string, description: string, isChecked: boolean, onToggle: (value: boolean) => void) {
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

      Toggle({ type: ToggleType.Switch, isOn: isChecked })
        .onChange((value) => {
          onToggle(value)
        })
    }
    .width('100%')
    .padding({ top: 15, bottom: 15 })
  }

  // 显示清除数据对话框
  showClearDataDialog() {
    promptAction.showDialog({
      title: '清除数据',
      message: '确定要清除所有本地数据吗？此操作不可撤销。',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '清除', color: '#FF6B35' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        // 用户点击了清除
        this.clearAllData()
      }
    })
  }

  // 清除所有数据
  async clearAllData() {
    try {
      // 这里可以添加清除本地存储、数据库等逻辑
      promptAction.showToast({ message: '正在清除数据...', duration: 1000 })

      // 模拟清除过程
      setTimeout(() => {
        promptAction.showToast({ message: '数据清除完成', duration: 2000 })

        // 重置设置项
        this.isDataCollection = true
        this.isPushNotification = true
        this.isAnalytics = false
        this.isLocationService = false
      }, 1000)
    } catch (error) {
      console.error('清除数据失败:', error)
      promptAction.showToast({ message: '清除失败，请重试' })
    }
  }
}