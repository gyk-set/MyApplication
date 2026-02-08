import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import pasteboard from '@ohos.pasteboard';
import { RecordStore } from '../data/RecordStore';
import { CategoryItem, ConsumptionRanking, MonthlyTrend, Record, TabItem } from '../models/Record';
import { CommonTabBar, DefaultTabItems } from '../components/CommonTabBar';
import { CommonNavBar } from '../components/CommonNavBar';
import { componentSnapshot } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fs from '@ohos.file.fs';
import { fileUri } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

interface Month {
  year: number;
  month: number;
  label: string;
}

interface AvailableMonths {
  year: number;
  month: number;
  label: string;
}

const pieCanvasContext = new CanvasRenderingContext2D();
const barCanvasContext = new CanvasRenderingContext2D();

@Entry
@Component
struct StatisticPage {
  private pieCtx: CanvasRenderingContext2D = pieCanvasContext;
  private barCtx: CanvasRenderingContext2D = barCanvasContext;
  private recordStore: RecordStore | undefined = undefined;

  @State currentIndex: number = 0;
  private tabItems: Array<TabItem> = DefaultTabItems;

  @State currentMonth: string = '本月';
  @State income: number = 0;
  @State expense: number = 0;
  @State balance: number = 0;
  @State categoryData: Array<CategoryItem> = [];
  @State monthlyTrend: Array<MonthlyTrend> = [];
  @State consumptionRanking: Array<ConsumptionRanking> = [];

  @State showMonthPicker: boolean = false;
  @State selectedYear: number = new Date().getFullYear();
  @State selectedMonth: number = new Date().getMonth() + 1;
  @State availableMonths: Array<AvailableMonths> = [];

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
    if (!this.recordStore) return;

    try {
      const monthRecords = this.recordStore.getRecordsByMonth(this.selectedYear, this.selectedMonth - 1);
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
      this.calculateCategoryData(monthRecords);
      this.calculateMonthlyTrend(monthRecords);
      this.calculateConsumptionRanking(monthRecords);

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
      categoryArray.push({
        name: category.name,
        amount: amount,
        percent: percent,
        color: category.color
      });
    });

    categoryArray.sort((a: CategoryItem, b: CategoryItem) => b.amount - a.amount);
    this.categoryData = categoryArray;
  }

  calculateMonthlyTrend(records: Record[]): void {
    const daysInMonth = new Date(this.selectedYear, this.selectedMonth, 0).getDate();
    const trendData: Array<MonthlyTrend> = [];
    const dailyExpense: Map<number, number> = new Map();
    const expenseRecords = records.filter(r => r.type === 'expense');

    expenseRecords.forEach((record: Record) => {
      const parts = record.date.split('-');
      if (parts.length === 3) {
        const day = parseInt(parts[2]);
        if (!isNaN(day) && day >= 1 && day <= daysInMonth) {
          dailyExpense.set(day, (dailyExpense.get(day) || 0) + record.amount);
        }
      }
    });

    for (let day = 1; day <= daysInMonth; day++) {
      trendData.push({
        day: `${day}日`,
        amount: dailyExpense.get(day) || 0,
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

    const ranking: Array<ConsumptionRanking> = [];
    categoryMap.forEach((amount: number, categoryId: string) => {
      const category = this.recordStore!.getCategoryById(categoryId);
      ranking.push({
        category: category.name,
        amount: amount
      });
    });

    ranking.sort((a: ConsumptionRanking, b: ConsumptionRanking) => b.amount - a.amount);
    this.consumptionRanking = ranking;
  }

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
    const centerX = 120, centerY = 120, radius = 90, holeRadius = 30;

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
    const canvasWidth = 320, canvasHeight = 200;
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
    const startX = 30, baseY = canvasHeight - 40;

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

  onMonthSelect(year: number, month: number): void {
    this.selectedYear = year;
    this.selectedMonth = month;
    this.currentMonth = `${month}月`;
    this.showMonthPicker = false;
    this.income = 0;
    this.expense = 0;
    this.balance = 0;
    this.categoryData = [];
    this.monthlyTrend = [];
    this.consumptionRanking = [];
    this.updateStatisticData();
  }

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

  // ====================== 复制功能 ======================
  private async copyData(): Promise<void> {
    let content = `📊 消费排行榜 (${this.currentMonth})\n`;
    content += `==================\n\n`;

    this.consumptionRanking.slice(0, 5).forEach((item: ConsumptionRanking, index: number) => {
      const medal = index === 0 ? '🥇' : index === 1 ? '🥈' : index === 2 ? '🥉' : '  ';
      content += `${medal} ${index + 1}. ${item.category}\n`;
      content += `   金额: ¥${item.amount.toFixed(2)}\n\n`;
    });

    content += `==================\n`;
    content += `总收入: ¥${this.income.toFixed(2)}\n`;
    content += `总支出: ¥${this.expense.toFixed(2)}\n`;
    content += `结余: ¥${this.balance.toFixed(2)}\n`;
    content += `导出时间: ${new Date().toLocaleString()}`;

    try {
      const result = await promptAction.showDialog({
        title: '复制消费排行榜',
        message: '是否将消费排行榜数据复制到剪贴板？\n\n可复制后粘贴到微信、备忘录等应用',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '确认复制', color: '#007AFF' }
        ]
      });

      if (result.index === 1) {
        const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content);
        const systemPasteboard = pasteboard.getSystemPasteboard();
        await systemPasteboard.setData(pasteData);

        promptAction.showToast({
          message: '已复制到剪贴板',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('复制失败:', error);
      promptAction.showToast({
        message: '复制失败，请重试',
        duration: 2000
      });
    }
  }

  // ====================== 修复后的下载功能 ======================
  private async downloadRankingCard(): Promise<void> {
    try {
      const result = await promptAction.showDialog({
        title: '保存图片',
        message: '是否将消费排行榜保存为图片到相册？',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '确认保存', color: '#34C759' }
        ]
      });

      if (result.index !== 1) return;

      promptAction.showToast({
        message: '正在生成图片...',
        duration: 1500
      });

      // 截图组件
      const pixelMap = await componentSnapshot.get('rankingCard', {
        scale: 2,
        waitUntilRenderFinished: true
      });

      // 保存到相册 - 使用 createAsset + packToFile 方式 [^132^][^136^]
      await this.savePixelMapToAlbum(pixelMap);

      promptAction.showToast({
        message: '已保存到相册',
        duration: 2000
      });

    } catch (error) {
      console.error('保存图片失败:', error);
      promptAction.showToast({
        message: '保存失败: ' + (error as Error).message,
        duration: 3000
      });
    }
  }

  // 关键修复：使用 createAsset 直接创建相册文件并写入 [^132^][^136^]
  private async savePixelMapToAlbum(pixelMap: image.PixelMap): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;

    try {
      // 1. 获取相册管理实例
      const helper = photoAccessHelper.getPhotoAccessHelper(context);

      // 2. 在相册中创建图片资源（关键：使用 createAsset）[^132^]
      // 注意：必须在用户点击后的10秒内调用 createAsset，否则权限会收回
      const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
      console.log('创建相册文件成功，uri:', uri);

      // 3. 打开文件准备写入
      const file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

      try {
        // 4. 创建图片打包器
        const imagePackerApi = image.createImagePacker();
        const packOpts: image.PackingOption = {
          format: 'image/png',
          quality: 100
        };

        // 5. 将 PixelMap 打包写入文件 [^132^]
        await imagePackerApi.packToFile(pixelMap, file.fd, packOpts);
        console.log('图片打包写入成功');

        // 6. 关闭文件
        await fs.close(file.fd);

        // 7. 释放打包器资源
        imagePackerApi.release();

      } catch (err) {
        // 发生错误时关闭文件
        await fs.close(file.fd);
       // throw err;
      }

    } catch (error) {
      console.error('保存到相册失败:', error);
      //throw error;
    }
  }

  build() {
    Column() {
      CommonNavBar({
        options: {
          showBack: true,
          onLeftClick: () => {
            router.replaceUrl({ url: 'pages/HomePage' });
          },
          title: '数据统计',
          rightText: '月份',
          onRightClick: () => {
            this.showMonthPicker = true;
          }
        }
      });

      Scroll() {
        Column({ space: 20 }) {
          // ... 其他卡片保持不变 ...
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
            }
          }
          // 消费排行榜卡片
          if (this.consumptionRanking.length > 0) {
            Column() {
              // 截图区域
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
              }
              .id('rankingCard')
              .backgroundColor('#FFFFFF')

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
                    this.downloadRankingCard();
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