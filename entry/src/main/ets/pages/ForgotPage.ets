// pages/ForgotPage.ets
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import pasteboard from '@ohos.pasteboard';
import { CommonNavBar } from '../components/CommonNavBar';
import { getPasswordByUsername, decryptPwd } from '../DatabaseUtil';

@Entry
@Component
struct ForgotPage {
  @State username: string = ''; // 输入的用户名
  @State isLoading: boolean = false; // 加载状态
  @State foundPassword: string = ''; // 找到的原密码（明文）
  @State showResult: boolean = false; // 是否显示结果

  // 查询并解密密码
  private async handleQueryPassword(): Promise<void> {
    if (this.isLoading) return;

    if (!this.username.trim()) {
      promptAction.showToast({ message: '请输入用户名' });
      return;
    }

    this.isLoading = true;
    this.showResult = false;
    this.foundPassword = '';

    try {
      // 获取加密后的密码
      const encryptedPassword = await getPasswordByUsername(this.username.trim());

      if (encryptedPassword) {
        // 解密密码
        this.foundPassword = decryptPwd(encryptedPassword);

        if (this.foundPassword) {
          this.showResult = true;
          promptAction.showToast({ message: '查询成功', duration: 2000 });
        } else {
          promptAction.showToast({ message: '密码解密失败', duration: 2000 });
        }
      } else {
        promptAction.showToast({ message: '该用户名不存在', duration: 2000 });
      }
    } catch (error) {
      console.error('查询密码失败:', error);
      promptAction.showToast({ message: '查询失败，请重试', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  // 复制密码到剪贴板
  private async copyPassword(): Promise<void> {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.foundPassword);
      const systemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteData);

      promptAction.showToast({ message: '密码已复制到剪贴板', duration: 2000 });
    } catch (error) {
      promptAction.showToast({ message: '复制失败', duration: 2000 });
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      CommonNavBar({
        options: {
          showBack: true,
          title: '忘记密码',
          onLeftClick: () => {
            router.replaceUrl({ url: 'pages/LoginPage' });
          }
        }
      });

      Scroll() {
        Column({ space: 20 }) {
          // 页面标题
          Column({ space: 8 }) {
            Text('🔐 找回密码')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#000000')

            Text('请输入您的用户名查询原密码')
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .margin({ top: 40, bottom: 20 })

          // 输入区域
          Column({ space: 16 }) {
            // 用户名输入
            Column({ space: 8 }) {
              Text('用户名')
                .fontSize(14)
                .fontColor('#333333')
                .width('100%')
                .textAlign(TextAlign.Start)

              TextInput({ placeholder: '请输入您的用户名', text: this.username })
                .placeholderColor('#999999')
                .height(48)
                .width('100%')
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .padding({ left: 16, right: 16 })
                .onChange((value: string) => {
                  this.username = value;
                })
            }
            .width('100%')

            // 查询按钮
            Button(this.isLoading ? '查询中...' : '查询原密码', {
              type: ButtonType.Capsule,
              stateEffect: true
            })
              .width('100%')
              .height(48)
              .backgroundColor(this.isLoading ? '#CCCCCC' : '#007AFF')
              .fontColor('#FFFFFF')
              .fontSize(16)
              .enabled(!this.isLoading)
              .onClick(() => {
                this.handleQueryPassword();
              })

            // 返回登录按钮
            Button('返回登录', {
              type: ButtonType.Capsule,
              stateEffect: true
            })
              .width('100%')
              .height(48)
              .backgroundColor('#FFFFFF')
              .fontColor('#007AFF')
              .borderColor('#007AFF')
              .borderWidth(1)
              .fontSize(16)
              .onClick(() => {
                router.replaceUrl({ url: 'pages/LoginPage' });
              })
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)

          // 查询结果区域 - 明文显示原密码
          if (this.showResult && this.foundPassword) {
            Column({ space: 16 }) {
              Text('✅ 查询成功')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#34C759')
                .width('100%')
                .textAlign(TextAlign.Center)

              Text('您的原密码如下：')
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .textAlign(TextAlign.Center)

              // 明文密码显示框 - 使用 Text 直接显示
              Column({ space: 8 }) {
                Text('原密码')
                  .fontSize(12)
                  .fontColor('#999999')
                  .width('100%')
                  .textAlign(TextAlign.Start)

                // 关键修改：使用 Text 直接明文显示，红色大号字体突出显示
                Text(this.foundPassword)
                  .fontSize(24) // 大字号
                  .fontColor('#FF3B30') // 红色
                  .fontWeight(FontWeight.Bold) // 粗体
                  .width('100%')
                  .height(60)
                  .backgroundColor('#FFF5F5') // 浅红背景
                  .borderRadius(8)
                  .padding({ left: 16, right: 16 })
                  .textAlign(TextAlign.Center) // 居中显示
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)

              // 复制按钮
              Button('复制密码')
                .width('100%')
                .height(44)
                .backgroundColor('#34C759')
                .fontColor('#FFFFFF')
                .fontSize(16)
                .onClick(() => {
                  this.copyPassword();
                })

              // 提示信息
              Text('💡 提示：请牢记您的密码，或复制保存到安全位置')
                .fontSize(12)
                .fontColor('#007AFF')
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ top: 8 })
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#E8F5E9')
            .borderRadius(12)
            .margin({ top: 10 })
          }

          // 安全提示
          Column({ space: 8 }) {
            Text('🔒 安全提示')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#000000')
              .width('100%')

            Text('1. 请确保您是账号的合法所有者')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')

            Text('2. 查询结果请勿泄露给他人')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')

            Text('3. 建议定期修改密码以保证安全')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFF8E1')
          .borderRadius(12)
          .margin({ top: 10 })
        }
        .width('100%')
        .padding(20)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F2F2F7')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}