import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { RecordStore } from '../data/RecordStore';
import { DateUtils } from '../utils/DateUtils';
import { TabItem } from '../models/Record'
import { CommonTabBar, DefaultTabItems } from '../components/CommonTabBar';
import { CommonNavBar } from '../components/CommonNavBar';

@Entry
@Component
struct MainPage {
  private recordStore: RecordStore | undefined = undefined;
  @State currentDate: string = '';
  @State todaySpend: number = 0;
  @State yesterdayChange: string = '0%';
  @State expense: number = 0;
  @State income: number = 0;
  // 当前选中的Tab索引（用于高亮图标/文字）
  @State currentIndex: number = 0;
  // 底部Tab配置
  private tabItems: Array<TabItem> = DefaultTabItems;

  // 数据变更监听回调（用于销毁时取消监听）
  private dataChangeListener: () => void = () => {};

  async aboutToAppear(): Promise<void> {
    this.recordStore = RecordStore.getInstance();
    await this.recordStore.ready();
    this.currentDate = DateUtils.formatChineseDate(DateUtils.getCurrentDate());
    this.updateData();

    // 注册数据变更监听
    this.dataChangeListener = () => {
      console.log('MainPage: 收到数据变更通知，刷新数据');
      this.updateData();
    };
    this.recordStore.onDataChanged(this.dataChangeListener);
  }

  // 页面销毁时取消监听，避免内存泄漏
  aboutToDisappear(): void {
    if (this.recordStore && this.dataChangeListener) {
      this.recordStore.offDataChanged(this.dataChangeListener);
      console.log('MainPage: 取消数据变更监听');
    }
  }

  private updateData(): void {
    if (!this.recordStore) {
      return;
    }
    this.todaySpend = this.recordStore.getTodayExpense();
    this.expense = this.recordStore.getTodayExpense();
    this.income = this.recordStore.getTodayIncome();
    this.yesterdayChange = this.recordStore.getExpenseChangePercent();

  }

  // 新增：跳转按钮的点击事件处理函数
  private navigateToOtherPage() {
    // 这里替换为你要跳转的页面路径（例如：记账详情页/统计页/设置页）
    router.pushUrl({
      url: 'pages/AiChatPage' // 请根据实际页面路径修改
    });
  }

  build() {
    Column() {
      // 1. 顶部导航栏（CommonNavBar）
      CommonNavBar({

        options: {
          showBack: false,
          title: '轻记，一款专注于记账的软件',

        }
      });
      // ========== 主内容区域 ==========
      Scroll() {
        Column({ space: 0 }) {
          // 顶部占位空间（10%）
          Column()
            .height('20%')
            .width('100%')

          // 今日消费卡片
          Column() {
            Row() {
              Text('今日消费')
                .fontSize(16)
                .fontColor('#666666');
              Blank();
              Button('刷新')
                .fontSize(13)
                .fontColor('#007AFF')
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
                .padding({
                  left: 10,
                  right: 10,
                  top: 4,
                  bottom: 4
                })
                .onClick(() => {
                  this.updateData();
                  promptAction.showToast({ message: '已刷新今日数据' });
                });
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16 })

            Text('¥ ' + this.todaySpend.toFixed(2))
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#000000')
              .margin({ left: 20, top: 8, bottom: 8 });

            Row() {
              Text('较昨日')
                .fontSize(14)
                .fontColor('#666666');
              Text(this.yesterdayChange)
                .fontSize(14)
                .fontColor(this.yesterdayChange.includes('+') ? '#FF3B30' : '#34C759')
                .margin({ left: 6 });
            }
            .padding({ left: 20, right: 20, bottom: 16 });

            Row() {
              Column() {
                Text('支出')
                  .fontSize(14)
                  .fontColor('#666666');
                Text('¥ ' + this.expense.toFixed(2))
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FF3B30');
              }
              .flexGrow(1)
              .alignItems(HorizontalAlign.Center);

              Divider().vertical(true).height(32).color('#E5E5EA');

              Column() {
                Text('收入')
                  .fontSize(14)
                  .fontColor('#666666');
                Text('¥ ' + this.income.toFixed(2))
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#34C759');
              }
              .flexGrow(1)
              .alignItems(HorizontalAlign.Center);
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 20 });
          }
          .width('90%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({
            radius: 8,
            color: '#1A000000',
            offsetX: 0,
            offsetY: 2
          })
          .margin({ left: '5%', right: '5%' }) // 使用margin代替alignSelf实现居中

          // 欢迎语
          Column() {
            Text('欢迎使用轻记，您的每一次记录都将是美好的')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding(16);
          }
          .width('100%')

          // 中间到AI卡片之间的占位空间
          Column()
            .layoutWeight(1) // 再占据一部分空间
            .width('100%')
            .justifyContent(FlexAlign.End) // 对齐到底部

          // AI助手卡片（距离底部10%）
          Column({ space: 12 }) {
            // 上部分：AI助手卡片
            Row({ space: 16 }) {
              // 左侧图标
              Column()
                .width(50)
                .height(50)
                .backgroundImage($r('app.media.logo1'))
                .backgroundImageSize(ImageSize.Cover)
                .borderRadius(35) // 圆形
                .border({ width: 2, color: '#FFFFFF' })
                .shadow({
                  radius: 4,
                  color: '#00000010',
                  offsetX: 0,
                  offsetY: 2
                })

              // 中间文字
              Column({ space: 4 }) {
                Text('轻记AI助手')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#333333')

                Text('智能问答，快速解决记账问题')
                  .fontSize(10)
                  .fontColor('#666666')
              }
              .layoutWeight(1)

              // 右侧体验按钮
              Button('体验')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium)
                .backgroundColor('#FF5722')
                .borderRadius(16)
                .width(60)
                .height(32)
            }
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .border({ width: 1, color: '#F0F0F0' })
            .shadow({
              radius: 6,
              color: '#00000008',
              offsetX: 0,
              offsetY: 2
            })
            .onClick(() => {
              this.navigateToOtherPage();
            })

            // 下部分：提示信息
            Row() {
              Text('💡 小提示')
                .fontSize(14)
                .fontColor('#FF5722')
                .fontWeight(FontWeight.Medium)

              Text('试试AI助手，让记账更智能')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ left: 8 })
            }
            .margin({ left: '5%', right: '5%' })
          }
          .width('90%')
          .margin({ left: '5%', right: '5%', bottom: '10%' }) // 使用margin实现居中

          // 移除：原底部56px的占位空间（导航栏不再需要内部占位）
        }
        .width('100%')
        .height('100%')
      }
      // 关键修改1：将Scroll高度改为90%，和记账/我的页面完全一致
      .width('100%')
      .height('90%')
      .backgroundColor('#F5F5F5')
      .scrollBar(BarState.Off);

      // 底部导航栏（属性和层级与其他页面完全对齐）
      CommonTabBar({
        tabItems: this.tabItems,
        activeColor: '#FF5722',
        inactiveColor: '#999999'
      })
        .width('100%')
        //.height(56) // 固定56px高度，和其他页面一致
        .backgroundColor('#FFFFFF');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F7F7');
  }
}