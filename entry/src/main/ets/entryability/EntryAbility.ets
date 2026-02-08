import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import router from '@ohos.router';
import { setAppContext } from '../utils/AppContextHolder';
import { initDatabase } from '../DatabaseUtil';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 原有数据库初始化逻辑
    initDatabase(this.context);

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      setAppContext(this.context.getApplicationContext());
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    // ========== 多卡片跳转逻辑：ArkTS兼容if/else，无索引语法报错 ==========
    try {
      const cardParam: string | undefined = want.parameters?.info as string;
      hilog.info(DOMAIN, 'testTag', '卡片跳转参数：%{public}s', cardParam ?? '无参数');

      // 无参数则走默认页面，不跳转
      if (!cardParam) {
        hilog.info(DOMAIN, 'testTag', '普通启动，进入默认页');
        return;
      }

      // 严格if/else匹配，规避ArkTS对象索引报错，路径为绝对路径
      if (cardParam === 'to_mainPage') {
        // 卡片1 → 主页面
        router.pushUrl({ url: 'pages/MainPage' });
        hilog.info(DOMAIN, 'testTag', '跳转至 MainPage 成功');
      } else if (cardParam === 'to_aiChatPage') {
        // 卡片2 → AI聊天页
        router.pushUrl({ url: 'pages/AiChatPage' });
        hilog.info(DOMAIN, 'testTag', '跳转至 AiChatPage 成功');
      } else if (cardParam === 'to_recordPage') {
        // 卡片3 → 统计页
        router.pushUrl({ url: 'pages/RecordPage' });
        hilog.info(DOMAIN, 'testTag', '跳转至 StatisticsPage 成功');
      } else {
        hilog.info(DOMAIN, 'testTag', '未匹配跳转规则，使用默认页');
      }
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', '卡片跳转异常：%{public}s', JSON.stringify(err));
    }

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  // 应用后台被唤醒时，同样处理卡片跳转（核心必加）
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', 'onNewWant 接收到卡片参数');
    try {
      const cardParam: string | undefined = want.parameters?.info as string;
      if (!cardParam) return;

      if (cardParam === 'to_mainPage') {
        router.pushUrl({ url: 'pages/MainPage' });
      } else if (cardParam === 'to_aiChatPage') {
        router.pushUrl({ url: 'pages/AiChatPage' });
      } else if (cardParam === 'to_recordPage') {
        router.pushUrl({ url: 'pages/RecordPage' });
      }
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'onNewWant跳转失败：%{public}s', JSON.stringify(err));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}