import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { RecordStore } from '../data/RecordStore';
import { CategoryItem, ConsumptionRanking, MonthlyTrend, Record, Category, TabItem } from '../models/Record';
import { CommonTabBar, DefaultTabItems } from '../components/CommonTabBar';
import { CommonNavBar } from '../components/CommonNavBar'


interface Month {year: number, month: number, label: string}

interface availableMonths {year: number, month: number, label: string}
// 创建全局上下文实例
const pieCanvasContext = new CanvasRenderingContext2D();
const barCanvasContext = new CanvasRenderingContext2D();

@Entry
@Component
struct StatisticPage {
  // 使用普通属性而不是@State
  private pieCtx: CanvasRenderingContext2D = pieCanvasContext;
  private barCtx: CanvasRenderingContext2D = barCanvasContext;

  private recordStore: RecordStore | undefined = undefined;

  // 底部导航配置
  @State currentIndex: number = 0;
  private tabItems: Array<TabItem> = DefaultTabItems;

  // 数据状态
  @State currentMonth: string = '本月';
  @State income: number = 0;
  @State expense: number = 0;
  @State balance: number = 0;
  @State categoryData: Array<CategoryItem> = [];
  @State monthlyTrend: Array<MonthlyTrend> = [];
  @State consumptionRanking: Array<ConsumptionRanking> = [];

  // 月份选择器相关状态
  @State showMonthPicker: boolean = false;
  @State selectedYear: number = new Date().getFullYear();
  @State selectedMonth: number = new Date().getMonth() + 1;
  @State availableMonths: Array<availableMonths> = [];

  async aboutToAppear(): Promise<void> {
    this.recordStore = RecordStore.getInstance();
    await this.recordStore.ready();
    this.initAvailableMonths();
    this.updateStatisticData();
  }

  initAvailableMonths(): void {
    const currentDate = new Date();
    const currentYear = currentDate.getFullYear();
    const currentMonth = currentDate.getMonth() + 1;

    const months: Array<Month> = [];

    for (let i = 5; i >= 0; i--) {
      const date = new Date(currentYear, currentMonth - 1 - i);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;

      months.push({
        year: year,
        month: month,
        label: `${year}年${month}月`
      });
    }

    this.availableMonths = months;
    this.selectedYear = currentYear;
    this.selectedMonth = currentMonth;
    this.currentMonth = `${currentMonth}月`;
  }

  updateStatisticData(): void {
    console.log(`更新统计数据，月份: ${this.selectedYear}年${this.selectedMonth}月`);

    if (!this.recordStore) {
      console.error('RecordStore未初始化');
      return;
    }

    try {
      // 获取当前选中月份的记录（注意：getRecordsByMonth的月份参数是0-11）
      const monthRecords = this.recordStore.getRecordsByMonth(this.selectedYear, this.selectedMonth - 1);

      console.log(`找到${monthRecords.length}条记录`);

      // 计算收入、支出和结余
      let totalIncome = 0;
      let totalExpense = 0;

      monthRecords.forEach((record: Record) => {
        if (record.type === 'income') {
          totalIncome += record.amount;
        } else {
          totalExpense += record.amount;
        }
      });

      this.income = totalIncome;
      this.expense = totalExpense;
      this.balance = totalIncome - totalExpense;

      console.log(`收入: ${this.income}, 支出: ${this.expense}, 结余: ${this.balance}`);

      // 计算分类数据
      this.calculateCategoryData(monthRecords);

      // 计算月度趋势（按天统计）
      this.calculateMonthlyTrend(monthRecords);

      // 计算消费排行榜
      this.calculateConsumptionRanking(monthRecords);

      // 延迟绘制图表，确保Canvas已准备好
      setTimeout(() => {
        this.drawPieChartContent();
        this.drawBarChartContent();
      }, 100);

    } catch (error) {
      console.error('更新统计数据失败:', error);
    }
  }

  calculateCategoryData(records: Record[]): void {
    const expenseRecords = records.filter(r => r.type === 'expense');
    const categoryMap = new Map<string, number>();

    expenseRecords.forEach((record: Record) => {
      const category = this.recordStore!.getCategoryById(record.category);
      const current = categoryMap.get(category.id) || 0;
      categoryMap.set(category.id, current + record.amount);
    });

    const totalExpense = this.expense;
    const categoryArray: Array<CategoryItem> = [];

    categoryMap.forEach((amount: number, categoryId: string) => {
      const category = this.recordStore!.getCategoryById(categoryId);
      const percent = totalExpense > 0 ? (amount / totalExpense) * 100 : 0;

      const categoryItem: CategoryItem = {
        name: category.name,
        amount: amount,
        percent: percent,
        color: category.color
      };
      categoryArray.push(categoryItem);
    });

    categoryArray.sort((a: CategoryItem, b: CategoryItem) => b.amount - a.amount);
    this.categoryData = categoryArray;
  }

  calculateMonthlyTrend(records: Record[]): void {
    const daysInMonth = new Date(this.selectedYear, this.selectedMonth, 0).getDate();
    const trendData: MonthlyTrend[] = [];

    const dailyExpense: Map<number, number> = new Map();
    const expenseRecords = records.filter(r => r.type === 'expense');

    expenseRecords.forEach((record: Record) => {
      const parts = record.date.split('-');
      if (parts.length === 3) {
        const day = parseInt(parts[2]);
        if (!isNaN(day) && day >= 1 && day <= daysInMonth) {
          dailyExpense[day] = (dailyExpense[day] || 0) + record.amount;
        }
      }
    });

    for (let day = 1; day <= daysInMonth; day++) {
      trendData.push({
        day: `${day}日`,
        amount: dailyExpense[day] || 0,
        month: '',
        expense: 0,
        income: 0,
        balance: 0
      });
    }

    this.monthlyTrend = trendData;
  }

  calculateConsumptionRanking(records: Record[]): void {
    const categoryMap = new Map<string, number>();
    const expenseRecords = records.filter(r => r.type === 'expense');

    expenseRecords.forEach((record: Record) => {
      const current = categoryMap.get(record.category) || 0;
      categoryMap.set(record.category, current + record.amount);
    });

    const ranking: ConsumptionRanking[] = [];
    categoryMap.forEach((amount: number, categoryId: string) => {
      const category = this.recordStore!.getCategoryById(categoryId);
      const rankingItem: ConsumptionRanking = {
        category: category.name,
        amount: amount
      };
      ranking.push(rankingItem);
    });

    ranking.sort((a: ConsumptionRanking, b: ConsumptionRanking) => b.amount - a.amount);
    this.consumptionRanking = ranking;
  }

  // 辅助方法：将十六进制颜色字符串转换为rgba
  private hexToRgba(hex: string, alpha: number = 1): string {
    hex = hex.replace('#', '');

    if (hex.length === 3) {
      hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
    }

    if (hex.length === 6) {
      const r = parseInt(hex.substring(0, 2), 16);
      const g = parseInt(hex.substring(2, 4), 16);
      const b = parseInt(hex.substring(4, 6), 16);

      return `rgba(${r}, ${g}, ${b}, ${alpha})`;
    }

    return 'rgba(0, 0, 255, 1)';
  }

  // 绘制环形图
  @Builder
  drawPieChart() {
    Canvas(this.pieCtx)
      .width(240)
      .height(240)
      .backgroundColor('transparent')
      .onReady(() => {
        this.drawPieChartContent();
      })
  }

  private drawPieChartContent(): void {
    const ctx = this.pieCtx;
    if (!ctx) return;

    ctx.clearRect(0, 0, 240, 240);

    if (this.categoryData.length === 0 || this.expense === 0) {
      ctx.beginPath();
      ctx.arc(120, 120, 40, 0, Math.PI * 2);
      ctx.fillStyle = '#F2F2F7';
      ctx.fill();

      ctx.font = '14px sans-serif';
      ctx.fillStyle = '#8E8E93';
      ctx.textAlign = 'center';
      ctx.fillText('暂无数据', 120, 120);
      return;
    }

    let startAngle: number = -Math.PI / 2;
    const centerX = 120;
    const centerY = 120;
    const radius = 90;
    const holeRadius = 30;

    this.categoryData.forEach((item: CategoryItem) => {
      const angle: number = (item.percent / 100) * Math.PI * 2;
      const endAngle: number = startAngle + angle;

      ctx.beginPath();
      ctx.moveTo(centerX, centerY);
      ctx.arc(centerX, centerY, radius, startAngle, endAngle);
      ctx.closePath();
      ctx.fillStyle = this.hexToRgba(item.color);
      ctx.fill();

      startAngle = endAngle;
    });

    ctx.beginPath();
    ctx.arc(centerX, centerY, holeRadius, 0, Math.PI * 2);
    ctx.fillStyle = '#FFFFFF';
    ctx.fill();

    ctx.font = '16px sans-serif';
    ctx.fillStyle = '#000000';
    ctx.textAlign = 'center';
    ctx.fillText('¥' + this.expense.toFixed(0), centerX, centerY - 8);

    ctx.font = '12px sans-serif';
    ctx.fillStyle = '#666666';
    ctx.fillText('总支出', centerX, centerY + 12);
  }

  // 绘制柱状图
  @Builder
  drawBarChart() {
    Canvas(this.barCtx)
      .width('100%')
      .height(200)
      .backgroundColor('transparent')
      .onReady(() => {
        this.drawBarChartContent();
      })
  }

  private drawBarChartContent(): void {
    const ctx = this.barCtx;
    if (!ctx) return;

    const canvasWidth = 320;
    const canvasHeight = 200;

    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    if (this.monthlyTrend.length === 0) {
      ctx.font = '16px sans-serif';
      ctx.fillStyle = '#8E8E93';
      ctx.textAlign = 'center';
      ctx.fillText('暂无趋势数据', canvasWidth / 2, canvasHeight / 2);
      return;
    }

    const maxValue: number = Math.max(...this.monthlyTrend.map(item => item.amount));
    const scale = maxValue > 0 ? maxValue : 1;

    const barCount = Math.min(this.monthlyTrend.length, 15);
    const barWidth = (canvasWidth - 40) / barCount * 0.7;
    const gap = (canvasWidth - 40) / barCount * 0.3;
    const startX = 30;
    const baseY = canvasHeight - 40;

    ctx.beginPath();
    ctx.moveTo(20, 20);
    ctx.lineTo(20, baseY);
    ctx.lineTo(canvasWidth - 20, baseY);
    ctx.strokeStyle = '#CCCCCC';
    ctx.lineWidth = 1;
    ctx.stroke();

    const ySteps = 5;
    for (let i = 0; i <= ySteps; i++) {
      const y = 20 + (baseY - 20) * (ySteps - i) / ySteps;
      const value = (scale * i / ySteps).toFixed(0);

      ctx.beginPath();
      ctx.moveTo(15, y);
      ctx.lineTo(20, y);
      ctx.strokeStyle = '#CCCCCC';
      ctx.stroke();

      ctx.font = '10px sans-serif';
      ctx.fillStyle = '#666666';
      ctx.textAlign = 'right';
      ctx.fillText(`¥${value}`, 13, y + 3);
    }

    for (let i = 0; i < barCount; i++) {
      const item = this.monthlyTrend[i];
      const x = startX + i * (barWidth + gap);
      const height = (item.amount / scale) * (baseY - 40);
      const y = baseY - height;

      ctx.beginPath();
      ctx.rect(x, y, barWidth, height);
      ctx.fillStyle = '#3F7DFF';
      ctx.fill();

      if (item.amount > 0) {
        ctx.font = '10px sans-serif';
        ctx.fillStyle = '#000000';
        ctx.textAlign = 'center';
        ctx.fillText(`¥${item.amount.toFixed(0)}`, x + barWidth / 2, y - 5);
      }

      if (i % 3 === 0 || i === barCount - 1) {
        ctx.font = '10px sans-serif';
        ctx.fillStyle = '#666666';
        ctx.textAlign = 'center';
        ctx.fillText(item.day, x + barWidth / 2, baseY + 15);
      }
    }
  }

  // 月份选择处理
  onMonthSelect(year: number, month: number): void {
    this.selectedYear = year;
    this.selectedMonth = month;
    this.currentMonth = `${month}月`;
    this.showMonthPicker = false;
    // 重置数据状态，触发UI更新
    this.income = 0;
    this.expense = 0;
    this.balance = 0;
    this.categoryData = [];
    this.monthlyTrend = [];
    this.consumptionRanking = [];

    // 更新统计数据
    this.updateStatisticData();
  }

  // 月份选择器弹窗
  @Builder
  monthPickerDialog() {
    Column({ space: 0 }) {
      Row() {
        Text('选择月份')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
          .flexGrow(1)
          .textAlign(TextAlign.Center)

        Text('✕')
          .fontSize(20)
          .fontColor('#666666')
          .onClick(() => {
            this.showMonthPicker = false;
          })
      }
      .padding({ top: 16, bottom: 16, left: 20, right: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })

      Scroll() {
        Column({ space: 0 }) {
          ForEach(this.availableMonths, (item: Month) => {
            Row() {
              Text(item.label)
                .fontSize(16)
                .fontColor('#000000')
                .flexGrow(1)

              if (item.year === this.selectedYear && item.month === this.selectedMonth) {
                Text('✓')
                  .fontSize(18)
                  .fontColor('#007AFF')
              }
            }
            .padding({ top: 16, bottom: 16, left: 20, right: 20 })
            .backgroundColor('#FFFFFF')
            .onClick(() => {
              this.onMonthSelect(item.year, item.month);
            })

            Divider()
              .color('#F2F2F7')
              .margin({ left: 20 })
          })
        }
      }
      .height(300)
    }
    .width('80%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 20,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  private exportData(): void {
    console.log('导出数据');
    promptAction.showToast({
      message: '数据导出成功',
      duration: 2000
    });
  }

  private copyData(): void {
    const dataStr = `收入: ¥${this.income}\n支出: ¥${this.expense}\n结余: ¥${this.balance}`;
    console.log('复制数据:', dataStr);
    promptAction.showToast({
      message: '数据已复制',
      duration: 2000
    });
  }

  build() {
    Column() {
      // 顶部标题栏
      CommonNavBar({

        options: {
          showBack: true,
          onLeftClick: () =>{
            router.replaceUrl({ url: 'pages/HomePage' })// 右侧按钮点击事件（可选）
          },
          title: '数据统计',
          rightText: '月份', // 右侧文本按钮内容（可选）
          onRightClick: () =>{
            this.showMonthPicker = true;
          }}
      });

      Scroll() {
        Column({ space: 20 }) {
          // 收支概览卡片
          Column() {
            Text('收支概览')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#000000')
              .margin({ top: 20, left: 20 })

            Row() {
              Column({ space: 8 }) {
                Text('收入')
                  .fontSize(14)
                  .fontColor('#666666')
                Text('¥' + this.income.toFixed(2))
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#34C759')
              }
              .flexGrow(1)
              .alignItems(HorizontalAlign.Center)

              Column({ space: 8 }) {
                Text('支出')
                  .fontSize(14)
                  .fontColor('#666666')
                Text('¥' + this.expense.toFixed(2))
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FF3B30')
              }
              .flexGrow(1)
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')
            .padding({ top: 20, bottom: 20 })

            Column() {
              Text('结余')
                .fontSize(14)
                .fontColor('#666666')
              Text('¥' + this.balance.toFixed(2))
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.balance >= 0 ? '#34C759' : '#FF3B30')
            }
            .width('100%')
            .padding({ bottom: 20 })
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({
            radius: 8,
            color: '#1A000000',
            offsetX: 0,
            offsetY: 2
          })

          // 支出分类环形图卡片
          Column() {
            Text('支出分类环形图')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#000000')
              .margin({ top: 20, left: 20 })

            Row() {
              this.drawPieChart()
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 20, bottom: 20 })

            if (this.categoryData.length > 0) {
              Column({ space: 12 }) {
                ForEach(this.categoryData.slice(0, 4), (item: CategoryItem) => {
                  Row() {
                    Circle({ width: 12, height: 12 })
                      .fill(item.color)
                      .margin({ right: 8 })

                    Text(item.name)
                      .fontSize(14)
                      .fontColor('#000000')
                      .flexGrow(1)

                    Text(item.percent.toFixed(1) + '%')
                      .fontSize(14)
                      .fontColor('#000000')
                      .margin({ right: 8 })

                    Text('¥' + item.amount.toFixed(2))
                      .fontSize(14)
                      .fontColor('#000000')
                      .fontWeight(FontWeight.Medium)
                  }
                  .width('85%')
                })
              }
              .width('100%')
              .padding({ bottom: 20 })
              .alignItems(HorizontalAlign.Center)
            }
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({
            radius: 8,
            color: '#1A000000',
            offsetX: 0,
            offsetY: 2
          })

          // 月度趋势卡片
          Column() {
            Text('月度趋势')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#000000')
              .margin({ top: 20, left: 20 })

            Text(`${this.selectedYear}年${this.selectedMonth}月支出趋势`)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 12, left: 20 })

            Column() {
              this.drawBarChart()
            }
            .width('100%')
            .height(200)
            .padding({ left: 10, right: 10 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({
            radius: 8,
            color: '#1A000000',
            offsetX: 0,
            offsetY: 2
          })

          if (this.consumptionRanking.length > 0) {
            Column() {
              Text('消费排行榜')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#000000')
                .margin({ top: 20, left: 20 })

              Column() {
                ForEach(this.consumptionRanking.slice(0, 5), (item: ConsumptionRanking, index: number) => {
                  Row() {
                    Text((index + 1).toString() + '.')
                      .fontSize(16)
                      .fontColor(index < 3 ? '#FF3B30' : '#666666')
                      .width(40)

                    Text(item.category)
                      .fontSize(16)
                      .fontColor('#000000')
                      .flexGrow(1)

                    Text('¥' + item.amount.toFixed(2))
                      .fontSize(16)
                      .fontColor('#000000')
                      .fontWeight(FontWeight.Medium)
                  }
                  .width('100%')
                  .padding({ top: 16, bottom: 16, left: 20, right: 20 })

                  if (index < Math.min(4, this.consumptionRanking.length - 1)) {
                    Divider()
                      .color('#F2F2F7')
                      .margin({ left: 20, right: 20 })
                  }
                })
              }

              Row({ space: 12 }) {
                Button('复制')
                  .fontSize(14)
                  .fontColor('#007AFF')
                  .backgroundColor('#FFFFFF')
                  .borderColor('#007AFF')
                  .borderWidth(1)
                  .borderRadius(8)
                  .flexGrow(1)
                  .height(40)
                  .onClick(() => {
                    this.copyData();
                  })

                Button('下载')
                  .fontSize(14)
                  .fontColor('#007AFF')
                  .backgroundColor('#FFFFFF')
                  .borderColor('#007AFF')
                  .borderWidth(1)
                  .borderRadius(8)
                  .flexGrow(1)
                  .height(40)
                  .onClick(() => {
                    this.exportData();
                  })
              }
              .width('100%')
              .padding({ top: 16, bottom: 20, left: 20, right: 20 })
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({
              radius: 8,
              color: '#1A000000',
              offsetX: 0,
              offsetY: 2
            })
          }
        }
        .width('100%')
        .padding(20)
      }
      .width('100%')
      .height('90%')
      .backgroundColor('#F2F2F7')
      .scrollBar(BarState.Off)

      CommonTabBar({
        tabItems: this.tabItems,
        activeColor: '#FF5722',
        inactiveColor: '#999999'
      })
        .width('100%')
        .height(56)
        .backgroundColor('#FFFFFF');

      if (this.showMonthPicker) {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#1A000000')
            .onClick(() => {
              this.showMonthPicker = false;
            })

          this.monthPickerDialog()
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}