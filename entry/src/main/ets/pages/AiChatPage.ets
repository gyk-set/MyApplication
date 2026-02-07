import { AiService } from '../services/AiService';
import promptAction from '@ohos.promptAction';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';
// 导入通用导航栏组件
import { CommonNavBar } from '../components/CommonNavBar';

/**
 * 聊天消息类型定义
 */
interface ChatMessage {
  id: number;
  content: string;
  isUser: boolean;
  timestamp: number;
}

/**
 * 本地存储数据结构
 */
interface ChatHistoryData {
  messages: ChatMessage[];
  messageId: number;
}

@Entry
@Component
struct AiChatPage {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State messages: ChatMessage[] = [];
  // 适配低版本：用 ListScroller 替代 ListController
  private listScroller: ListScroller = new ListScroller();

  private messageId: number = 0;
  private readonly STORAGE_KEY: string = 'chat_history';
  private readonly PREF_NAME: string = 'ai_chat_preferences';
  private pref: preferences.Preferences | null = null;
  @State showQuickAsk: boolean = false;

  private readonly quickQuestions: string[] = [
    "你好，我的AI助手",
    "如何快速记账，请简单回复？",
    "记账的好处都有哪些，简单回复？",
    "教我零基础个人记账的核心方法，要求步骤简单、易坚持，适合月薪族日常使用",
    "推荐 3 个适合普通人的记账原则，能避免漏记、乱记，快速理清收支",
    "帮我梳理个人记账的必备科目，不用太复杂，覆盖日常工资、饮食、交通、娱乐即可",
    "教我学生党极简记账法，主打低成本、易操作，适配生活费有限、消费单一的场景",
    "设计一份上班族月度记账模板，包含固定开支、灵活消费、储蓄目标，可直接套用",
    "教我家庭合伙记账的方法，能清晰划分共同开支和个人开支，避免账目纠纷",
    "适合自由职业者的记账技巧，兼顾收入不固定、多平台收款、成本核算的需求",
    "教我极简攒钱式记账法，核心是通过记账控制非必要消费，快速攒下第一笔钱"
  ];
  /**
   * 页面显示生命周期
   */
  async aboutToAppear(): Promise<void> {
    await this.initPreferences();
    await this.loadChatHistory();
    // 页面打开后延迟滚动到底部（适配低版本）
    setTimeout(() => {
      this.scrollToBottom();
    }, 150);
  }

  /**
   * 初始化本地存储
   */
  private async initPreferences(): Promise<void> {
    try {
      this.pref = await preferences.getPreferences(this.context, this.PREF_NAME);
    } catch (error) {
      console.error("存储初始化失败");
    }
  }

  /**
   * 加载聊天历史
   */
  async loadChatHistory(): Promise<void> {
    if (!this.pref) return;
    try {
      const savedHistory = await this.pref.get(this.STORAGE_KEY, "") as string;
      if (savedHistory) {
        const history = JSON.parse(savedHistory) as ChatHistoryData;
        this.messages = Array.isArray(history.messages) ? history.messages : [];
        this.messageId = typeof history.messageId === "number" ? history.messageId : 0;
      }
    } catch (error) {
      this.messages = [];
      this.messageId = 0;
    }
  }

  /**
   * 保存聊天历史
   */
  private async saveChatHistory(): Promise<void> {
    if (!this.pref) return;
    try {
      const data: ChatHistoryData = {
        messages: this.messages,
        messageId: this.messageId
      };
      await this.pref.put(this.STORAGE_KEY, JSON.stringify(data));
      await this.pref.flush();
    } catch {}
  }

  /**
   * 清空对话历史
   */
  async clearHistory(): Promise<void> {
    if (!this.pref) return;
    this.messages = [];
    this.messageId = 0;
    await this.pref.delete(this.STORAGE_KEY);
    await this.pref.flush();
    promptAction.showToast({ message: "已清空", duration: 2000 });
  }

  /**
   * 添加消息
   */
  private addMessage(content: string, isUser: boolean): void {
    const id = this.messageId++;
    this.messages = [...this.messages, {
      id: id,
      content: content,
      isUser: isUser,
      timestamp: Date.now()
    }];
    this.saveChatHistory();
    // 添加消息后立即滚动到底部
    setTimeout(() => {
      this.scrollToBottom();
    }, 50);
  }

  /**
   * 时间格式化
   */
  private formatTime(timestamp: number): string {
    const d: Date = new Date(timestamp);
    const h: string = d.getHours().toString().padStart(2, "0");
    const m: string = d.getMinutes().toString().padStart(2, "0");
    return h + ":" + m;
  }

  /**
   * 滚动到列表最后一条消息（适配最低版本：用 scrollTo 实现）
   */
  private scrollToBottom(): void {
    if (this.messages.length > 0) {
      // 最低版本API：滚动到最大偏移量，确保滚到底部
      this.listScroller.scrollTo({
        xOffset: 0,
        yOffset: 99999,
        animation: true
      });
    }
  }

  /**
   * 返回按钮点击事件
   */
  private onBackClick(): void {
    try {
      router.back();
    } catch (error) {
      console.error("返回失败:", error);
    }
  }

  /**
   * 发送消息核心逻辑
   */
  async sendMessage(): Promise<void> {
    const text: string = this.inputText.trim();
    if (!text || this.isLoading) {
      return;
    }

    this.isLoading = true;
    const sendText: string = text;
    this.inputText = "";

    this.addMessage(sendText, true);

    try {
      const res: string = await AiService.chat(sendText);
      this.addMessage(res, false);
    } catch (error) {
      let msg: string = "请求失败，请重试";
      try {
        if (error instanceof Error) {
          msg = error.message;
        }
      } catch {}
      this.addMessage("❌ " + msg, false);
      promptAction.showToast({ message: msg, duration: 2500, bottom: 200 });
    } finally {
      setTimeout((): void => {
        this.isLoading = false;
      }, 0);
    }
  }

  build() {
    Stack() {
      Column({ space: 0 }) {
        // ========== 使用通用导航栏组件，右侧按钮实现清空历史 ==========
        CommonNavBar({
          options: {
            showBack: true,
            title: "轻记AI智能助手",
            backIconColor: "#fff",
            rightText: '清历史', // 清空图标名称
            onLeftClick: this.onBackClick.bind(this),
            onRightClick: async () => {
              await this.clearHistory();
            }
          }
        });

        // 消息列表区域（占满剩余空间，输入框弹出时被挤压）
        Column() {
          if (this.messages.length === 0) {
            Column() {
              Image($r('app.media.logo1'))
                .width(100)
                .height(100)
                .opacity(0.8)
                .borderRadius(50); // 添加圆角，数值越大圆角越明显
              Text("你好！我是AI助手")
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .margin({ top: 20, bottom: 8 });
              Text("我可以回答各种问题，试试问我吧！")
                .fontSize(14)
                .fontColor("#666666")
                .margin({ bottom: 24 });

              Column({ space: 12 }) {
                ForEach(
                  ["你好，我的AI助手", "如何快速记账，请简单回复？", "记账的好处都有哪些，简单回复？"],
                  (item: string) => {
                    Text(item)
                      .fontSize(13)
                      .fontColor("#007dff")
                      .padding({
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 8
                      })
                      .backgroundColor("#007dff10")
                      .borderRadius(20)
                      .border({ width: 1, color: "#007dff30" })
                      .onClick((): void => {
                        this.inputText = item;
                      });
                  },
                  (item: string) => item
                );
              }
            }
            .width("100%")
            .height("100%")
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
          } else {
            List({ space: 16, scroller: this.listScroller }) {
              ForEach(
                this.messages,
                (msg: ChatMessage) => {
                  ListItem() {
                    Column({ space: 6 }) {
                      if (msg.isUser) {
                        // 用户消息区域 - 带头像
                        Column() {
                          // 用户信息行：头像 + 名称 + 时间
                          Row() {
                            Text(this.formatTime(msg.timestamp))
                              .fontSize(10)
                              .fontColor("#999999")
                              .margin({ right: 8 });
                            Text("你")
                              .fontSize(12)
                              .fontColor("#666666")
                              .margin({ right: 8 });
                            // 用户头像
                            Image($r('app.media.User_Avatar'))
                              .width(24)
                              .height(24)
                              .borderRadius(12) // 圆形头像
                              .objectFit(ImageFit.Cover);
                          }
                          .justifyContent(FlexAlign.End)
                          .width("100%");

                          // 用户消息内容行
                          Row() {
                            Text(msg.content)
                              .fontSize(15)
                              .fontColor("#ffffff")
                              .padding(12)
                              .backgroundColor("#007dff")
                              .borderRadius({
                                topLeft: 12,
                                topRight: 4,
                                bottomLeft: 12,
                                bottomRight: 12
                              })
                          }
                          .justifyContent(FlexAlign.End)
                          .width("80%");
                        }
                      } else {
                        // AI助手消息区域 - 带头像
                        Column() {
                          // AI信息行：头像 + 名称 + 时间
                          Row() {
                            // AI头像
                            Image($r('app.media.logo1'))
                              .width(24)
                              .height(24)
                              .borderRadius(12) // 圆形头像
                              .objectFit(ImageFit.Cover)
                              .margin({ right: 8 });
                            Text("AI助手")
                              .fontSize(12)
                              .fontColor("#666666")
                              .margin({ right: 8 });
                            Text(this.formatTime(msg.timestamp))
                              .fontSize(10)
                              .fontColor("#999999");
                          }
                          .justifyContent(FlexAlign.Start)
                          .width("100%");

                          // AI消息内容行
                          Row() {
                            Text(msg.content)
                              .fontSize(15)
                              .fontColor("#333333")
                              .padding(12)
                              .backgroundColor("#f0f0f0")
                              .borderRadius({
                                topLeft: 4,
                                topRight: 12,
                                bottomLeft: 12,
                                bottomRight: 12
                              })
                          }
                          .justifyContent(FlexAlign.Start)
                          .width("80%");
                        }
                      }
                    }
                    .margin({ top: 4, bottom: 4 });
                  }
                },
                (msg: ChatMessage) => msg.id.toString()
              );
            }
            .width("100%")
            .height("100%")
            .padding(16)
            .scrollBar(BarState.Off)
            .backgroundColor("#ffffff");
          }
        }
        .layoutWeight(1)
        .backgroundColor("#ffffff");

        // ===================== 输入框区域（在提示上方，跟随键盘） =====================
        Column() {
          Row({ space: 12 }) {
            TextInput({
              placeholder: "输入您的问题...",
              text: this.inputText
            })
              .layoutWeight(1)
              .height(44)
              .backgroundColor("#f8f9fa")
              .padding({ left: 16, right: 16 })
              .borderRadius(22)
              .maxLength(500)
              .onChange((v: string): void => {
                this.inputText = v;
              })
              .onSubmit((): void => {
                this.sendMessage();
              });

            Button() {
              Image($r('app.media.send_icon'))
                .width(24)
                .height(24);
            }
            .width(44)
            .height(44)
            .borderRadius(22)
            .backgroundColor(this.inputText.trim() !== "" && !this.isLoading ? "#007dff" : "#e0e0e0")
            .enabled(this.inputText.trim() !== "" && !this.isLoading)
            .onClick((): void => {
              this.sendMessage();
            });
          }
          .width("100%")
          .padding({
            left: 16,
            right: 16,
            top: 12,
            bottom: 8
          });
        }
        .backgroundColor("#ffffff")
        .border({ width: 1, color: "#f0f0f0" });

        // ===================== 固定底部提示栏（永远贴底，不移动、不被键盘顶起） =====================
        Row() {
          Text("💡 AI可能会产生不准确信息，请谨慎核实")
            .fontSize(11)
            .fontColor("#999999");
        }
        .width("100%")
        .height(30)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor("#ffffff")
        .zIndex(-1);
      }

      this.buildQuickAskPanel()
    }
    .width("100%")
    .height("100%")
    .backgroundColor("#ffffff");
  }
  @Builder
  private buildQuickAskPanel() {
    if (!this.showQuickAsk) {
      // 只显示悬浮按钮
      Button() {
        Column() {
          Text("快")
          Text("速")
          Text("提")
          Text("问")
        }
        .height("100%")
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 4, bottom: 4 })
      }
      .fontSize(12)
      .fontColor("#ffffff")
      .backgroundColor("#3399FF")
      .borderRadius(25)
      .width("10%")
      .height(100)
      .position({
        x: '90%',
        y: '70%'
      })
      .zIndex(100)
      .onClick(() => {
        this.showQuickAsk = true;
      })
    }

    // ========== 展开态 ==========
    if (this.showQuickAsk) {
      Stack() {
        // 1️⃣ 半透明遮罩（点空白关闭）
        Column()
          .width("100%")
          .height("100%")
          .backgroundColor("#00000040")
          .onClick(() => {
            this.showQuickAsk = false;
          });

        // 2️⃣ 右下角展开的面板（占 1/4 屏幕），可滚动
        Column({ space: 0 }) {
          // 标题区域 - 固定高度
          Row({ space: 0 }) {
            Text("快速提问")
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .flexGrow(1)
              .textAlign(TextAlign.Start)

            Button() {
              Image($r('app.media.ic_close'))
                .width(16)
                .height(16)
                .fillColor("#999999")
            }
            .width(24)
            .height(24)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.showQuickAsk = false;
            })
          }
          .width("100%")
          .height(56) // 固定高度
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .padding({ left: 16, right: 16 })
          .border({ width: { bottom: 1 }, color: "#f0f0f0" })

          // 可滚动的问题列表区域
          Column() {
            Scroll() {
              Column({ space: 8 }) {
                ForEach(this.quickQuestions, (item: string) => {
                  Text(item)
                    .fontSize(14)
                    .fontColor("#333333")
                    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                    .backgroundColor("#f9f9f9")
                    .borderRadius(8)
                    .border({ width: 1, color: "#eeeeee" })
                    .width("100%")
                    .onClick(() => {
                      this.inputText = item;
                      this.showQuickAsk = false;
                    });
                })
              }
              .padding(16)
              .width("100%")
            }
            .scrollable(ScrollDirection.Vertical)
            .scrollBar(BarState.Auto)
            .scrollBarColor("#cccccc")
            .scrollBarWidth(4)
          }
          .width("100%")
          .layoutWeight(1) // 关键：占据剩余所有高度
        }
        .width("50%")
        .height("50%")
        .backgroundColor("#ffffff")
        .borderRadius(16)
        .shadow({
          radius: 16,
          color: "#00000030",
          offsetX: 0,
          offsetY: 6
        })
        .position({
          x: '45%',
          y: '35%'
        });
      }
      .width("100%")
      .height("100%")
      .zIndex(99);
    }
  }


}