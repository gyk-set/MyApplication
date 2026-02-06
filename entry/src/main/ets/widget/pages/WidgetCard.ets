import {RecordStore} from "../../data/RecordStore"
import {CategoryDistributionItem} from "../../models/Record"
import { DateUtils } from '../../utils/DateUtils';


@Entry
@Component
struct WidgetCard {

  // 标题和基础配置
  readonly title: string = '消费概览';
  readonly actionType: string = 'router';
  readonly abilityName: string = 'EntryAbility';
  readonly message: string = '查看详情';
  readonly fullWidthPercent: string = '100%';
  readonly fullHeightPercent: string = '100%';

  // 数据管理器实例
  private recordStore: RecordStore = RecordStore.getInstance();

  // 响应式数据

  @State todaySpend: number = 0;
  @State yesterdayChange: string = '0%';
  @State expense: number = 0;
  @State income: number = 0;
  @State isRefreshing: boolean = false;
  @State todayDistribution: CategoryDistributionItem[] = [];
  @State todayIncome: number = 0;
  @State currentDate: string = '';
  // 数据变更监听回调（用于销毁时取消监听）
  private dataChangeListener: () => void = () => {};
  // 数据变更监听回调
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
      // 今日消费概览卡片
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
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .padding({ left: 20, right: 20, bottom: 20 })
      .margin({ left: 16, right: 16, top: 16, bottom: 16 })
      .shadow({
        radius: 12,
        color: '#10000000',
        offsetX: 0,
        offsetY: 4
      })
    }
    .width(this.fullWidthPercent)
    .height(this.fullHeightPercent)
    .backgroundColor('#F5F5F7')
    .onClick(() => {
      // 保留原来的点击事件
      postCardAction(this, {
        action: this.actionType,
        abilityName: this.abilityName,
        params: {
          message: this.message
        }
      });
    })
  }
}