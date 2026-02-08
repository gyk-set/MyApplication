import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import { RecordStore } from '../data/RecordStore';
import { CategoryItem, ConsumptionRanking, MonthlyTrend, Record, TabItem } from '../models/Record';
import { CommonTabBar, DefaultTabItems } from '../components/CommonTabBar';
import { CommonNavBar } from '../components/CommonNavBar';
import { fileUri } from '@kit.CoreFileKit';

// 关键修改：从 @kit.AbilityKit 导入 wantConstant
import { common, wantConstant, Want } from '@kit.AbilityKit';

// 导出类型枚举
enum ExportType {
  OVERVIEW = 'overview',
  CATEGORY_PIE = 'category_pie',
  RANKING = 'ranking',
  MONTHLY_TREND = 'monthly_trend',
  ALL_RECORDS = 'all_records'
}

// 显式接口定义
interface ExportOption {
  type: ExportType;
  title: string;
  icon: string;
  description: string;
}



// 月份选项接口
interface MonthItem {
  year: number;
  month: number;
  label: string;
}

// 按钮配置接口
interface ActionButton {
  text: string;
  color: string;
}

@Entry
@Component
struct ExportRecordsPage {
  private recordStore: RecordStore | undefined = undefined;

  @State currentIndex: number = 0;
  private tabItems: Array<TabItem> = DefaultTabItems;

  @State currentMonth: string = '本月';
  @State selectedYear: number = new Date().getFullYear();
  @State selectedMonth: number = new Date().getMonth() + 1;
  @State income: number = 0;
  @State expense: number = 0;
  @State balance: number = 0;
  @State categoryData: Array<CategoryItem> = [];
  @State monthlyTrend: Array<MonthlyTrend> = [];
  @State consumptionRanking: Array<ConsumptionRanking> = [];
  @State allRecords: Record[] = [];

  @State isExporting: boolean = false;
  @State exportProgress: number = 0;
  @State lastExportedFile: string = '';
  @State showExportSuccess: boolean = false;

  private exportOptions: Array<ExportOption> = [
    {
      type: ExportType.OVERVIEW,
      title: '收支概览',
      icon: '💰',
      description: '导出当前月份的收入、支出、结余统计'
    },
    {
      type: ExportType.CATEGORY_PIE,
      title: '支出分类',
      icon: '📊',
      description: '导出各分类支出金额及占比'
    },
    {
      type: ExportType.RANKING,
      title: '消费排行榜',
      icon: '🏆',
      description: '导出消费金额最高的分类排名'
    },
    {
      type: ExportType.MONTHLY_TREND,
      title: '月度趋势',
      icon: '📈',
      description: '导出每日支出趋势数据'
    },
    {
      type: ExportType.ALL_RECORDS,
      title: '所有记录明细',
      icon: '📋',
      description: '导出完整的记账记录列表'
    }
  ];

  async aboutToAppear(): Promise<void> {
    this.recordStore = RecordStore.getInstance();
    await this.recordStore.ready();
    this.loadAllData();
  }

  private loadAllData(): void {
    this.updateStatisticData();
    this.loadAllRecords();
  }

  private loadAllRecords(): void {
    if (!this.recordStore) return;
    this.allRecords = this.recordStore.getAllRecords();
  }

  private updateStatisticData(): void {
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
      this.currentMonth = `${this.selectedYear}年${this.selectedMonth}月`;

      this.calculateCategoryData(monthRecords);
      this.calculateMonthlyTrend(monthRecords);
      this.calculateConsumptionRanking(monthRecords);

    } catch (error) {
      console.error('更新统计数据失败:', error);
    }
  }

  private calculateCategoryData(records: Record[]): void {
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

  private calculateMonthlyTrend(records: Record[]): void {
    const daysInMonth = new Date(this.selectedYear, this.selectedMonth, 0).getDate();
    const trendData: Array<MonthlyTrend> = [];
    const dailyExpense: Map<number, number> = new Map();

    const expenseRecords = records.filter(r => r.type === 'expense');
    expenseRecords.forEach((record: Record) => {
      const parts = record.date.split('-');
      if (parts.length === 3) {
        const day = parseInt(parts[2]);
        if (!isNaN(day)) {
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

  private calculateConsumptionRanking(records: Record[]): void {
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

  private generateCSVContent(exportType: ExportType): string {
    let csvContent = '';
    const bom = '\uFEFF';

    switch (exportType) {
      case ExportType.OVERVIEW:
        csvContent = this.generateOverviewCSV();
        break;
      case ExportType.CATEGORY_PIE:
        csvContent = this.generateCategoryCSV();
        break;
      case ExportType.RANKING:
        csvContent = this.generateRankingCSV();
        break;
      case ExportType.MONTHLY_TREND:
        csvContent = this.generateTrendCSV();
        break;
      case ExportType.ALL_RECORDS:
        csvContent = this.generateAllRecordsCSV();
        break;
    }

    return bom + csvContent;
  }

  private generateOverviewCSV(): string {
    let csv = '收支概览报表\n';
    csv += `统计月份,${this.currentMonth}\n`;
    csv += `生成时间,${new Date().toLocaleString()}\n\n`;
    csv += '项目,金额(元),占比\n';
    csv += `总收入,${this.income.toFixed(2)},100%\n`;
    csv += `总支出,${this.expense.toFixed(2)},${this.income > 0 ? ((this.expense / this.income) * 100).toFixed(2) : '0'}%\n`;
    csv += `结余,${this.balance.toFixed(2)},${this.income > 0 ? ((this.balance / this.income) * 100).toFixed(2) : '0'}%\n`;
    return csv;
  }

  private generateCategoryCSV(): string {
    let csv = '支出分类统计\n';
    csv += `统计月份,${this.currentMonth}\n`;
    csv += `总支出,${this.expense.toFixed(2)}元\n\n`;
    csv += '排名,分类名称,金额(元),占比(%),颜色标识\n';

    this.categoryData.forEach((item: CategoryItem, index: number) => {
      csv += `${index + 1},${item.name},${item.amount.toFixed(2)},${item.percent.toFixed(2)},${item.color}\n`;
    });

    return csv;
  }

  private generateRankingCSV(): string {
    let csv = '消费排行榜\n';
    csv += `统计月份,${this.currentMonth}\n\n`;
    csv += '排名,分类名称,消费金额(元),占比(%)\n';

    const total = this.consumptionRanking.reduce((sum: number, item: ConsumptionRanking) => sum + item.amount, 0);
    this.consumptionRanking.forEach((item: ConsumptionRanking, index: number) => {
      const percent = total > 0 ? ((item.amount / total) * 100).toFixed(2) : '0';
      csv += `${index + 1},${item.category},${item.amount.toFixed(2)},${percent}\n`;
    });

    return csv;
  }

  private generateTrendCSV(): string {
    let csv = '月度支出趋势\n';
    csv += `统计月份,${this.currentMonth}\n\n`;
    csv += '日期,支出金额(元),星期\n';

    this.monthlyTrend.forEach((item: MonthlyTrend) => {
      const dayNum = parseInt(item.day);
      const date = new Date(this.selectedYear, this.selectedMonth - 1, dayNum);
      const weekDay = ['日', '一', '二', '三', '四', '五', '六'][date.getDay()];
      csv += `${item.day},${item.amount.toFixed(2)},星期${weekDay}\n`;
    });

    return csv;
  }

  private generateAllRecordsCSV(): string {
    let csv = '记账记录明细\n';
    csv += `导出时间,${new Date().toLocaleString()}\n`;
    csv += `记录总数,${this.allRecords.length}\n\n`;
    csv += '序号,日期,时间,类型,分类,金额(元),描述,记录ID\n';

    this.allRecords.forEach((record: Record, index: number) => {
      const typeStr = record.type === 'income' ? '收入' : '支出';
      const categoryName = this.recordStore?.getCategoryById(record.category)?.name || '未知';
      csv += `${index + 1},${record.date},${record.time},${typeStr},${categoryName},${record.amount.toFixed(2)},"${record.description || ''}",${record.id}\n`;
    });

    return csv;
  }

  private async performExport(exportType: ExportType): Promise<void> {
    if (this.isExporting) return;

    this.isExporting = true;
    this.exportProgress = 0;
    this.showExportSuccess = false;

    try {
      this.exportProgress = 30;
      await new Promise<void>(resolve => setTimeout(resolve, 200));

      const csvContent = this.generateCSVContent(exportType);
      this.exportProgress = 60;

      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
      const fileName = `财务记录_${this.getExportTypeName(exportType)}_${timestamp}.csv`;

      const context = getContext() as common.UIAbilityContext;
      const filePath = `${context.filesDir}/${fileName}`;

      const file = await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(file.fd, csvContent);
      await fs.close(file.fd);

      this.exportProgress = 100;
      this.lastExportedFile = filePath;
      this.showExportSuccess = true;

      promptAction.showToast({ message: 'CSV文件已生成', duration: 2000 });
      await this.shareFile(filePath);

    } catch (error) {
      console.error('导出失败:', error);
      promptAction.showToast({ message: '导出失败: ' + (error as BusinessError).message, duration: 3000 });
    } finally {
      this.isExporting = false;
    }
  }

  private getExportTypeName(type: ExportType): string {
    switch (type) {
      case ExportType.OVERVIEW: return '收支概览';
      case ExportType.CATEGORY_PIE: return '支出分类';
      case ExportType.RANKING: return '消费排行榜';
      case ExportType.MONTHLY_TREND: return '月度趋势';
      case ExportType.ALL_RECORDS: return '所有记录';
      default: return '导出';
    }
  }

  private async shareFile(filePath: string): Promise<void> {
    try {
      const context = getContext() as common.UIAbilityContext;
      const uri = fileUri.getUriFromPath(filePath);

      // 关键：显式声明为 common.Want 类型
      const want: Want = {
        action: 'ohos.want.action.sendData',  // 字符串字面量
        type: 'text/csv',
        uri: uri,
        flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION | wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION
      };

      await context.startAbility(want);
      console.log('分享成功');
    } catch (error) {
      console.error('分享失败:', error);
      promptAction.showToast({ message: '分享失败，文件已保存到应用目录', duration: 2000 });
    }
  }

  private async showExportConfirm(option: ExportOption): Promise<void> {
    try {
      const res = await promptAction.showDialog({
        title: `导出${option.title}`,
        message: `即将导出${option.title}数据为CSV文件\n\n文件包含：${option.description}\n\n导出后可通过系统分享保存到本地或发送给其他应用`,
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '确认导出', color: '#007AFF' }
        ]
      });

      if (res.index === 1) {
        await this.performExport(option.type);
      }
    } catch (err) {
      console.error('导出确认异常:', err);
    }
  }

  private async reShareFile(): Promise<void> {
    if (this.lastExportedFile) {
      await this.shareFile(this.lastExportedFile);
    }
  }

  build() {
    Column() {
      CommonNavBar({
        options: {
          showBack: true,
          onLeftClick: () => {
            router.back();
          },
          title: '导出数据',
        }
      });

      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 12 }) {
            Text('📅 选择统计月份')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#000000')
              .width('100%')

            Row() {
              Text(this.currentMonth)
                .fontSize(16)
                .fontColor('#007AFF')
                .fontWeight(FontWeight.Medium)

              Blank()

              Button('切换月份')
                .fontSize(14)
                .height(36)
                .backgroundColor('#F0F0F0')
                .fontColor('#007AFF')
                .onClick(() => {
                  this.showMonthPicker();
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)

          Column({ space: 12 }) {
            Text('📤 选择导出内容')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#000000')
              .width('100%')

            ForEach(this.exportOptions, (option: ExportOption) => {
              Column({ space: 8 }) {
                Row({ space: 12 }) {
                  Text(option.icon)
                    .fontSize(24)
                    .width(40)
                    .textAlign(TextAlign.Center)

                  Column({ space: 4 }) {
                    Text(option.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#000000')

                    Text(option.description)
                      .fontSize(13)
                      .fontColor('#666666')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Button('导出')
                    .fontSize(14)
                    .height(32)
                    .backgroundColor('#007AFF')
                    .onClick(() => {
                      this.showExportConfirm(option);
                    })
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#F8F8F8')
                .borderRadius(12)

                if (this.isExporting) {
                  Progress({ value: this.exportProgress, total: 100, type: ProgressType.Linear })
                    .width('100%')
                    .height(4)
                    .color('#007AFF')
                    .backgroundColor('#E0E0E0')
                }
              }
              .width('100%')
            }, (option: ExportOption) => option.type)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)

          if (this.showExportSuccess && this.lastExportedFile) {
            Column({ space: 12 }) {
              Text('✅ 导出成功')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#34C759')
                .width('100%')
                .textAlign(TextAlign.Center)

              Text('文件已保存到应用私有目录')
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .textAlign(TextAlign.Center)

              Text(`路径: ${this.lastExportedFile}`)
                .fontSize(12)
                .fontColor('#999999')
                .width('100%')
                .textAlign(TextAlign.Center)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Button('重新分享')
                .fontSize(16)
                .width('100%')
                .height(44)
                .backgroundColor('#007AFF')
                .margin({ top: 8 })
                .onClick(() => {
                  this.reShareFile();
                })

              Text('提示：CSV文件可通过微信、邮件、文件管理器等应用分享保存')
                .fontSize(12)
                .fontColor('#999999')
                .width('100%')
                .textAlign(TextAlign.Center)
                .margin({ top: 8 })
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#E8F5E9')
            .borderRadius(12)
          }

          Column({ space: 8 }) {
            Text('💡 使用说明')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#000000')
              .width('100%')

            Text('1. CSV文件可导入Excel、WPS等表格软件查看')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')

            Text('2. 导出后请使用系统分享功能保存到合适位置')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')

            Text('3. 文件默认保存于应用私有目录，卸载应用后将丢失')
              .fontSize(13)
              .fontColor('#FF6B6B')
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFF8E1')
          .borderRadius(12)
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
        .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  // 使用 promptAction.showDialog 替代
  private async showMonthPicker(): Promise<void> {
    const months: Array<MonthItem> = [];
    const currentDate = new Date();

    for (let i = 0; i < 6; i++) {
      const d = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1);
      months.push({
        year: d.getFullYear(),
        month: d.getMonth() + 1,
        label: `${d.getFullYear()}年${d.getMonth() + 1}月`
      });
    }

    // 构建消息文本
    const message = months.map((m, i) => `${i + 1}. ${m.label}`).join('\n');

    try {
      const result = await promptAction.showDialog({
        title: '选择月份',
        message: message,
        buttons: [
          { text: '1月前', color: '#666666' },
          { text: '2月前', color: '#666666' },
          { text: '3月前', color: '#666666' },
          { text: '4月前', color: '#666666' },
          { text: '5月前', color: '#666666' },
          { text: '6月前', color: '#666666' }
        ]
      });

      if (result.index >= 0 && result.index < months.length) {
        const selected = months[result.index];
        this.selectedYear = selected.year;
        this.selectedMonth = selected.month;
        this.loadAllData();
      }
    } catch (error) {
      console.error('选择月份失败:', error);
    }
  }
}