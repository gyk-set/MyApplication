import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

import { RecordStore, categories } from '../data/RecordStore';
import { DateUtils } from '../utils/DateUtils';
import { Record, CategoryType, Category, TabItem } from '../models/Record';
import { CommonNavBar } from '../components/CommonNavBar'
import { CommonTabBar, DefaultTabItems } from '../components/CommonTabBar'

interface GeneratedTypeLiteralInterface_1 {
  recordId?: string;
}

interface GeneratedTypeLiteralInterface_2 {
  enabled: boolean;
  text: string;
}

@Entry
@Component
export struct EditPage {
  private recordStore = RecordStore.getInstance();
  private tabItems: Array<TabItem> = DefaultTabItems;
  @State quickDescriptions: string[] = ['午餐', '交通', '购物', '娱乐', '学习', '其他'];
  @State amount: string = '';
  @State recordType: 'expense' | 'income' = 'expense';
  @State selectedCategory: Category | null = null;
  @State description: string = '';
  @State showCategoryPicker: boolean = false;
  @State expenseCategories: Category[] = [];
  @State incomeCategories: Category[] = [];
  @State isIconError: boolean = false;
  @State currentType: CategoryType = CategoryType.EXPENSE;
  @State recordId: string = '';
  @State originalRecord: Record | null = null;
  @State isSaving: boolean = false;
  private categoryList = categories;

  // 时间选择器相关状态
  @State selectedDate: string = DateUtils.getCurrentDate();
  @State selectedTime: string = DateUtils.getCurrentTime();
  @State selectedYear: number = new Date().getFullYear();
  @State selectedMonth: number = new Date().getMonth() + 1;
  @State selectedDay: number = new Date().getDate();
  @State selectedHour: number = new Date().getHours();
  @State selectedMinute: number = new Date().getMinutes();
  @State showDatePicker: boolean = false;
  @State showTimePicker: boolean = false;

  // 动态获取当前类型的分类列表
  get currentCategories(): Category[] {
    return this.categoryList.filter(item => item.type === this.currentType);
  }

  // 页面初始化时加载数据
  async aboutToAppear(): Promise<void> {
    await this.recordStore.ready();
    this.loadCategories();

    // 从路由参数获取记录ID
    const params = router.getParams() as GeneratedTypeLiteralInterface_1;
    if (params?.recordId) {
      this.recordId = params.recordId;
      this.loadRecordData();
    } else {
      // 如果没有记录ID，返回上一页
      promptAction.showToast({ message: '未找到记录', duration: 2000 });
      setTimeout(() => {
        router.back();
      }, 1000);
    }
  }

  // 加载记录数据
  loadRecordData(): void {
    const record = this.recordStore.getRecordById(this.recordId);
    if (record) {
      this.originalRecord = record;
      this.amount = record.amount.toFixed(2);
      this.recordType = record.type as 'expense' | 'income';
      this.description = record.description || '';

      // 设置时间
      this.selectedDate = record.date;
      this.selectedTime = record.time;

      // 解析日期和时间
      const dateParts = record.date.split('-');
      if (dateParts.length === 3) {
        this.selectedYear = parseInt(dateParts[0]);
        this.selectedMonth = parseInt(dateParts[1]);
        this.selectedDay = parseInt(dateParts[2]);
      }

      const timeParts = record.time.split(':');
      if (timeParts.length === 2) {
        this.selectedHour = parseInt(timeParts[0]);
        this.selectedMinute = parseInt(timeParts[1]);
      }

      // 设置分类
      const category = this.recordStore.getCategoryById(record.category);
      if (category) {
        this.selectedCategory = category;
        // 根据分类类型设置当前显示类型
        this.currentType = category.type === CategoryType.EXPENSE ? CategoryType.EXPENSE : CategoryType.INCOME;
      }
    } else {
      promptAction.showToast({ message: '记录不存在', duration: 2000 });
      setTimeout(() => {
        router.back();
      }, 1000);
    }
  }

  // 从RecordStore加载支出/收入分类
  loadCategories(): void {
    this.expenseCategories = [...this.recordStore.getExpenseCategories()];
    this.incomeCategories = [...this.recordStore.getIncomeCategories()];
  }

  // 检查是否有修改
  hasChanges(): boolean {
    if (!this.originalRecord) return false;

    return (
      Math.abs(parseFloat(this.amount) - this.originalRecord.amount) > 0.001 ||
        this.recordType !== this.originalRecord.type ||
        this.description !== this.originalRecord.description ||
        !this.selectedCategory ||
        this.selectedCategory.id !== this.originalRecord.category ||
        this.selectedDate !== this.originalRecord.date ||
        this.selectedTime !== this.originalRecord.time
    );
  }

  // 更新记录
  async updateRecord(): Promise<void> {
    if (!this.originalRecord) {
      promptAction.showToast({ message: '记录不存在', duration: 2000 });
      return;
    }

    if (!this.amount || parseFloat(this.amount) <= 0) {
      promptAction.showToast({ message: '请输入有效金额', duration: 2000 });
      return;
    }

    if (!this.selectedCategory) {
      promptAction.showToast({ message: '请选择分类', duration: 2000 });
      return;
    }

    // 如果没有修改，直接返回
    if (!this.hasChanges()) {
      promptAction.showToast({ message: '没有修改内容', duration: 2000 });
      return;
    }

    this.isSaving = true;

    try {
      const updatedRecord: Record = {
        id: this.originalRecord.id, // 保留原始ID
        amount: parseFloat(this.amount),
        type: this.recordType,
        category: this.selectedCategory.id,
        description: this.description || this.selectedCategory.name,
        date: this.selectedDate,
        time: this.selectedTime,
        timestamp: DateUtils.getCurrentTimestamp()
      };

      const success = await this.recordStore.updateRecord(updatedRecord);

      if (success) {
        promptAction.showToast({ message: '更新成功', duration: 2000 });
        // 返回上一页，并携带更新成功的标志
        setTimeout(() => {
          router.back({
            url: 'pages/DetailPage',
            params: {
              recordId: this.recordId,
              updated: true,
              timestamp: Date.now() // 添加时间戳确保每次返回都不同
            }
          });
        }, 500);
      } else {
        promptAction.showToast({ message: '更新失败', duration: 2000 });
      }
    } catch (error) {
      console.error('更新记录失败:', error);
      promptAction.showToast({ message: '更新失败', duration: 2000 });
    } finally {
      this.isSaving = false;
    }
  }

  // 删除记录
  private async deleteRecord(): Promise<void> {
    if (!this.originalRecord) {
      return;
    }

    try {
      const result = await promptAction.showDialog({
        title: '确认删除',
        message: `确定要删除"${this.originalRecord.description}"这条记录吗？`,
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

      if (result.index === 1) {
        const success = await this.recordStore.deleteRecord(this.recordId);
        if (success) {
          promptAction.showToast({ message: '删除成功', duration: 2000 });
          // 返回首页
          setTimeout(() => {
            router.replaceUrl({
              url: 'pages/HomePage'
            });
          }, 500);
        } else {
          promptAction.showToast({ message: '删除失败', duration: 2000 });
        }
      }
    } catch (error) {
      console.error('删除记录时出错:', error);
      promptAction.showToast({ message: '删除失败', duration: 2000 });
    }
  }

  // 重置为原始值
  resetToOriginal(): void {
    if (this.originalRecord) {
      this.amount = this.originalRecord.amount.toFixed(2);
      this.recordType = this.originalRecord.type as 'expense' | 'income';
      this.description = this.originalRecord.description || '';
      this.selectedDate = this.originalRecord.date;
      this.selectedTime = this.originalRecord.time;

      // 解析日期和时间
      const dateParts = this.originalRecord.date.split('-');
      if (dateParts.length === 3) {
        this.selectedYear = parseInt(dateParts[0]);
        this.selectedMonth = parseInt(dateParts[1]);
        this.selectedDay = parseInt(dateParts[2]);
      }

      const timeParts = this.originalRecord.time.split(':');
      if (timeParts.length === 2) {
        this.selectedHour = parseInt(timeParts[0]);
        this.selectedMinute = parseInt(timeParts[1]);
      }

      const category = this.recordStore.getCategoryById(this.originalRecord.category);
      if (category) {
        this.selectedCategory = category;
        this.currentType = category.type === CategoryType.EXPENSE ? CategoryType.EXPENSE : CategoryType.INCOME;
      }
    }
  }

  // 获取保存按钮状态
  getSaveButtonState(): GeneratedTypeLiteralInterface_2 {
    if (this.isSaving) {
      return { enabled: false, text: '保存中...' };
    }

    if (!this.hasChanges()) {
      return { enabled: false, text: '保存' };
    }

    return { enabled: true, text: '保存' };
  }

  // 时间选择器相关方法
  getWeekday(): string {
    const dateStr = this.selectedDate;
    if (!dateStr) return '';

    const dateParts = dateStr.split('-');
    if (dateParts.length !== 3) return '';

    const year = parseInt(dateParts[0]);
    const month = parseInt(dateParts[1]) - 1;
    const day = parseInt(dateParts[2]);

    const date = new Date(year, month, day);
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekdays[date.getDay()];
  }

  setToNow(): void {
    const now = new Date();
    this.selectedYear = now.getFullYear();
    this.selectedMonth = now.getMonth() + 1;
    this.selectedDay = now.getDate();
    this.selectedHour = now.getHours();
    this.selectedMinute = now.getMinutes();
    this.selectedDate = DateUtils.getCurrentDate();
    this.selectedTime = DateUtils.getCurrentTime();
  }

  // 生成年份列表（最近10年）
  getYearOptions(): number[] {
    const currentYear = new Date().getFullYear();
    // 显式声明years为number类型数组
    const years: number[] = [];
    for (let i = currentYear - 5; i <= currentYear + 5; i++) {
      years.push(i);
    }
    return years;
  }

  // 生成月份列表
  getMonthOptions(): number[] {
    // 先创建指定长度的数组，再映射为number类型
    return Array(12).fill(0).map((_: number, i: number) => i + 1);
  }

  // 生成日期列表（根据年份和月份）
  getDayOptions(): number[] {
    const daysInMonth = new Date(this.selectedYear, this.selectedMonth, 0).getDate();
    return Array(daysInMonth).fill(0).map((_: number, i: number) => i + 1);
  }

  // 生成小时列表
  getHourOptions(): number[] {
    // 先创建指定长度数组，再映射为number类型
    return Array(24).fill(0).map((_: number, i: number) => i);
  }

  // 生成分钟列表
  getMinuteOptions(): number[] {
    return Array(60).fill(0).map((_: number, i: number) => i);
  }


  confirmDateSelection(): void {
    this.selectedDate = `${this.selectedYear}-${this.selectedMonth.toString().padStart(2, '0')}-${this.selectedDay.toString().padStart(2, '0')}`;
    this.showDatePicker = false;
  }

  confirmTimeSelection(): void {
    this.selectedTime = `${this.selectedHour.toString().padStart(2, '0')}:${this.selectedMinute.toString().padStart(2, '0')}`;
    this.showTimePicker = false;
  }

  build() {
    Column() {
      // 顶部标题栏
      CommonNavBar({
        options: {
          showBack: true,
          title: '编辑记录',
          onLeftClick: () =>{
            router.replaceUrl({ url: 'pages/DetailPage' })// 右侧按钮点击事件（可选）
          },
          rightText: this.getSaveButtonState().text,
          onRightClick: () => {
            const buttonState = this.getSaveButtonState();
            if (buttonState.enabled) {
              this.updateRecord();
            }
          }
        }
      });

      // 滚动内容区域
      Scroll() {
        Column({ space: 24 }) {
          // 记录ID显示
          if (this.recordId) {
            Column() {
              Text('记录ID: ' + this.recordId)
                .fontSize(12)
                .fontColor('#999999')
                .width('100%')
                .textAlign(TextAlign.Center)
                .margin({ bottom: 8 });
            }
            .width('100%')
            .padding(8)
            .backgroundColor('#F2F2F7')
            .borderRadius(8)
            .margin({ left: 20, right: 20, top: 10 });
          }

          // 金额输入区域
          Column() {
            Text('金额')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 8 });
            Row() {
              Text('¥')
                .fontSize(36)
                .fontColor('#000000')
                .fontWeight(FontWeight.Bold)
                .margin({ right: 12 });
              TextInput({ placeholder: '0.00', text: this.amount })
                .fontSize(48)
                .fontColor('#000000')
                .fontWeight(FontWeight.Bold)
                .width('70%')
                .onChange((value: string) => {
                  // 输入验证：只允许数字和小数点
                  const filteredValue = value.replace(/[^0-9.]/g, '');
                  const parts = filteredValue.split('.');
                  if (parts.length > 2) {
                    this.amount = parts[0] + '.' + parts.slice(1).join('');
                  } else {
                    this.amount = filteredValue;
                  }
                });
            }
            .alignItems(VerticalAlign.Bottom);
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 20, right: 20 });

          // 支出/收入类型选择
          Row() {
            Button('支出', { type: ButtonType.Normal })
              .flexGrow(1)
              .height(48)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.recordType === 'expense' ? '#FF3B30' : '#F2F2F7')
              .fontColor(this.recordType === 'expense' ? '#FFFFFF' : '#000000')
              .borderRadius(8)
              .margin({ right: 12 })
              .opacity(this.recordType === 'expense' ? 1 : 0.7)
              .onClick(() => {
                this.recordType = 'expense';
                // 切换为支出时默认选择第一个支出分类
                if (this.expenseCategories.length > 0 && !this.selectedCategory) {
                  this.selectedCategory = this.expenseCategories[0];
                }
                this.currentType = CategoryType.EXPENSE;
              });
            Button('收入', { type: ButtonType.Normal })
              .flexGrow(1)
              .height(48)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.recordType === 'income' ? '#34C759' : '#F2F2F7')
              .fontColor(this.recordType === 'income' ? '#FFFFFF' : '#000000')
              .borderRadius(8)
              .opacity(this.recordType === 'income' ? 1 : 0.7)
              .onClick(() => {
                this.recordType = 'income';
                // 切换为收入时默认选择第一个收入分类
                if (this.incomeCategories.length > 0 && !this.selectedCategory) {
                  this.selectedCategory = this.incomeCategories[0];
                }
                this.currentType = CategoryType.INCOME;
              });
          }
          .width('100%')
          .padding({ left: 20, right: 20 });

          // 分类选择区域
          Stack() {
            // 分类选择触发行
            Row() {
              Text('分类')
                .fontSize(16)
                .fontColor('#000000')
                .fontWeight(FontWeight.Medium);
              Blank();
              if (this.selectedCategory) {
                Row() {
                  // 分类颜色标记
                  Circle({ width: 12, height: 12 })
                    .fill(this.selectedCategory.color);
                  // 分类名称
                  Text(this.selectedCategory.name)
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ left: 8 });
                }
              } else {
                Text('请选择分类')
                  .fontSize(14)
                  .fontColor('#999999');
              }
            }
            .width('100%')
            .padding({
              top: 16,
              bottom: 16,
              left: 20,
              right: 20
            })
            .onClick(() => {
              // 点击显示分类选择弹窗
              this.showCategoryPicker = true;
            });

            // 分类选择弹窗（显示时触发）
            if (this.showCategoryPicker) {
              // 弹窗背景（半透明遮罩）
              Column() {
                // 弹窗内容容器
                Column() {
                  // 弹窗标题栏
                  Row() {
                    Text('选择分类')
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#000000');
                    Blank();
                    Button('关闭')
                      .fontSize(14)
                      .fontColor('#007AFF')
                      .backgroundColor('#FFFFFF')
                      .onClick(() => {
                        this.showCategoryPicker = false;
                      });
                  }
                  .width('100%')
                  .padding({
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: 16
                  });

                  // 弹窗内支出/收入切换
                  Row() {
                    Button('支出', { type: ButtonType.Normal })
                      .flexGrow(1)
                      .height(40)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor(this.currentType === CategoryType.EXPENSE ? '#FF3B30' : '#F2F2F7')
                      .fontColor(this.currentType === CategoryType.EXPENSE ? '#FFFFFF' : '#000000')
                      .borderRadius(20)
                      .margin({ right: 8 })
                      .onClick(() => {
                        this.currentType = CategoryType.EXPENSE;
                      });
                    Button('收入', { type: ButtonType.Normal })
                      .flexGrow(1)
                      .height(40)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor(this.currentType === CategoryType.INCOME ? '#34C759' : '#F2F2F7')
                      .fontColor(this.currentType === CategoryType.INCOME ? '#FFFFFF' : '#000000')
                      .borderRadius(20)
                      .onClick(() => {
                        this.currentType = CategoryType.INCOME;
                      });
                  }
                  .justifyContent(FlexAlign.SpaceAround)
                  .margin({ bottom: 16 })
                  .padding({ left: 20, right: 20 })
                  .width('100%');

                  // 分类列表（滚动布局，限制高度）
                  Scroll() {
                    Flex({
                      wrap: FlexWrap.Wrap,
                      justifyContent: FlexAlign.Start,
                    }) {
                      ForEach(
                        this.categoryList.filter(item => item.type === this.currentType),
                        (category: Category) => {
                          Flex({
                            direction: FlexDirection.Column,
                            alignItems: ItemAlign.Center
                          }) {
                            // 分类图标容器（圆形）
                            Column() {
                              Image($r(`app.media.category_${category.icon}`))
                                .width(36)
                                .height(36)
                                .objectFit(ImageFit.Contain)
                                .onError(() => {
                                  this.isIconError = true;
                                });

                              if (this.isIconError) {
                                Image($r('app.media.category_default'))
                                  .width(36)
                                  .height(36)
                                  .objectFit(ImageFit.Contain);
                              }
                            }
                            .width(68)
                            .height(68)
                            .justifyContent(FlexAlign.Center)
                            .alignItems(HorizontalAlign.Center)
                            .backgroundColor(this.selectedCategory?.id === category.id ? category.color : '#F2F2F7')
                            .border({
                              width: this.selectedCategory?.id === category.id ? 2 : 0,
                              color: category.color,
                              style: BorderStyle.Solid
                            })
                            .borderRadius(34)
                            .margin({ bottom: 8 });

                            // 分类名称
                            Text(category.name)
                              .fontSize(13)
                              .fontColor('#000000')
                              .textAlign(TextAlign.Center)
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                              .width('100%');
                          }
                          .width('25%')
                          .padding({ left: 4, right: 4 })
                          .onClick(() => {
                            this.selectedCategory = category;
                            // 同步更新记录类型
                            this.recordType = category.type === CategoryType.EXPENSE ? 'expense' : 'income';
                            this.showCategoryPicker = false;
                          });
                        }, (category: Category) => category.id);
                    }
                    .width('100%')
                    .padding({ left: 20, right: 20, bottom: 20 });
                  }
                  .height(280)
                  .width('100%')
                  .scrollBar(BarState.On);
                }
                .width('100%')
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .margin({ left: 20, right: 20, top: 10 })
                .zIndex(99);
              }
              .width('100%')
              .height('100%')
              .backgroundColor('rgba(0,0,0,0.3)')
              .position({ top: 0, left: 0, right: 0 })
              .onClick(() => {
                this.showCategoryPicker = false;
              });
            }

            // 分割线
            Divider()
              .color('#F2F2F7');
          }
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 20, right: 20 });

          // 描述输入区域
          Column() {
            Row() {
              Text('描述')
                .fontSize(16)
                .fontColor('#000000')
                .fontWeight(FontWeight.Medium);
              Blank();
              Text(`${this.description.length}/30`)
                .fontSize(12)
                .fontColor(this.description.length > 30 ? '#FF3B30' : '#8E8E93');
            }
            .width('100%')
            .padding({ top: 16, left: 20, right: 20 });

            TextArea({ placeholder: '请输入交易描述...', text: this.description })
              .fontSize(16)
              .fontColor('#000000')
              .width('100%')
              .height(100)
              .padding(20)
              .backgroundColor('#F9F9F9')
              .borderRadius(12)
              .margin({
                top: 12,
                bottom: 16,
                left: 20,
                right: 20
              })
              .onChange((value: string) => {
                if (value.length <= 30) {
                  this.description = value;
                }
              });

            // 快捷描述选项
            if (this.description.length === 0) {
              Flex({
                justifyContent: FlexAlign.Start,
                wrap: FlexWrap.Wrap
              }) {
                ForEach(this.quickDescriptions, (desc: string) => {
                  Button(desc)
                    .fontSize(14)
                    .fontColor('#007AFF')
                    .backgroundColor('#F0F8FF')
                    .borderRadius(16)
                    .padding({
                      left: 12,
                      right: 12,
                      top: 6,
                      bottom: 6
                    })
                    .onClick(() => {
                      this.description = desc;
                    });
                });
              }
              .width('100%')
              .padding({ left: 20, right: 20, bottom: 16 });
            }
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 20, right: 20 });

          // 时间选择区域
          Stack() {
            Column() {
              Row() {
                Text('时间')
                  .fontSize(16)
                  .fontColor('#000000')
                  .fontWeight(FontWeight.Medium);
                Blank();
                Button('现在')
                  .fontSize(14)
                  .fontColor('#007AFF')
                  .backgroundColor('#F2F2F7')
                  .borderRadius(4)
                  .padding({
                    left: 12,
                    right: 12,
                    top: 6,
                    bottom: 6
                  })
                  .onClick(() => {
                    this.setToNow();
                  });
              }
              .width('100%')
              .padding({ left: 20, right: 20 });

              // 时间显示，点击可以修改
              Row() {
                // 日期部分，点击打开日期选择器
                Column() {
                  Text(this.selectedDate)
                    .fontSize(16)
                    .fontColor('#007AFF')
                    .fontWeight(FontWeight.Medium)
                    .onClick(() => {
                      this.showDatePicker = true;
                    });
                  Text(this.getWeekday())
                    .fontSize(12)
                    .fontColor('#666666')
                    .margin({ top: 2 });
                }
                .margin({ right: 20 })
                .onClick(() => {
                  this.showDatePicker = true;
                });

                // 时间部分，点击打开时间选择器
                Text(this.selectedTime)
                  .fontSize(16)
                  .fontColor('#007AFF')
                  .fontWeight(FontWeight.Medium)
                  .onClick(() => {
                    this.showTimePicker = true;
                  });
              }
              .width('100%')
              .padding({ left: 20, right: 20 })
              .margin({ top: 12, bottom: 16 })
              .justifyContent(FlexAlign.Start);
            }

            // 时间选择器上方固定位置（作为弹窗定位参考）
            Column()
              .width('100%')
              .height(1)
              .backgroundColor('#00000000')
              .position({ x: 0, y: -340 }) // 固定位置
              .id('pickerPosition');

            // 日期选择器弹窗 - 固定在固定位置
            if (this.showDatePicker) {
              Column() {
                // 日期选择器内容
                Column() {
                  // 标题栏
                  Row() {
                    Text('选择日期')
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#000000');
                    Blank();
                    Button('关闭')
                      .fontSize(14)
                      .fontColor('#007AFF')
                      .backgroundColor('#FFFFFF')
                      .onClick(() => {
                        this.showDatePicker = false;
                      });
                  }
                  .width('100%')
                  .padding({
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: 16
                  });

                  // 日期选择器
                  Row({ space: 12 }) {
                    // 年份选择
                    Column() {
                      Text('年')
                        .fontSize(14)
                        .fontColor('#666666')
                        .margin({ bottom: 8 });
                      Scroll() {
                        Column({ space: 8 }) {
                          ForEach(this.getYearOptions(), (year: number) => {
                            Text(year.toString())
                              .fontSize(16)
                              .fontColor(this.selectedYear === year ? '#007AFF' : '#000000')
                              .fontWeight(this.selectedYear === year ? FontWeight.Bold : FontWeight.Normal)
                              .padding(8)
                              .backgroundColor(this.selectedYear === year ? '#E6F2FF' : '#FFFFFF')
                              .borderRadius(8)
                              .onClick(() => {
                                this.selectedYear = year;
                              });
                          })
                        }
                      }
                      .height(200)
                      .width('30%')
                    }

                    // 月份选择
                    Column() {
                      Text('月')
                        .fontSize(14)
                        .fontColor('#666666')
                        .margin({ bottom: 8 });
                      Scroll() {
                        Column({ space: 8 }) {
                          ForEach(this.getMonthOptions(), (month: number) => {
                            Text(month.toString())
                              .fontSize(16)
                              .fontColor(this.selectedMonth === month ? '#007AFF' : '#000000')
                              .fontWeight(this.selectedMonth === month ? FontWeight.Bold : FontWeight.Normal)
                              .padding(8)
                              .backgroundColor(this.selectedMonth === month ? '#E6F2FF' : '#FFFFFF')
                              .borderRadius(8)
                              .onClick(() => {
                                this.selectedMonth = month;
                              });
                          })
                        }
                      }
                      .height(200)
                      .width('30%')
                    }

                    // 日期选择
                    Column() {
                      Text('日')
                        .fontSize(14)
                        .fontColor('#666666')
                        .margin({ bottom: 8 });
                      Scroll() {
                        Column({ space: 8 }) {
                          ForEach(this.getDayOptions(), (day: number) => {
                            Text(day.toString())
                              .fontSize(16)
                              .fontColor(this.selectedDay === day ? '#007AFF' : '#000000')
                              .fontWeight(this.selectedDay === day ? FontWeight.Bold : FontWeight.Normal)
                              .padding(8)
                              .backgroundColor(this.selectedDay === day ? '#E6F2FF' : '#FFFFFF')
                              .borderRadius(8)
                              .onClick(() => {
                                this.selectedDay = day;
                              });
                          })
                        }
                      }
                      .height(200)
                      .width('30%')
                    }
                  }
                  .width('100%')
                  .padding({ left: 20, right: 20 })

                  // 操作按钮
                  Row({ space: 16 }) {
                    Button('取消')
                      .fontSize(16)
                      .fontColor('#666666')
                      .backgroundColor('#F2F2F7')
                      .borderColor('#DDDDDD')
                      .borderWidth(1)
                      .borderRadius(8)
                      .width('45%')
                      .height(48)
                      .onClick(() => {
                        this.showDatePicker = false;
                      });

                    Button('确定')
                      .fontSize(16)
                      .fontColor('#FFFFFF')
                      .backgroundColor('#007AFF')
                      .borderRadius(8)
                      .width('45%')
                      .height(48)
                      .onClick(() => {
                        this.confirmDateSelection();
                      });
                  }
                  .width('100%')
                  .padding({ left: 20, right: 20, bottom: 20, top: 16 });
                }
                .width('90%')
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .margin({ left: 20, right: 20 })
                .shadow({ radius: 16, color: '#000000', offsetX: 0, offsetY: 4 })
                .zIndex(99);
              }
              .width('100%')
              .position({
                x: 0,
                y: -340  // 与固定位置对齐
              })
              .onClick(() => {
                // 阻止点击事件冒泡，避免点击弹窗外部关闭
              });
            }

            // 时间选择器弹窗 - 固定在相同位置
            if (this.showTimePicker) {
              Column() {
                // 时间选择器内容
                Column() {
                  // 标题栏
                  Row() {
                    Text('选择时间')
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#000000');
                    Blank();
                    Button('关闭')
                      .fontSize(14)
                      .fontColor('#007AFF')
                      .backgroundColor('#FFFFFF')
                      .onClick(() => {
                        this.showTimePicker = false;
                      });
                  }
                  .width('100%')
                  .padding({
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: 16
                  });

                  // 时间选择器
                  Row({ space: 12 }) {
                    // 小时选择
                    Column() {
                      Text('时')
                        .fontSize(14)
                        .fontColor('#666666')
                        .margin({ bottom: 8 });
                      Scroll() {
                        Column({ space: 8 }) {
                          ForEach(this.getHourOptions(), (hour: number) => {
                            Text(hour < 10 ? '0' + hour.toString() : hour.toString())
                              .fontSize(16)
                              .fontColor(this.selectedHour === hour ? '#007AFF' : '#000000')
                              .fontWeight(this.selectedHour === hour ? FontWeight.Bold : FontWeight.Normal)
                              .padding(8)
                              .backgroundColor(this.selectedHour === hour ? '#E6F2FF' : '#FFFFFF')
                              .borderRadius(8)
                              .onClick(() => {
                                this.selectedHour = hour;
                              });
                          })
                        }
                      }
                      .height(200)
                      .width('45%')
                    }

                    // 分钟选择
                    Column() {
                      Text('分')
                        .fontSize(14)
                        .fontColor('#666666')
                        .margin({ bottom: 8 });
                      Scroll() {
                        Column({ space: 8 }) {
                          ForEach(this.getMinuteOptions(), (minute: number) => {
                            Text(minute < 10 ? '0' + minute.toString() : minute.toString())
                              .fontSize(16)
                              .fontColor(this.selectedMinute === minute ? '#007AFF' : '#000000')
                              .fontWeight(this.selectedMinute === minute ? FontWeight.Bold : FontWeight.Normal)
                              .padding(8)
                              .backgroundColor(this.selectedMinute === minute ? '#E6F2FF' : '#FFFFFF')
                              .borderRadius(8)
                              .onClick(() => {
                                this.selectedMinute = minute;
                              });
                          })
                        }
                      }
                      .height(200)
                      .width('45%')
                    }
                  }
                  .width('100%')
                  .padding({ left: 20, right: 20 })

                  // 操作按钮
                  Row({ space: 16 }) {
                    Button('取消')
                      .fontSize(16)
                      .fontColor('#666666')
                      .backgroundColor('#F2F2F7')
                      .borderColor('#DDDDDD')
                      .borderWidth(1)
                      .borderRadius(8)
                      .width('45%')
                      .height(48)
                      .onClick(() => {
                        this.showTimePicker = false;
                      });

                    Button('确定')
                      .fontSize(16)
                      .fontColor('#FFFFFF')
                      .backgroundColor('#007AFF')
                      .borderRadius(8)
                      .width('45%')
                      .height(48)
                      .onClick(() => {
                        this.confirmTimeSelection();
                      });
                  }
                  .width('100%')
                  .padding({ left: 20, right: 20, bottom: 20, top: 16 });
                }
                .width('90%')
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .margin({ left: 20, right: 20 })
                .shadow({ radius: 16, color: '#000000', offsetX: 0, offsetY: 4 })
                .zIndex(99);
              }
              .width('100%')
              .position({
                x: 0,
                y: -340  // 与固定位置对齐，两个选择器在同一个位置
              })
              .onClick(() => {
                // 阻止点击事件冒泡
              });
            }
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 20, right: 20 });

          // 操作按钮区域
          Column({ space: 12 }) {
            // 保存提示
            if (this.hasChanges() && !this.isSaving) {
              Column() {
                Row() {
                  Circle({ width: 8, height: 8 })
                    .fill('#FF9500')
                    .margin({ right: 8 });
                  Text('记录已修改，点击顶部"保存"按钮更新记录')
                    .fontSize(14)
                    .fontColor('#FF9500');
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFF4E5')
              .borderRadius(12);
            }

            if (this.isSaving) {
              Column() {
                Row() {
                  LoadingProgress()
                    .color('#007AFF')
                    .width(20)
                    .height(20)
                    .margin({ right: 8 });
                  Text('正在保存...')
                    .fontSize(14)
                    .fontColor('#007AFF');
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#E6F2FF')
              .borderRadius(12);
            }

            // 操作按钮
            Row({ space: 16 }) {
              Button('重置')
                .fontSize(16)
                .fontColor('#666666')
                .backgroundColor('#F2F2F7')
                .borderColor('#DDDDDD')
                .borderWidth(1)
                .borderRadius(8)
                .width('30%')
                .height(48)
                .onClick(() => {
                  this.resetToOriginal();
                })
                .enabled(this.hasChanges() && !this.isSaving);

              Button('删除记录')
                .fontSize(16)
                .fontColor('#FF3B30')
                .backgroundColor('#FFFFFF')
                .borderColor('#FF3B30')
                .borderWidth(1)
                .borderRadius(8)
                .width('65%')
                .height(48)
                .onClick(() => {
                  this.deleteRecord();
                })
                .enabled(!this.isSaving);
            }
            .width('100%');
          }
          .width('100%')
          .padding({ left: 20, right: 20 });
        }
        .width('100%')
        .padding({ top: 20, bottom: 40 });
      }
      .width('100%')
      .height('90%')
      .backgroundColor('#F2F2F7')
      .scrollBar(BarState.Off);

      // 底部导航栏
      CommonTabBar({
        tabItems: this.tabItems,
        activeColor: '#FF5722',
        inactiveColor: '#999999'
      })
        .width('100%')
        .height(56)
        .backgroundColor('#FFFFFF');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7');
  }
}