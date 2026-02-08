import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@ohos.base';
import { RecordStore } from '../data/RecordStore';
import { DateUtils } from '../utils/DateUtils';
import { Record, Category, TabItem } from '../models/Record';
import { CommonNavBar } from '../components/CommonNavBar';
import { CommonTabBar, DefaultTabItems } from '../components/CommonTabBar';
import pasteboard from '@ohos.pasteboard'; // 导入剪贴板模块



interface RecordParams {
  recordId: string | number;
  refresh?: boolean,
  timestamp?: number
}

@Entry
@Component
struct DataBackupPage {
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

  @State isGeneratingBackup: boolean = false;
  @State showBackupResult: boolean = false;
  @State backupContent: string = ''; // 存储生成的备份文本



  async aboutToAppear(): Promise<void> {
    this.recordStore = RecordStore.getInstance();
    await this.recordStore.ready();

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

    const allRecords = this.recordStore.getAllRecords();
    const record = allRecords.find(r => r.id === this.currentRecordId);

    if (record) {
      this.currentRecord = record;
      this.categoryInfo = this.recordStore.getCategoryById(record.category);
      console.log('加载记录数据成功:', record.id, record.description);
    } else {
      console.log('记录不存在，可能已被删除:', this.currentRecordId);
      this.currentRecord = undefined;
      this.categoryInfo = undefined;
    }
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

  // 获取格式化日期
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

  // 格式化金额显示
  private formatAmount(amount: number, type: string): string {
    const prefix = type === 'expense' ? '-￥' : '+￥';
    return prefix + amount.toFixed(2);
  }

  // ====================== 核心修改：确认弹窗 ======================
  private async showConfirmBackupDialog() {
    if (this.isGeneratingBackup) return;

    try {
      // 系统确认弹窗
      let res = await promptAction.showDialog({
        title: "确认生成备份",
        message: "确定要生成当前数据的备份文本吗？\n生成后可直接复制使用",
        buttons: [
          { text: "取消", color: "#666666" },
          { text: "确认", color: "#007AFF" },
        ]
      });

      // 点击确认，生成备份文本并显示
      if (res.index === 1) {
        await this.generateAndShowBackup();
      } else {
        promptAction.showToast({ message: "已取消备份", duration: 1500 });
      }
    } catch (err) {
      console.error("弹窗异常", err);
    }
  }
  // ===========================================================================

  // 生成备份并显示（不保存文件，直接展示文本）
  private async generateAndShowBackup(): Promise<void> {
    if (this.isGeneratingBackup) {
      return;
    }

    this.isGeneratingBackup = true;

    try {
      promptAction.showToast({ message: '正在生成备份...', duration: 800 });

      // 生成备份内容
      this.backupContent = this.generateBackupContent();
      this.showBackupResult = true;

      promptAction.showToast({ message: '备份生成成功', duration: 1500 });

    } catch (error) {
      console.error('备份生成失败:', error);
      promptAction.showToast({ message: '生成失败，请重试', duration: 2000 });
    } finally {
      this.isGeneratingBackup = false;
    }
  }

  // 复制文本到剪贴板
  private async copyToClipboard(): Promise<void> {
    try {
      // 创建剪贴板数据 [^11^]
      const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.backupContent);
      const systemPasteboard = pasteboard.getSystemPasteboard();

      // 设置数据到系统剪贴板，允许跨应用粘贴 [^21^]
      await systemPasteboard.setData(pasteboardData);

      promptAction.showToast({ message: '已复制到剪贴板', duration: 2000 });
    } catch (error) {
      console.error('复制失败:', error);
      promptAction.showToast({ message: '复制失败，请手动复制', duration: 2000 });
    }
  }

  // 生成备份文本内容
  private generateBackupContent(): string {
    const timestamp = new Date().toLocaleString();
    let content = '=== 财务记录备份 ===\n';
    content += `备份时间: ${timestamp}\n`;
    content += '===================\n\n';

    if (this.showRecentRecords) {
      content += '【最近记录】\n';
      content += '-----------\n';

      if (this.recentRecords.length > 0) {
        this.recentRecords.forEach((record, index) => {
          content += `${index + 1}. ${record.description || '无描述'}\n`;
          content += `   金额: ${this.formatAmount(record.amount, record.type)}\n`;
          content += `   分类: ${this.getCategoryName(record.category)}\n`;
          content += `   时间: ${record.date} ${record.time}\n`;
          content += `   类型: ${record.type === 'expense' ? '支出' : '收入'}\n\n`;
        });
      } else {
        content += '暂无记录\n\n';
      }
    } else if (this.currentRecord) {
      content += '【详细记录】\n';
      content += '-----------\n';
      content += `描述: ${this.currentRecord.description || '无描述'}\n`;
      content += `金额: ${this.formatAmount(this.currentRecord.amount, this.currentRecord.type)}\n`;
      content += `分类: ${this.getCategoryName(this.currentRecord.category)}\n`;
      content += `时间: ${this.getFormattedDate()}\n`;
      content += `类型: ${this.currentRecord.type === 'expense' ? '支出' : '收入'}\n`;
      content += `记录ID: ${this.currentRecord.id}\n\n`;

      // 添加统计信息
      content += '【月度统计】\n';
      content += '-----------\n';
      content += `本月餐饮消费: ¥${this.foodExpenseTotal.toFixed(2)}\n`;
      content += `餐饮预算剩余: ¥${(this.budgetTotal - this.foodExpenseTotal).toFixed(2)}\n`;
    }

    content += '\n=== 备份结束 ===\n';
    content += `记录总数: ${this.recentRecords.length}\n`;
    content += '生成时间: ' + new Date().toISOString();

    return content;
  }

  build() {
    Column() {
      // 顶部导航栏
      CommonNavBar({
        options: {
          showBack: true,
          onLeftClick: () => {
            router.back();
          },
          title: '数据备份',
        }
      });

      // 主要内容区域
      Scroll() {
        Column({ space: 20 }) {
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
                      Column() {
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

              Column({ space: 16 }) {
                Text('详细信息')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#000000')
                  .margin({ left: 20, top: 20 })

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
            }
          }

          // ====================== 核心修改：备份结果显示区域 ======================
          if (this.showBackupResult && this.backupContent) {
            Column({ space: 12 }) {
              Row() {
                Text('📋 备份内容')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#000000')

                Blank()

                // 复制按钮
                Button('一键复制')
                  .fontSize(14)
                  .height(32)
                  .backgroundColor('#007AFF')
                  .onClick(() => {
                    this.copyToClipboard();
                  })
              }
              .width('100%')

              // 使用 TextArea 替代 TextInput，支持多行自动换行 [^23^][^26^]
              TextArea({ text: this.backupContent })
                .width('100%')
                .height(300)
                .fontSize(14)
                .fontColor('#333333')
                .backgroundColor('#F5F5F5')
                .padding(12)
                .borderRadius(8)
                .enabled(true) // 允许交互选择文本
                .copyOption(CopyOptions.LocalDevice) // 允许复制 [^13^]

              Text('提示：点击"一键复制"可直接复制全部内容，或长按上方文本框手动选择复制')
                .fontSize(12)
                .fontColor('#999999')
                .width('100%')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#E8F4FD')
            .borderRadius(12)
            .margin({ top: 10 })
          }
          // ===========================================================================

          // 备份说明（仅在未生成备份时显示）
          if (!this.showBackupResult) {
            Column({ space: 8 }) {
              Text('备份说明')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#000000')
                .margin({ bottom: 12 })

              Text('点击下方按钮生成备份文本')
                .fontSize(14)
                .fontColor('#666666')
              Text('生成后可直接复制或手动选择文本')
                .fontSize(14)
                .fontColor('#666666')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ top: 20 })
          }
        }
        .width('100%')
        .padding(20)
      }
      .width('100%')
      .height('85%')
      .backgroundColor('#F2F2F7')
      .scrollBar(BarState.Off)

      // 底部备份按钮
      Column() {
        Button(this.showBackupResult ? '重新生成备份' : '生成备份文本')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .backgroundColor(this.isGeneratingBackup ? '#CCCCCC' : '#007AFF')
          .width('90%')
          .height(50)
          .borderRadius(25)
          .enabled(!this.isGeneratingBackup)
          .onClick(() => {
            if (this.showBackupResult) {
              // 如果已经显示结果，点击则重新生成
              this.generateAndShowBackup();
            } else {
              // 首次点击显示确认弹窗
              this.showConfirmBackupDialog();
            }
          })

        if (this.isGeneratingBackup) {
          LoadingProgress()
            .width(30)
            .height(30)
            .color('#007AFF')
            .margin({ top: 10 })
        }

        Text(this.showBackupResult ? '已生成备份文本，请复制使用' : '点击生成可复制的备份文本')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 8 })
      }
      .width('100%')
      .height('15%')
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}