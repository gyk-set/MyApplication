import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { RecordStore } from '../data/RecordStore';
import { DateUtils } from '../utils/DateUtils';
import { Record, Category, TabItem } from '../models/Record';
import { CommonNavBar } from '../components/CommonNavBar';
import { CommonTabBar, DefaultTabItems } from '../components/CommonTabBar';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';


interface RecordParams {
  recordId: string | number;
  refresh?: boolean,
  timestamp?: number
}


interface GeneratedObjectLiteralInterface_1 {
  action: string;
  type: string;
  uri: string;
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

  @State isGeneratingImage: boolean = false;
  @State backupFilePath: string = '';
  @State showBackupSuccess: boolean = false;

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

  // 生成并保存备份 - 修改为方案一
  private async saveAndShareBackup(): Promise<void> {
    if (this.isGeneratingImage) {
      return;
    }

    this.isGeneratingImage = true;
    this.showBackupSuccess = false;

    try {
      promptAction.showToast({ message: '正在生成备份...', duration: 1000 });

      // 生成备份内容
      const backupContent = this.generateBackupContent();

      // 保存到应用私有目录（不需要额外权限）
      const context = getContext() as common.UIAbilityContext;
      const filesDir = context.filesDir;
      const fileName = `财务记录备份_${new Date().toLocaleDateString().replace(/\//g, '-')}.txt`;
      const filePath = `${filesDir}/${fileName}`;

      // 写入文件
      const file = await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(file.fd, backupContent);
      await fs.close(file.fd);

      console.log('文件已保存到应用目录:', filePath);
      this.backupFilePath = filePath;
      this.showBackupSuccess = true;

      // 直接调用系统分享
      await this.shareFileDirectly(filePath, backupContent);

    } catch (error) {
      console.error('备份失败:', error);
      promptAction.showToast({ message: '备份失败: ' + error.message, duration: 3000 });
    } finally {
      this.isGeneratingImage = false;
    }
  }

  shareFileDirectly(filePath: string, backupContent: string) {
    throw new Error('Method not implemented.');
  }

  // 最简单的分享方法
  private async shareFile(filePath: string): Promise<void> {
    try {
      const context = getContext() as common.UIAbilityContext;
      const fileName = filePath.split('/').pop() || '财务记录备份.txt';

      // 方法1：使用uri方式
      const want1: GeneratedObjectLiteralInterface_1 = {
        action: 'ohos.want.action.sendFile',
        type: 'text/plain',
        uri: `file://${filePath}`
      };

      // 尝试第一种方式，失败时尝试第二种
        await context.startAbility(want1);



      console.log('分享文件成功');
    } catch (error) {
      console.error('分享文件失败:', error);
      // 错误处理...
    }
  }

  // 显示备份内容让用户手动复制
  private async showBackupContent(content: string): Promise<void> {
    try {
      // 计算显示的行数（前30行）
      const lines = content.split('\n');
      const previewLines = lines.slice(0, Math.min(30, lines.length));
      const previewContent = previewLines.join('\n');

      const result = await promptAction.showDialog({
        title: '📋 备份内容',
        message: `备份已生成！\n\n由于系统限制，文件已保存到应用私有目录。\n\n以下是备份内容（前${previewLines.length}行）：\n\n${previewContent}\n\n... ${lines.length - previewLines.length} 行更多内容\n\n您可以选择：`,
        buttons: [
          {
            text: '查看完整内容',
            color: '#666666'
          },
          {
            text: '复制文本内容',
            color: '#007AFF'
          }
        ]
      });

      if (result.index === 0) {
        // 显示完整内容
        await this.showFullContent(content);
      } else if (result.index === 1) {
        // 提示用户手动复制
        await this.showCopyInstructions(content);
      }

    } catch (error) {
      console.error('显示内容失败:', error);
    }
  }

  // 显示完整内容
  private async showFullContent(content: string): Promise<void> {
    try {
      promptAction.showDialog({
        title: '📄 完整备份内容',
        message: content,
        buttons: [{
          text: '关闭',
          color: '#007AFF'
        }]
      });
    } catch (error) {
      console.error('显示完整内容失败:', error);
    }
  }

  // 显示复制说明
  private async showCopyInstructions(content: string): Promise<void> {
    try {
      // 显示操作指引
      promptAction.showDialog({
        title: '📋 复制说明',
        message: '请按以下步骤操作：\n\n1. 返回上一个对话框\n2. 长按备份内容文本\n3. 选择"全选"\n4. 选择"复制"\n5. 粘贴到备忘录、微信或其他应用\n\n或者您可以选择重新生成并尝试分享。',
        buttons: [
          {
            text: '返回查看内容',
            color: '#666666'
          },
          {
            text: '重新生成备份',
            color: '#007AFF'
          }
        ]
      }).then(result => {
        if (result.index === 0) {
          this.showFullContent(content);
        } else if (result.index === 1) {
          this.saveAndShareBackup();
        }
      });
    } catch (error) {
      promptAction.showToast({ message: '操作失败', duration: 2000 });
    }
  }

  // 生成备份文本内容
  private generateBackupContent(): string {
    const timestamp = new Date().toLocaleString();
    let content = '=== 财务记录备份 ===\n';
    content += `备份时间: ${timestamp}\n`;
    content += '===================\n\n';

    if (this.showRecentRecords) {
      content += '最近记录:\n';
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
      content += '详细记录:\n';
      content += '-----------\n';
      content += `描述: ${this.currentRecord.description || '无描述'}\n`;
      content += `金额: ${this.formatAmount(this.currentRecord.amount, this.currentRecord.type)}\n`;
      content += `分类: ${this.getCategoryName(this.currentRecord.category)}\n`;
      content += `时间: ${this.getFormattedDate()}\n`;
      content += `类型: ${this.currentRecord.type === 'expense' ? '支出' : '收入'}\n`;
      content += `记录ID: ${this.currentRecord.id}\n\n`;

      // 添加统计信息
      content += '月度统计:\n';
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
          } else {
            Column() {
              Image($r('app.media.background'))
                .width(120)
                .height(120)
                .margin({ bottom: 20 })
              Text('无记录数据')
                .fontSize(18)
                .fontColor('#8E8E93')
                .margin({ bottom: 20 })
            }
            .width('100%')
            .height(400)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }

          // 备份说明
          Column({ space: 8 }) {
            Text('备份说明')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#000000')
              .margin({ bottom: 12 })

            Text('点击下方按钮将生成备份文件')
              .fontSize(14)
              .fontColor('#666666')
            Text('系统会自动弹出分享菜单')
              .fontSize(14)
              .fontColor('#666666')
            Text('您可以选择分享到微信、QQ、邮箱等')
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ top: 20, bottom: 10 })

          // 显示备份成功信息
          if (this.showBackupSuccess && this.backupFilePath) {
            Column({ space: 8 }) {
              Text('✅ 备份已生成')
                .fontSize(16)
                .fontColor('#34C759')
                .fontWeight(FontWeight.Bold)

              Text('如果未弹出分享菜单，请点击下方按钮重新分享')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ top: 4 })

              Button('重新分享')
                .fontSize(14)
                .height(36)
                .margin({ top: 8 })
                .onClick(async () => {
                  const backupContent = this.generateBackupContent();
                  await this.shareFileDirectly(this.backupFilePath, backupContent);
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#E8F5E9')
            .borderRadius(12)
            .margin({ top: 10 })
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
        Button('生成并分享备份')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .backgroundColor(this.isGeneratingImage ? '#CCCCCC' : '#007AFF')
          .width('90%')
          .height(50)
          .borderRadius(25)
          .enabled(!this.isGeneratingImage)
          .onClick(() => {
            this.saveAndShareBackup();
          })

        if (this.isGeneratingImage) {
          LoadingProgress()
            .width(30)
            .height(30)
            .color('#007AFF')
            .margin({ top: 10 })
        }

        Text('点击后请留意系统分享菜单')
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