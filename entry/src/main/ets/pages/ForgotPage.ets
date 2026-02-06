import router from '@ohos.router';
import { CommonNavBar } from '../components/CommonNavBar'


@Entry
@Component
struct ForgotPage {
  build() {
    Column() {
      CommonNavBar({

        options: {
          showBack: true,
          title: '忘记密码',
          onLeftClick: () =>{
            router.replaceUrl({ url: 'pages/LoginPage' })// 右侧按钮点击事件（可选）
          }}
      });
      // 主要内容区域
      Column() {

        // 应用名称
        Text('忘记密码页面')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .margin({ bottom: 10 })
      }
      .height('40%')
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('95%')
  }
}