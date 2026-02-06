// entry/src/main/ets/pages/AiChatPage.ets
import { AiService } from '../services/AiService';
import promptAction from '@ohos.promptAction'; // 新增：鸿蒙原生提示框，提升用户体验

/**
 * AI智能问答页面
 * 职责：仅处理页面交互逻辑，业务逻辑委托给AiService，符合单一职责原则
 */
@Entry
@Component
struct AiChatPage {
  // 状态管理：用户输入、AI回答、加载状态
  @State inputText: string = '';
  @State resultText: string = '';
  @State isLoading: boolean = false; // 新增：加载状态，防止重复点击

  /**
   * 发送提问的处理方法
   */
  async sendMsg() {
    // 1. 加载状态控制（防止重复点击）
    if (this.isLoading) {
      return;
    }
    this.isLoading = true;
    this.resultText = 'AI 正在思考中...';

    try {
      // 2. 调用AI服务层获取回答
      this.resultText = await AiService.chat(this.inputText);
    } catch (e) {
      // 3. 友好的错误提示（用户可感知）
      const errMsg = (e as Error).message;
      this.resultText = `提问失败：${errMsg}`;
      // 新增：鸿蒙原生弹窗提示，提升体验
      promptAction.showToast({
        message: errMsg,
        duration: 3000,
        bottom: 200
      });
    } finally {
      // 4. 无论成功失败，都结束加载状态
      this.isLoading = false;
    }
  }

  build() {
    Column({ space: 16 }) {
      // 页面标题
      Text('智谱AI智能问答')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 });

      // 输入框：禁用多行，限制输入长度
      TextInput({
        placeholder: '请输入你的问题（如：解释OpenHarmony的分层架构）',
        text: this.inputText
      })
        .width('100%')
        .height(80)
        .backgroundColor('#f5f5f5')
        .padding(12)
        .maxLength(500) // 限制输入长度，避免超长请求
        .onChange(v => this.inputText = v);

      // 发送按钮：加载状态下禁用
      Button('发送提问')
        .width('100%')
        .height(48)
        .backgroundColor('#007dff')
        .fontColor(Color.White)
        .borderRadius(8)
        .enabled(!this.isLoading) // 替换为enabled，isLoading为true时按钮不可用
        .onClick(() => this.sendMsg());

      // AI回答区域：可滚动，适配长文本
      Scroll() {
        Text(this.resultText)
          .fontSize(16)
          .lineHeight(24)
          .padding(12)
          .backgroundColor('#f9f9f9')
          .borderRadius(8)
          .width('100%');
      }
      .height(300)
      .backgroundColor('#ffffff')
      .border({ width: 1, color: '#eeeeee', radius: 8 })
      .margin({ top: 8 });

    }
    .padding(20)
    .width('100%')
    .height('100%')
    .backgroundColor('#fafafa');
  }
}