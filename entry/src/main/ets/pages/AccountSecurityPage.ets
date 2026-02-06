import { CommonNavBar } from '../components/CommonNavBar'
import relationalStore from '@ohos.data.relationalStore';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

import dataPreferences from '@ohos.data.preferences';

interface AccountSecurity
{ isValid: boolean, message: string }


@Entry
@Component
struct AccountSecurityPage {
  @State currentUsername: string = '';
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State isOldPasswordVisible: boolean = false;
  @State isNewPasswordVisible: boolean = false;
  @State isConfirmPasswordVisible: boolean = false;
  @State isLoading: boolean = false;
  @State isLoggedIn: boolean = false;

  aboutToAppear() {
    // 从AppStorage获取当前登录状态
    this.loadLoginState();
  }

  async loadLoginState() {
    try {
      // 从AppStorage获取用户名
      const username = AppStorage.get<string>('currentUsername');
      const loggedIn = AppStorage.get<boolean>('isLoggedIn');

      if (username && loggedIn) {
        this.currentUsername = username;
        this.isLoggedIn = true;
        console.log('从AppStorage获取到用户:', username);
      } else {
        // 如果AppStorage没有，尝试从Preferences获取
        await this.loadFromPreferences();
      }
    } catch (error) {
      console.error('加载登录状态失败:', error);
      // 尝试从Preferences获取
      await this.loadFromPreferences();
    }
  }

  async loadFromPreferences() {
    try {
      const preferences = await dataPreferences.getPreferences(getContext(), 'user_preferences');
      const username = await preferences.get('currentUsername', '') as string;
      const loggedIn = await preferences.get('isLoggedIn', false) as boolean;

      if (username && loggedIn) {
        this.currentUsername = username;
        this.isLoggedIn = true;
        console.log('从Preferences获取到用户:', username);

        // 同步到AppStorage
        AppStorage.setOrCreate('currentUsername', username);
        AppStorage.setOrCreate('isLoggedIn', true);
      }
    } catch (error) {
      console.error('从Preferences加载失败:', error);
    }
  }

  // 密码加密函数（与登录页保持一致）
  private encryptPwd(pwd: string): string {
    let hash = 0;
    for (let i = 0; i < pwd.length; i++) {
      hash = pwd.charCodeAt(i) + ((hash << 5) - hash);
    }
    let hex = '';
    for (let i = 0; i < 8; i++) {
      hex += (hash >> (i * 4) & 0xF).toString(16);
    }
    return hex;
  }

  // 修改密码逻辑
  async updatePassword(): Promise<boolean> {
    if (!this.currentUsername) {
      promptAction.showToast({ message: '未登录', duration: 2000 });
      return false;
    }

    try {
      const context = getContext(this) as Context;
      const dbConfig: relationalStore.StoreConfig = {
        name: '记账本.db',
        securityLevel: relationalStore.SecurityLevel.S1
      };
      const rdbStore = await relationalStore.getRdbStore(context, dbConfig);

      // 验证原密码
      const verifySql = `SELECT id FROM user_table WHERE username = ? AND password = ?`;
      const encryptedOldPwd = this.encryptPwd(this.oldPassword);
      const result = await rdbStore.querySql(verifySql, [this.currentUsername, encryptedOldPwd]);

      if (!result || result.rowCount === 0) {
        if (result) result.close();
        return false;
      }
      if (result) result.close();

      // 更新密码
      const updateSql = `UPDATE user_table SET password = ? WHERE username = ?`;
      const encryptedNewPwd = this.encryptPwd(this.newPassword);
      await rdbStore.executeSql(updateSql, [encryptedNewPwd, this.currentUsername]);

      // 更新成功后清除输入框
      this.oldPassword = '';
      this.newPassword = '';
      this.confirmPassword = '';

      return true;
    } catch (error) {
      console.error('修改密码失败:', error);
      return false;
    }
  }

  validateInput(): AccountSecurity {
    if (!this.oldPassword.trim()) {
      return { isValid: false, message: '请输入原密码' };
    }

    if (!this.newPassword.trim()) {
      return { isValid: false, message: '请输入新密码' };
    }

    if (this.newPassword.length < 6) {
      return { isValid: false, message: '新密码长度至少6位' };
    }

    if (!this.confirmPassword.trim()) {
      return { isValid: false, message: '请确认新密码' };
    }

    if (this.newPassword !== this.confirmPassword) {
      return { isValid: false, message: '两次输入的新密码不一致' };
    }

    if (this.oldPassword === this.newPassword) {
      return { isValid: false, message: '新密码不能与原密码相同' };
    }

    return { isValid: true, message: '' };
  }

  async onModifyPassword() {
    // 先检查是否登录
    if (!this.currentUsername || !this.isLoggedIn) {
      promptAction.showToast({ message: '请先登录', duration: 2000 });

      // 延时跳转到登录页
      setTimeout(() => {
        router.replaceUrl({
          url: 'pages/LoginPage'
        });
      }, 1500);
      return;
    }

    const validation = this.validateInput();
    if (!validation.isValid) {
      promptAction.showToast({ message: validation.message, duration: 2000 });
      return;
    }

    this.isLoading = true;

    try {
      const success = await this.updatePassword();
      if (success) {
        promptAction.showToast({ message: '密码修改成功', duration: 2000 });
      } else {
        promptAction.showToast({ message: '原密码错误', duration: 2000 });
      }
    } catch (error) {
      console.error('修改密码出错:', error);
      promptAction.showToast({ message: '修改失败，请重试', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  onLogout() {
    promptAction.showDialog({
      title: '提示',
      message: '确定要退出登录吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#007DFF' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        // 用户点击了确定
        this.clearLoginState();
        promptAction.showToast({ message: '已退出登录', duration: 1500 });

        // 跳转到登录页面
        setTimeout(() => {
          router.replaceUrl({
            url: 'pages/LoginPage'
          });
        }, 1500);
      }
    });
  }

  clearLoginState() {
    try {
      // 清除AppStorage中的登录状态
      AppStorage.delete('currentUsername');
      AppStorage.delete('isLoggedIn');
      AppStorage.delete('userInfo');

      // 清除页面状态
      this.currentUsername = '';
      this.isLoggedIn = false;

      // 清除输入框
      this.oldPassword = '';
      this.newPassword = '';
      this.confirmPassword = '';

      // 清除Preferences中的登录状态
      this.clearPreferences();
    } catch (error) {
      console.error('清除登录状态失败:', error);
    }
  }

  async clearPreferences() {
    try {
      const preferences = await dataPreferences.getPreferences(getContext(), 'user_preferences');
      await preferences.delete('currentUsername');
      await preferences.delete('isLoggedIn');
      await preferences.delete('userInfo');
      await preferences.flush();
      console.log('Preferences登录状态已清除');
    } catch (error) {
      console.error('清除Preferences失败:', error);
    }
  }

  goToLogin() {
    router.pushUrl({
      url: 'pages/LoginPage'
    });
  }

  build() {
    Column() {
      CommonNavBar({
        options: {
          showBack: true,
          onLeftClick: () =>{
            router.replaceUrl({ url: 'pages/SettingsPage' })// 右侧按钮点击事件（可选）
          },
          title: '账号与安全',
        }
      });

      Scroll() {
        Column() {
          // 当前账号信息卡片
          Column() {
            Text('当前账号')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ bottom: 5 })

            if (this.currentUsername && this.isLoggedIn) {
              // 已登录状态
              Text(this.currentUsername)
                .fontSize(20)
                .fontColor('#000000')
                .fontWeight(FontWeight.Medium)
                .margin({ bottom: 15 })

              // 退出登录按钮
              Button('退出登录', { type: ButtonType.Normal })
                .width(100)
                .height(36)
                .fontSize(14)
                .fontColor('#FF6B35')
                .backgroundColor(Color.Transparent)
                .borderColor('#FF6B35')
                .borderWidth(1)
                .borderRadius(18)
                .onClick(() => {
                  this.onLogout();
                })
            } else {
              // 未登录状态
              Text('未登录')
                .fontSize(18)
                .fontColor('#999999')
                .margin({ bottom: 15 })

              // 前往登录按钮
              Button('前往登录', { type: ButtonType.Capsule })
                .width(120)
                .height(40)
                .fontSize(16)
                .backgroundColor('#007DFF')
                .fontColor('#FFFFFF')
                .onClick(() => {
                  this.goToLogin();
                })
            }
          }
          .width('90%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ top: 20, bottom: 30 })
          .alignItems(HorizontalAlign.Center)
          .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })

          // 只有在登录状态下才显示修改密码表单
          if (this.currentUsername && this.isLoggedIn) {
            Column() {
              Text('修改密码')
                .fontSize(20)
                .fontColor('#000000')
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 20 })

              // 原密码输入框
              Column() {
                Text('原密码')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 5 })

                Row() {
                  TextInput({
                    text: this.oldPassword,
                    placeholder: '请输入原密码'
                  })
                    .width('100%')
                    .type(this.isOldPasswordVisible ? InputType.Normal : InputType.Password)
                    .onChange((value: string) => {
                      this.oldPassword = value;
                    })
                    .border({ width: 1, color: '#E0E0E0', radius: 6 })
                    .padding({ left: 10 })
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .margin({ bottom: 20 })

              // 新密码输入框
              Column() {
                Text('新密码')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 5 })

                Row() {
                  TextInput({
                    text: this.newPassword,
                    placeholder: '请输入新密码（至少6位）'
                  })
                    .width('100%')
                    .type(this.isNewPasswordVisible ? InputType.Normal : InputType.Password)
                    .onChange((value: string) => {
                      this.newPassword = value;
                    })
                    .border({ width: 1, color: '#E0E0E0', radius: 6 })
                    .padding({ left: 10 })
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .margin({ bottom: 20 })

              // 确认新密码输入框
              Column() {
                Text('确认新密码')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 5 })

                Row() {
                  TextInput({
                    text: this.confirmPassword,
                    placeholder: '请再次输入新密码'
                  })
                    .width('100%')
                    .type(this.isConfirmPasswordVisible ? InputType.Normal : InputType.Password)
                    .onChange((value: string) => {
                      this.confirmPassword = value;
                    })
                    .border({ width: 1, color: '#E0E0E0', radius: 6 })
                    .padding({ left: 10 })
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .margin({ bottom: 30 })

              // 修改按钮
              Button('确认修改', { type: ButtonType.Capsule })
                .width('100%')
                .height(50)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .backgroundColor('#007DFF')
                .fontColor('#FFFFFF')
                .enabled(!this.isLoading &&
                  this.oldPassword.trim() !== '' &&
                  this.newPassword.trim() !== '' &&
                  this.confirmPassword.trim() !== '')
                .onClick(() => {
                  this.onModifyPassword();
                })

              if (this.isLoading) {
                Row() {
                  LoadingProgress()
                    .width(30)
                    .height(30)
                  Text('修改中...')
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ left: 10 })
                }
                .margin({ top: 15 })
                .justifyContent(FlexAlign.Center)
              }
            }
            .width('90%')
            .padding(25)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
            .margin({ bottom: 30 })
          } else {
            // 未登录时的提示
            Column() {

              Text('登录后使用')
                .fontSize(18)
                .fontColor('#666666')
                .margin({ bottom: 10 })

              Text('请先登录以管理您的账号安全')
                .fontSize(14)
                .fontColor('#999999')
                .textAlign(TextAlign.Center)
                .margin({ bottom: 25 })
            }
            .width('90%')
            .padding(40)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
            .alignItems(HorizontalAlign.Center)
          }
        }
        .width('100%')
        .padding({ bottom: 40 })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}