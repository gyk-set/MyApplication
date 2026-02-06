import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { RecordStore } from '../data/RecordStore';
import { DateUtils } from '../utils/DateUtils';
import { Record, Category, TabItem } from '../models/Record';
import { CommonNavBar } from '../components/CommonNavBar';
import { CommonTabBar, DefaultTabItems } from '../components/CommonTabBar';

interface RecordParams{
  recordId: string | number;
  refresh?: boolean,
  timestamp?: number
}

@Entry
@Component
struct DetailPage {
  private recordStore: RecordStore | undefined = undefined;
  @State currentIndex: number = 0;
  private tabItems: Array<TabItem> = DefaultTabItems;
  @State currentRecordId: string | number = '';
  @State currentRecord: Record | undefined = undefined;
  @State categoryInfo: Category | undefined = undefined;
  @State allRecords: Record[] = [];
  @State recentRecords: Record[] = [];
  @State foodExpenseTotal: number = 0;
  @State budgetTotal: number = 1000;
  @State showRecentRecords: boolean = false;
  @State refreshFlag: boolean = false;
  @State refreshTimestamp: number = 0;

  async aboutToAppear(): Promise<void> {
    this.recordStore = RecordStore.getInstance();
    await this.recordStore.ready();

    // 从路由参数获取记录ID
    const params = router.getParams() as RecordParams;

    if (params?.recordId) {
      this.currentRecordId = String(params.recordId);
      this.loadRecordData();
      this.showRecentRecords = false;
    } else {
      this.loadRecentRecords();
      this.showRecentRecords = true;
    }

    this.calculateFoodExpense();
  }

  // 加载单条记录数据
  loadRecordData(): void {
    if (!this.recordStore) {
      return;
    }

    // 每次都重新获取所有记录，确保数据是最新的
    const allRecords = this.recordStore.getAllRecords();
    const record = allRecords.find(r => r.id === this.currentRecordId);

    if (record) {
      this.currentRecord = record;
      this.categoryInfo = this.recordStore.getCategoryById(record.category);
      console.log('加载记录数据成功:', record.id, record.description);
    } else {
      console.log('记录不存在，可能已被删除:', this.currentRecordId);
      // 如果记录不存在，显示无记录
      this.currentRecord = undefined;
      this.categoryInfo = undefined;
    }
  }

  // 加载所有记录
  loadAllRecords(): void {
    if (!this.recordStore) {
      return;
    }
    this.allRecords = this.recordStore.getAllRecords();
  }

  // 加载最近记录
  loadRecentRecords(): void {
    if (!this.recordStore) {
      return;
    }
    this.recentRecords = this.recordStore.getRecentRecords(10);
  }

  // 选择一条记录查看详情
  selectRecord(record: Record): void {
    this.currentRecord = record;
    this.categoryInfo = this.recordStore!.getCategoryById(record.category);
    this.showRecentRecords = false;
  }

  // 返回最近记录列表
  backToRecentRecords(): void {
    this.showRecentRecords = true;
    this.currentRecord = undefined;
    this.categoryInfo = undefined;
  }

  calculateFoodExpense(): void {
    if (!this.recordStore) {
      return;
    }

    const allRecords = this.recordStore.getAllRecords();
    const currentMonth = new Date().getMonth() + 1;

    let foodTotal = 0;
    allRecords.forEach(record => {
      if (record.type === 'expense' && record.category === 'food') {
        try {
          const GeneratedDestructArray_1 = record.date.split('-').map(Number);
          const year = GeneratedDestructArray_1[0];
          const month = GeneratedDestructArray_1[1];
          const day = GeneratedDestructArray_1[2];
          if (month === currentMonth) {
            foodTotal += record.amount;
          }
        } catch (e) {
          // 日期解析失败，跳过该记录
        }
      }
    });

    this.foodExpenseTotal = foodTotal;
  }

  private goBack(): void {
    router.back();
  }

  // 编辑记录 - 跳转到编辑页面
  private editRecord(): void {
    if (this.currentRecord) {
      console.log('编辑记录:', this.currentRecord.id);
      // 跳转到编辑页面，传递记录ID
      router.pushUrl({
        url: 'pages/EditPage', // 编辑页面的路径
        params: {
          recordId: this.currentRecord.id
        }
      });
    }
  }

  // 删除记录
  private async deleteRecord(): Promise<void> {
    if (!this.currentRecord || !this.recordStore) {
      return;
    }

    // 显示确认对话框
    try {
      const result = await promptAction.showDialog({
        title: '确认删除',
        message: `确定要删除"${this.currentRecord.description}"这条记录吗？`,
        buttons: [
          {
            text: '取消',
            color: '#666666'
          },
          {
            text: '删除',
            color: '#FF3B30'
          }
        ]
      });

      if (result.index === 1) { // 用户点击了"删除"按钮
        const success = await this.recordStore.deleteRecord(this.currentRecord.id);
        if (success) {
          promptAction.showToast({ message: '删除成功', duration: 2000 });

          if (this.showRecentRecords) {
            this.loadRecentRecords();
          } else {
            this.loadRecentRecords();
            this.backToRecentRecords();
          }
        } else {
          promptAction.showToast({ message: '删除失败', duration: 2000 });
        }
      }
    } catch (error) {
      console.error('删除记录时出错:', error);
    }
  }

  private getFormattedDate(): string {
    if (!this.currentRecord) {
      return '';
    }

    if (this.currentRecord.date === DateUtils.getCurrentDate()) {
      return '今天 ' + this.currentRecord.time;
    } else if (this.currentRecord.date === DateUtils.getYesterdayDate()) {
      return '昨天 ' + this.currentRecord.time;
    } else {
      return this.currentRecord.date + ' ' + this.currentRecord.time;
    }
  }

  // 获取分类颜色
  private getCategoryColor(categoryId: string): string {
    if (!this.recordStore) return '#CCCCCC';
    const category = this.recordStore.getCategoryById(categoryId);
    return category?.color || '#CCCCCC';
  }

  // 获取分类名称
  private getCategoryName(categoryId: string): string {
    if (!this.recordStore) return '未知';
    const category = this.recordStore.getCategoryById(categoryId);
    return category?.name || '未知';
  }

  // 格式化金额显示
  private formatAmount(amount: number, type: string): string {
    const prefix = type === 'expense' ? '-￥' : '+￥';
    return prefix + amount.toFixed(2);
  }

  build() {
    Column() {
      // 顶部导航栏
      CommonNavBar({
        options: {
          showBack: true,
          onLeftClick: () =>{
            router.replaceUrl({ url: 'pages/HomePage' })// 右侧按钮点击事件（可选）
          },
          title: this.showRecentRecords ? '最近记录' : '详细记录',
        }
      });

      // 主要内容区域
      Scroll() {
        Column({ space: 24 }) {
          if (this.showRecentRecords) {
            // 显示最近记录列表
            if (this.recentRecords.length > 0) {
              Column({ space: 12 }) {
                Text('最近记录')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#000000')
                  .margin({ left: 8, top: 8, bottom: 8 })

                ForEach(this.recentRecords, (record: Record) => {
                  Column() {
                    Row({ space: 12 }) {
                      // 圆形图标容器
                      Column() {
                        // 显示分类图标
                        // 显示分类图标
                        Image($r(`app.media.category_${this.recordStore?.getCategoryById(record.category)?.icon}`))
                          .width(24)
                          .height(24)
                          .objectFit(ImageFit.Contain)
                      }
                      .width(40)
                      .height(40)
                      .backgroundColor(`${this.getCategoryColor(record.category)}20`)
                      .borderRadius(20)
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)

                      // 记录信息
                      Column({ space: 4 }) {
                        Row() {
                          Text(record.description || '无描述')
                            .fontSize(16)
                            .fontColor('#000000')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })

                          Blank()

                          Text(this.formatAmount(record.amount, record.type))
                            .fontSize(16)
                            .fontColor(record.type === 'expense' ? '#FF3B30' : '#34C759')
                            .fontWeight(FontWeight.Medium)
                        }
                        .width('100%')
                        .height(24)

                        // 第二行：分类和时间
                        Row() {
                          Text(this.getCategoryName(record.category))
                            .fontSize(14)
                            .fontColor('#666666')

                          Text(' · ')
                            .fontSize(14)
                            .fontColor('#666666')

                          Text(record.date + ' ' + record.time)
                            .fontSize(14)
                            .fontColor('#666666')
                        }
                        .width('100%')
                        .height(20)
                      }
                      .layoutWeight(1)
                      .justifyContent(FlexAlign.SpaceBetween)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                    .backgroundColor('#FFFFFF')
                    .borderRadius(12)
                    .onClick(() => {
                      this.selectRecord(record);
                    })
                  }
                  .width('100%')
                })
              }
              .width('100%')
            } else {
              // 没有记录时的显示
              Column() {
                Image($r('app.media.background'))
                  .width(120)
                  .height(120)
                  .margin({ bottom: 20 })
                Text('暂无记录')
                  .fontSize(18)
                  .fontColor('#8E8E93')
                  .margin({ bottom: 8 })
                Text('点击首页的"+"按钮添加记录')
                  .fontSize(14)
                  .fontColor('#999999')
              }
              .width('100%')
              .height(400)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            }
          } else if (this.currentRecord) {
            // 显示单条记录详情
            Column({ space: 24 }) {
              // 金额显示
              Column() {
                Text(this.formatAmount(this.currentRecord.amount, this.currentRecord.type))
                  .fontSize(40)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.currentRecord.type === 'expense' ? '#FF3B30' : '#34C759')

                Text(this.currentRecord.description || '无描述')
                  .fontSize(18)
                  .fontColor('#666666')
                  .margin({ top: 8 })
              }
              .width('100%')
              .padding({ top: 32, bottom: 32 })
              .backgroundColor('#FFFFFF')
              .alignItems(HorizontalAlign.Center)

              // 详细信息卡片
              Column({ space: 16 }) {
                Text('详细信息')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#000000')
                  .margin({ left: 20, top: 20 })

                // 分类
                Row() {
                  Text('分类：')
                    .fontSize(16)
                    .fontColor('#666666')
                    .width(100)

                  if (this.categoryInfo) {
                    Row() {
                      Circle({ width: 8, height: 8 })
                        .fill(this.categoryInfo.color)
                        .margin({ right: 8 })

                      Text(this.categoryInfo.name)
                        .fontSize(16)
                        .fontColor('#000000')
                    }
                  }
                }
                .width('100%')
                .padding({ left: 20, right: 20 })

                // 时间
                Row() {
                  Text('时间：')
                    .fontSize(16)
                    .fontColor('#666666')
                    .width(100)

                  Text(this.getFormattedDate())
                    .fontSize(16)
                    .fontColor('#000000')
                }
                .width('100%')
                .padding({ left: 20, right: 20 })

                // 类型
                Row() {
                  Text('类型：')
                    .fontSize(16)
                    .fontColor('#666666')
                    .width(100)

                  Text(this.currentRecord.type === 'expense' ? '支出' : '收入')
                    .fontSize(16)
                    .fontColor(this.currentRecord.type === 'expense' ? '#FF3B30' : '#34C759')
                }
                .width('100%')
                .padding({ left: 20, right: 20 })

                // 记录ID（用于调试）
                Row() {
                  Text('记录ID：')
                    .fontSize(16)
                    .fontColor('#666666')
                    .width(100)

                  Text(this.currentRecord.id)
                    .fontSize(16)
                    .fontColor('#999999')
                }
                .width('100%')
                .padding({ left: 20, right: 20 })
              }
              .width('100%')
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .shadow({
                radius: 8,
                color: '#1A000000',
                offsetX: 0,
                offsetY: 2
              })

              // 预算信息卡片（仅餐饮分类显示）
              if (this.currentRecord.type === 'expense' && this.currentRecord.category === 'food') {
                Column() {
                  Text('本月餐饮已消费 ¥' + this.foodExpenseTotal.toFixed(2))
                    .fontSize(16)
                    .fontColor('#000000')

                  Text('预算剩余 ¥' + (this.budgetTotal - this.foodExpenseTotal).toFixed(2))
                    .fontSize(16)
                    .fontColor('#34C759')
                    .fontWeight(FontWeight.Medium)
                    .margin({ top: 4 })
                }
                .width('100%')
                .padding({ top: 16, bottom: 16 })
                .backgroundColor('#F2F2F7')
                .borderRadius(12)
                .alignItems(HorizontalAlign.Center)
              }

              // 操作按钮
              Row({ space: 16 }) {
                Button('编辑')
                  .fontSize(16)
                  .fontColor('#007AFF')
                  .backgroundColor('#FFFFFF')
                  .borderColor('#007AFF')
                  .borderWidth(1)
                  .borderRadius(8)
                  .width('45%')
                  .height(48)
                  .onClick(() => {
                    this.editRecord();
                  })

                Button('删除')
                  .fontSize(16)
                  .fontColor('#FF3B30')
                  .backgroundColor('#FFFFFF')
                  .borderColor('#FF3B30')
                  .borderWidth(1)
                  .borderRadius(8)
                  .width('45%')
                  .height(48)
                  .onClick(() => {
                    this.deleteRecord();
                  })
              }
              .width('100%')
              .padding({ bottom: 32 })
            }
          } else {
            // 没有记录时的显示
            Column() {
              Image($r('app.media.background'))
                .width(120)
                .height(120)
                .margin({ bottom: 20 })
              Text('无记录数据')
                .fontSize(18)
                .fontColor('#8E8E93')
                .margin({ bottom: 20 })

              Button('返回')
                .fontSize(16)
                .fontColor('#007AFF')
                .backgroundColor('#FFFFFF')
                .borderColor('#007AFF')
                .borderWidth(1)
                .borderRadius(8)
                .width(120)
                .height(48)
                .onClick(() => {
                  this.goBack();
                })
            }
            .width('100%')
            .height(400)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }
        }
        .width('100%')
        .padding(20)
      }
      .width('100%')
      .height('90%')
      .backgroundColor('#F2F2F7')
      .scrollBar(BarState.Off)

      // 底部导航栏
      CommonTabBar({
        tabItems: this.tabItems,
        activeColor: '#FF5722',
        inactiveColor: '#999999'
      })
        .width('100%')
        .height(56)
        .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}