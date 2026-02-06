import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@ohos.base';
import { CommonNavBar } from '../components/CommonNavBar'


// 简化的设置项接口
interface SimpleSettingItem {
  title: string; // 标题
  icon: string; // 图标资源名
  onClick: () => void; // 点击事件
}

@Entry
@Component
struct SimpleSettingsPage {
  // 核心设置项列表（简化版）
  @State settingItems: SimpleSettingItem[] = [
    {
      title: '账号与安全',
      icon: 'icon_account',
      onClick: (): void => this.navigateTo('pages/AccountSecurityPage')
    },
    {
      title: '隐私设置',
      icon: 'icon_privacy',
      onClick: (): void => this.navigateTo('pages/PrivacySettingPage')
    },
    {
      title: '清除缓存',
      icon: 'icon_clean',
      onClick: (): void => this.cleanCache()
    },
    {
      title: '关于轻记',
      icon: 'icon_about',
      onClick: (): void => this.navigateTo('pages/AboutPage')
    },
    {
      title: '退出登录',
      icon: 'icon_logout',
      onClick: (): void => this.logout()
    }
  ];

  // 页面跳转通用方法
  navigateTo(pageUrl: string) {
    try {
      router.replaceUrl({ url: pageUrl });
    } catch (error) {
      const err = error as BusinessError;
      promptAction.showToast({ message: `跳转失败：${err.message}` });
    }
  }

  // 清除缓存
  cleanCache() {
    promptAction.showToast({ message: '正在清理缓存...' });
    // 模拟缓存清理
    setTimeout(() => {
      promptAction.showToast({ message: '缓存清理完成' });
    }, 1000);
  }

  // 退出登录
  logout() {
    promptAction.showDialog({
      title: '确认退出',
      message: '是否退出当前账号？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确认', color: '#FF3B30' }
      ]
    }).then(res => {
      if (res.index === 1) {
        router.replaceUrl({ url: 'pages/LoginPage' });
        promptAction.showToast({ message: '已退出登录' });
      }
    });
  }

  // 构建设置项
  @Builder
  buildSettingItem(item: SimpleSettingItem) {
    Row({ space: 16 }) {
      // 图标
      Image($r(`app.media.${item.icon}`))
        .width(24)
        .height(24)
        .fillColor('#666666')

      // 标题
      Text(item.title)
        .fontSize(16)
        .fontColor('#333333')
        .flexGrow(1)

      // 右箭头
      Image($r('app.media.ic_arrow'))
        .width(16)
        .height(16)
        .fillColor('#CCCCCC')
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 20,
      bottom: 20
    })
    .backgroundColor('#FFFFFF')
    .onClick(() => item.onClick())
  }

  build() {
    Column() {
      // 导航栏
      CommonNavBar({

        options: {
          showBack: true,
          title: '设置',
          onLeftClick: () =>{
            router.replaceUrl({ url: 'pages/MinePage' })// 右侧按钮点击事件（可选）
          }
        }
      });

      // 设置列表（简化版）
      Scroll() {
        Column({ space: 8 }) {
          // 遍历设置项
          ForEach(this.settingItems, (item: SimpleSettingItem) => {
            this.buildSettingItem(item)
          })
        }
        .width('100%')
        .padding({ top: 8, bottom: 20 })
      }
      .flexGrow(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}