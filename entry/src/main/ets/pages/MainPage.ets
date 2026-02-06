import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { RecordStore } from '../data/RecordStore';
import { DateUtils } from '../utils/DateUtils';
import { TabItem } from '../models/Record'
import { CommonTabBar, DefaultTabItems } from '../components/CommonTabBar';



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

  build() {
    Column() {
      // ========== 主内容区域：今日消费卡片 + 欢迎语 ==========
      Scroll() {
        Column({ space: 16 }) {
          // 今日消费卡片（简版）
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
                  .fontWeight(FontWeight.Bold)
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
          .margin({ top: 20, left: '5%', right: '5%' });

          // 欢迎语
          Column() {
            Text('欢迎使用轻记，您的每一次记录都将是美好的')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding(16);
          }
          .width('100%')
          .padding({ top: 8, bottom: 24 });
        }
        .width('100%')
      }
      .width('100%')
      .height('95%')
      .backgroundColor('#F5F5F5')
      .scrollBar(BarState.Off);

      CommonTabBar({
        tabItems: this.tabItems,
        activeColor: '#FF5722', // 自定义选中态颜色
        inactiveColor: '#999999' // 自定义未选中态颜色
      }).width('100%')
        .height(56)
        .backgroundColor('#FFFFFF');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}

