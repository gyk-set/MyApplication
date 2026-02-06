// 导入页面路由模块
import router from '@ohos.router';
import { BusinessError } from '@ohos.base';
import { LoginButton } from "../models/Record";
import { login, register } from "../DatabaseUtil"; // 导入登录注册服务
// 弹窗
import promptAction from '@ohos.promptAction';
import { encryptPwd } from '../../ets/DatabaseUtil'; // 导入加密函数

// 导入Preferences
import dataPreferences from '@ohos.data.preferences';
// 如果需要上下文
import { Context } from '@ohos.abilityAccessCtrl';

// 协议类型枚举
enum AgreementType {
  USER_AGREEMENT = 'user',
  PRIVACY_AGREEMENT = 'privacy'
}

@Entry
@Component
struct LoginPage {
  @State message: string = '欢迎登录'
  @State user: string = '' // 用户名
  @State password: string = '' // 密码
  @State isLoading: boolean = false // 加载状态
  @State agreementsChecked: boolean = false // 协议勾选状态
  @State showAgreementDialog: boolean = false // 控制协议对话框显示
  @State dialogContent: string = '' // 对话框内容
  @State dialogTitle: string = '' // 对话框标题
  // 重构数据：包含按钮文本、图片路径、标识
  private otherData: Array<LoginButton> = [
    { text: "微信", icon: "wechat", type: "wechat" },
    { text: "QQ", icon: "qq", type: "qq" },
    { text: "手机号", icon: "other", type: "phone" }
  ]

  // 页面生命周期 - 只做页面相关初始化
  aboutToAppear() {
    console.log('登录页面加载完成');
  }

  aboutToDisappear() {
    console.log('登录页面即将离开');
  }

  // 显示协议对话框
  showAgreement(type: AgreementType) {
    switch (type) {
      case AgreementType.USER_AGREEMENT:
        this.dialogTitle = '轻记用户协议';
        this.dialogContent = this.getUserAgreementContent();
        break;
      case AgreementType.PRIVACY_AGREEMENT:
        this.dialogTitle = '轻记隐私协议';
        this.dialogContent = this.getPrivacyAgreementContent();
        break;
    }
    this.showAgreementDialog = true;
  }

  // 登录函数
  // 登录函数（简化版）
  private async handleLogin(): Promise<void> {
    if (this.isLoading) {
      return;
    }

    if (!this.agreementsChecked) {
      promptAction.showToast({ message: '请先同意《用户协议》和《隐私协议》' });
      return;
    }

    if (!this.user.trim() || !this.password.trim()) {
      promptAction.showToast({ message: '请输入用户名和密码' });
      return;
    }

    this.isLoading = true;
    try {
      const success = await login(this.user, this.password);
      if (success) {
        // === 核心：保存登录状态 ===
        AppStorage.setOrCreate('currentUsername', this.user);
        AppStorage.setOrCreate('isLoggedIn', true);
        // === 结束 ===

        promptAction.showToast({ message: '登录成功！' });

        // 跳转到账单页面
        router.replaceUrl({
          url: 'pages/MainPage',
          params: {
            username: this.user,
            timestamp: new Date().getTime()
          }
        }).catch((error: Error) => {
          promptAction.showToast({ message: '跳转失败：' + error.message })
        });
      } else {
        promptAction.showToast({ message: '用户名或密码错误' });
      }
    } catch (error) {
      console.error('登录失败:', error);
      promptAction.showToast({ message: '登录失败，请检查网络或重试' });
    } finally {
      this.isLoading = false;
    }
  }

  // 注册函数
  // 注册函数（简化版）
  private async handleRegister(): Promise<void> {
    if (this.isLoading) {
      return;
    }

    if (!this.agreementsChecked) {
      promptAction.showToast({ message: '请先同意《用户协议》和《隐私协议》' });
      return;
    }

    if (!this.user.trim() || !this.password.trim()) {
      promptAction.showToast({ message: '用户名和密码不能为空' });
      return;
    }

    if (this.user.length < 3 || this.user.length > 20) {
      promptAction.showToast({ message: '用户名长度需在3-20位之间' });
      return;
    }

    if (this.password.length < 6) {
      promptAction.showToast({ message: '密码长度需至少6位' });
      return;
    }

    this.isLoading = true;
    try {
      const success = await register(this.user, this.password);
      if (success) {
        // === 核心：保存登录状态 ===
        AppStorage.setOrCreate('currentUsername', this.user);
        AppStorage.setOrCreate('isLoggedIn', true);
        // === 结束 ===

        promptAction.showToast({ message: '注册成功！' });
        this.password = '';
      } else {
        promptAction.showToast({ message: '用户名已存在' });
      }
    } catch (error) {
      console.error('注册失败:', error);
      promptAction.showToast({ message: '注册失败，请重试' });
    } finally {
      this.isLoading = false;
    }
  }

  // 用户协议内容
  getUserAgreementContent(): string {
    return `欢迎使用轻记！

一、服务条款的接受
欢迎使用轻记记账应用（以下简称"本应用"）。在使用本应用之前，请您仔细阅读本用户协议（以下简称"本协议"）。当您点击"我同意"按钮或开始使用本应用时，即表示您已充分理解并同意接受本协议的全部内容。

二、服务说明
1. 本应用是一款基于HarmonyOS平台的智能记账应用，旨在帮助用户便捷地记录和管理个人财务信息。
2. 本应用采用鸿蒙加密存储技术，确保您的数据安全。
3. 本应用使用端侧AI处理，所有数据仅在本地处理，不会上传至服务器。

三、用户行为规范
1. 您应当使用真实、准确的信息进行记账。
2. 您不得利用本应用从事任何违法违规活动。
3. 您应当妥善保管账户信息，对账户下的所有行为负责。

四、知识产权
本应用的所有知识产权归开发者所有，未经许可不得复制、传播或用于其他商业目的。

五、免责声明
1. 本应用不对因使用或无法使用本服务而产生的任何直接、间接、偶然、特殊或后果性损害承担责任。
2. 本应用不保证服务的及时性、安全性和准确性。

六、协议修改
我们有权随时修改本协议，修改后的协议将在本应用内公布。如您不同意修改后的协议，请停止使用本应用。

七、联系我们
如有任何疑问，请通过应用内反馈功能联系我们。

感谢您使用轻记！`;
  }

  // 隐私协议内容
  getPrivacyAgreementContent(): string {
    return `轻记隐私协议

我们非常重视您的隐私保护。本隐私协议说明了我们如何收集、使用、存储和保护您的个人信息。

一、信息收集
1. 记账数据：您主动输入的收入、支出等记账信息。
2. 设备信息：为保障账户安全，我们可能收集设备标识信息。
3. 位置信息：仅在您授权的情况下，用于记录消费地点。

二、信息使用
1. 我们使用您的记账数据为您提供记账、统计、分析等服务。
2. 我们采用鸿蒙加密存储技术，确保您的数据安全。
3. 我们使用端侧AI处理，所有数据仅在本地处理，不会上传至服务器。

三、信息存储
1. 您的所有数据均存储在您的设备本地，采用加密存储。
2. 我们不会将您的数据上传至任何服务器。
3. 您可以通过应用内的备份功能，将数据备份到您指定的位置。

四、信息保护
1. 我们采用业界领先的加密技术保护您的数据安全。
2. 我们不会向任何第三方分享、出售或出租您的个人信息。
3. 除非法律法规要求，我们不会向任何第三方披露您的信息。

五、您的权利
1. 您有权随时查看、修改、删除您的记账数据。
2. 您有权拒绝某些权限的授权，但这可能影响部分功能的使用。
3. 您有权随时停止使用本应用并删除数据。

六、儿童隐私保护
如果您是14周岁以下的儿童，请在监护人的陪同下阅读本协议，并在监护人的同意和指导下使用本应用。

七、协议更新
我们可能会不定期更新本隐私协议，更新后的协议将在本应用内公布。

八、联系我们
如有任何关于隐私的问题，请通过应用内反馈功能联系我们。

感谢您对轻记的信任！`;
  }

  build() {
    Column() {
      // 主内容区域
      Stack({ alignContent: Alignment.TopStart }) {
        Column() {
          // LOGO
          Image($r('app.media.logo1'))  // 替换为你的Logo路径
            .width(120)
            .height(120)
            .margin({ bottom: 20 })
            .borderRadius(60)
          // 欢迎登录
          Text(this.message)
            .fontSize(45)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 10 })

          // 用户名和密码
          TextInput({ placeholder: '请输入用户名' })
            .inputStyle()      // 引用公共样式函数
            .onChange(data => { // 输入值发生变化时，触发回调，data代表输入的内容
              this.user = data
              console.info('user:' + data)
            })

          TextInput({ placeholder: '请输入密码' })
            .type(InputType.Password)     // 输入框类型
            .inputStyle()       // 引用公共样式函数
            .onChange(data => { // 输入值发生变化时，触发回调，data代表输入的内容
              this.password = data
              console.info('password:' + data)
            })

          // 忘记密码（位置保持不变）
          // 忘记密码单独一行，右对齐
          Row() {
            // 左边留空，将忘记密码推到右边
            Blank()
            Text('忘记密码')
              .fontColor(Color.Blue)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/ForgotPage'
                })
              })
          }
          .justifyContent(FlexAlign.End) // 右对齐
          .width('80%') // 与输入框宽度保持一致
          .margin({ bottom: 10 })

          // 登录和注册按钮在同一行
          Row({ space: 20 }) {
            // 登录按钮在左边
            Button('登录', { type: ButtonType.Capsule, stateEffect: true })
              .width('35%')
              .enabled(this.agreementsChecked) // 只有在协议勾选后才启用
              .opacity(this.agreementsChecked ? 1 : 0.5) // 未勾选时变灰
              .onClick(() => {
                this.handleLogin()
              })

            // 注册按钮在右边
            Button('注册', { type: ButtonType.Capsule, stateEffect: true })
              .width('35%')
              .enabled(this.agreementsChecked) // 只有在协议勾选后才启用
              .opacity(this.agreementsChecked ? 1 : 0.5) // 未勾选时变灰
              .onClick(() => {
                this.handleRegister()
              })
          }
          .justifyContent(FlexAlign.SpaceBetween) // 两端对齐，登录左对齐，注册右对齐
          .width('80%') // 与输入框宽度保持一致
          .margin({ bottom: 20 })

          // 其它
          Row() {
            Text('其它登录方式')
              .fontColor(Color.Blue)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')

          // 重构：图片+文本 登录按钮
          Row() {
            ForEach(this.otherData, (item: LoginButton) => {
              Button({ stateEffect: true }) {
                // 方式1：图片 + 文本（推荐）
                Column({ space: 4 }) { // 垂直排列：图片在上，文字在下
                  Image($r(`app.media.login_${item.icon}`)) // 引用media目录下的图片
                    .width(40)
                    .height(40)
                    .borderRadius(20) // 圆形图标
                  Text(item.text)
                    .fontSize(12)
                    .fontColor(Color.Grey)
                }
              }
              .width(40)
              .height(40)
              .margin({ bottom: 0 })
              .borderRadius(20)
              .backgroundColor(Color.White) // 按钮背景色
              .border({ width: 0, color: Color.Grey, radius: 8 }) // 边框
              .onClick(() => {
                // 不同登录方式的点击事件
                promptAction.showToast({
                  message: `选择了${item.text}登录`,
                  duration: 1500
                })
              })
            })
          }

          .justifyContent(FlexAlign.SpaceAround)
          .width('100%')
          .margin(20)

          // 协议勾选区域 - 两个协议在同一行，使用同一个复选框
          Row({ space: 8 }) {
            // 复选框
            Checkbox()
              .select(this.agreementsChecked)
              .onChange((value: boolean) => {
                this.agreementsChecked = value;
              })
              .width(14)
              .height(14)
              .margin({ right: 2 })

            // 协议文本 - 全部放在同一行
            Row({ space: 4 }) {
              Text('我已阅读并同意')
                .fontSize(12)
                .fontColor(Color.Grey)

              Text('《用户协议》')
                .fontSize(12)
                .fontColor(Color.Blue)
                .onClick(() => {
                  this.showAgreement(AgreementType.USER_AGREEMENT);
                })

              Text('和')
                .fontSize(12)
                .fontColor(Color.Grey)

              Text('《隐私协议》')
                .fontSize(12)
                .fontColor(Color.Blue)
                .onClick(() => {
                  this.showAgreement(AgreementType.PRIVACY_AGREEMENT);
                })
            }
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .margin({ top: 100, bottom: 40 })
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.Center)

        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White) // 页面背景色
        .justifyContent(FlexAlign.Center)


        // 协议对话框 - 使用Stack定位在顶层
        if (this.showAgreementDialog) {
          // 半透明遮罩层
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#000000')
            .opacity(0.5)
            .position({ x: 0, y: 0 })
            .zIndex(100)
            .onClick(() => {
              this.showAgreementDialog = false;
            })

          // 协议内容对话框
          Column() {
            // 对话框标题栏
            Row() {
              Text(this.dialogTitle)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .flexGrow(1)
            }
            .width('100%')
            .padding({
              left: 24,
              right: 24,
              top: 20,
              bottom: 20
            })
            .backgroundColor('#FFFFFF')
            .borderRadius({ topLeft: 12, topRight: 12 })

            // 协议内容
            Scroll() {
              Text(this.dialogContent)
                .fontSize(14)
                .fontColor('#333333')
                .lineHeight(22)
                .width('100%')
                .padding({
                  top: 10,
                  bottom: 20,
                  left: 24,
                  right: 24
                })
            }
            .width('100%')
            .height(360)
            .scrollBar(BarState.Auto)
            .backgroundColor('#FFFFFF')

            // 确认按钮
            Button('我知道了')
              .width('30%')
              .height(40)
              .margin({ top: 10, bottom: 20 })
              .backgroundColor('#FFD700')
              .fontColor('#333333')
              .borderRadius(8)
              .onClick(() => {
                this.showAgreementDialog = false;
              })
          }
          .width('85%')
          .height('70%')
          .position({ x: '7.5%', y: '15%' })
          .zIndex(101)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({
            radius: 20,
            color: '#000000',
            offsetX: 0,
            offsetY: 4
          })
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}

// 添加公共的样式函数
// @Extend装饰器：扩展组件样式
// @Extend(组件描述名称) function 样式名称(){}
@Extend(TextInput)
function inputStyle() {
  .placeholderColor(Color.Pink) // 设置颜色
  .maxLength(8) // 设置最大长度
  .margin({ bottom: 10 })
  .width('80%') // 补充：设置输入框宽度
  .height(40) // 补充：设置输入框高度
  .border({ width: 1, color: Color.Grey, radius: 8 }) // 输入框边框
  .padding({ left: 10 }) // 输入框内边距
}