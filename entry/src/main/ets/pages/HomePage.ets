import router from '@ohos.router';
import { RecordStore } from '../data/RecordStore';
import { DateUtils } from '../utils/DateUtils';
import { Record, TabItem, CategoryDistributionItem } from '../models/Record';
import { CommonNavBar } from '../components/CommonNavBar' // 导入顶部导航栏组件
import promptAction from '@ohos.promptAction';
import { CommonTabBar, DefaultTabItems } from '../components/CommonTabBar';


@Entry
@Component
export struct HomePage {


  // 1. 静态默认值（满足ArkTS规则）
  private recordStore: RecordStore | undefined = undefined;
  private timer: number | undefined = undefined;
  // 状态变量 - 静态默认值
  @State currentDate: string = '';
  @State todaySpend: number = 0;
  @State yesterdayChange: string = '0%';
  @State expense: number = 0;
  @State income: number = 0;
  @State categoryDistribution: CategoryDistributionItem[] = [];
  @State recentRecords: Record[] = [];
  // 底部Tab配置（替换为你的图标和页面路径）
  private tabItems: Array<TabItem> = DefaultTabItems;

  // 生命周期初始化
  async aboutToAppear(): Promise<void> {
    this.recordStore = RecordStore.getInstance();
    await this.recordStore.ready();
    this.currentDate = DateUtils.formatChineseDate(DateUtils.getCurrentDate());
    this.updateData();
  }

  // 组件销毁时清理定时器
  aboutToDisappear(): void {
    if (this.timer) {
      clearInterval(this.timer);
    }
  }

  // 数据更新方法（增加防御性检查）
  updateData(): void {
    if (!this.recordStore) {
      return;
    }
    this.todaySpend = this.recordStore.getTodayExpense();
    this.yesterdayChange = this.recordStore.getExpenseChangePercent();
    this.expense = this.recordStore.getTodayExpense();
    this.income = this.recordStore.getTodayIncome();
    this.categoryDistribution = this.recordStore.getTodayCategoryDistribution();
    this.recentRecords = this.recordStore.getRecentRecords(10);
  }

  // 获取分类名称（防御性检查）
  private getCategoryName(categoryId: string): string {
    if (!this.recordStore) {
      return '其他';
    }
    const category = this.recordStore.getCategoryById(categoryId);
    return category ? category.name : '其他';
  }

  // 跳转统计分析页面
  private goToStatisticPage(): void {
    try {
      router.pushUrl({ url: 'pages/StatisticPage' });
      console.log('跳转统计分析页面成功');
    } catch (e) {
      console.error('跳转统计分析页面失败：', e);
    }
  }

  // 跳转详细记录界面
  private goToDetailPage(): void {
    try {
      router.pushUrl({ url: 'pages/DetailPage' });
      console.log('跳转详细记录页面成功');
    } catch (e) {
      console.error('跳转详细记录页面失败：', e);
    }
  }

  build() {

    // 外层Column：顶部导航栏 + 主内容 + 底部导航栏（垂直布局）
    Column() {
      // 1. 顶部导航栏（CommonNavBar）
      CommonNavBar({

        options: {
          showBack: true,
          title: '首页',
          onLeftClick: () =>{
            router.replaceUrl({ url: 'pages/MainPage' })// 右侧按钮点击事件（可选）
          }}
      });
      // 2. 主内容区域（占满剩余高度，可滚动）
      this.MainContentArea();
      // ========== 底部导航栏（图片+跳转逻辑） ==========
      CommonTabBar({
        tabItems: this.tabItems,
        activeColor: '#FF5722', // 自定义选中态颜色
        inactiveColor: '#999999' // 自定义未选中态颜色
      })
        .width('100%')
        .height(56)
        .backgroundColor(Color.White);

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  MainContentArea() {
    // 可滚动主内容（原页面保留逻辑）
    Scroll() {
      Column({ space: 16 }) {
        // 今日消费概览卡片
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
          .margin({ top: 16, bottom: 8 })

          Text('¥ ' + this.todaySpend.toFixed(2))
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')
            .margin({ bottom: 8 })
          Row() {
            Text('较昨日')
              .fontSize(14)
              .fontColor('#666666')
            Text(this.yesterdayChange)
              .fontSize(14)
              .fontColor(this.yesterdayChange.includes('+') ? '#FF3B30' : '#34C759')
          }
          .margin({ bottom: 24 })

          // 支出与收入对比
          Row() {
            Column() {
              Text('支出')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              Text('¥ ' + this.expense.toFixed(2))
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF3B30')
            }
            .flexGrow(1)
            .alignItems(HorizontalAlign.Center)

            Divider()
              .vertical(true)
              .height(30)
              .color('#E5E5EA')
            Column() {
              Text('收入')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              Text('¥ ' + this.income.toFixed(2))
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#34C759')
            }
            .flexGrow(1)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding({ top: 16, bottom: 16 })
          .backgroundColor('#F9F9F9')
          .borderRadius(12)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .padding({ left: 20, right: 20 })
        .shadow({
          radius: 8,
          color: '#1A000000',
          offsetX: 0,
          offsetY: 2
        })

        // 消费分类分布卡片
        Column() {
          Row() {
            Text('消费分类分布')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#000000')
            Blank()
            if (this.categoryDistribution.length > 0) {
              Text('查看详情')
                .fontSize(14)
                .fontColor('#007AFF')
                .onClick(() => {
                  this.goToStatisticPage();
                })
            }
          }
          .width('100%')
          .padding({ top: 20, bottom: 16 })

          if (this.categoryDistribution.length === 0) {
            Column() {
              Text('暂无消费数据')
                .fontSize(16)
                .fontColor('#8E8E93')
              Text('点击下方按钮记一笔吧')
                .fontSize(14)
                .fontColor('#C7C7CC')
                .margin({ top: 4 })
            }
            .width('100%')
            .height(200)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            Column({ space: 12 }) {
              ForEach(this.categoryDistribution, (item: CategoryDistributionItem) => {
                Column({ space: 6 }) {
                  Row() {
                    Text(item.category.name)
                      .fontSize(15)
                      .fontColor('#000000')
                    Blank()
                    Text(item.percent.toFixed(0) + '%')
                      .fontSize(15)
                      .fontColor('#000000')
                  }

                  Row() {
                    Row()
                      .width(item.percent + '%')
                      .height(8)
                      .backgroundColor(item.category.color)
                      .borderRadius(4)
                  }
                  .width('100%')
                  .height(8)
                  .backgroundColor('#F2F2F7')
                  .borderRadius(4)

                  Text('¥ ' + item.amount.toFixed(2))
                    .fontSize(13)
                    .fontColor('#8E8E93')
                }
                .width('100%')
              })
            }
            .width('100%')
            .margin({ bottom: 20 })
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({
          radius: 8,
          color: '#1A000000',
          offsetX: 0,
          offsetY: 2
        })

        // 最近记录卡片
        // 最近记录卡片
        Column() {
          Row() {
            Text('最近记录')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#000000')
            Blank()
            if (this.recentRecords.length > 0) {
              Text('查看全部')
                .fontSize(14)
                .fontColor('#007AFF')
                .onClick(() => {
                  this.goToDetailPage();
                })
            }
          }
          .width('100%')
          .padding({ top: 20, bottom: 16 })

          if (this.recentRecords.length === 0) {
            Column() {
              Text('暂无记录')
                .fontSize(16)
                .fontColor('#8E8E93')
            }
            .width('100%')
            .height(150)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            Column({ space: 0 }) {
              ForEach(this.recentRecords, (record: Record, index) => {
                // 将分类信息获取移到这里
                //const category = this.recordStore.getCategoryById(record.category);

                Column() {
                  Row() {
                    Row() {
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
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                      // 背景颜色使用分类颜色，带有20%透明度
                      .backgroundColor(this.recordStore?.getCategoryById(record.category) ?
                        `${this.recordStore.getCategoryById(record.category).color}20` : '#F2F2F7')
                      .borderRadius(20)

                      Column() {
                        Text(record.description)
                          .fontSize(16)
                          .fontColor('#000000')
                        // 直接在UI表达式中获取分类名称
                        Text(`${this.recordStore?.getCategoryById(record.category)?.name || '未知分类'} • ${record.date === DateUtils.getCurrentDate() ? '今日' : '昨日'} ${record.time}`)
                          .fontSize(12)
                          .fontColor('#8E8E93')
                          .margin({ top: 2 })
                      }
                      .margin({ left: 12 })
                    }

                    Blank()
                    Text((record.type === 'expense' ? '- ' : '+ ') + '¥ ' + record.amount.toFixed(2))
                      .fontSize(18)
                      .fontColor(record.type === 'expense' ? '#FF3B30' : '#34C759')
                      .fontWeight(FontWeight.Medium)
                  }
                  .width('100%')
                  .padding({ top: 12, bottom: 12 })

                  if (index < this.recentRecords.length - 1) {
                    Divider()
                      .color('#F2F2F7')
                  }
                }
              }, (record: Record) => record.id) // 添加唯一标识
            }
            .width('100%')
            .margin({ bottom: 20 })
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({
          radius: 8,
          color: '#1A000000',
          offsetX: 0,
          offsetY: 2
        })
        .width('100%')
        .padding({ left: 20, right: 20 })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({
          radius: 8,
          color: '#1A000000',
          offsetX: 0,
          offsetY: 2
        })

        // 底部空白（避免内容被悬浮按钮遮挡）
        Row().height(100)
      }
      .width('100%')
      .flexGrow(1)
      .padding(16)
    }
    .width('100%')
    .height('90%')
    .scrollBar(BarState.Off)
  }
}