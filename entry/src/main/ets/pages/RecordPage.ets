import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

import { RecordStore, categories } from '../data/RecordStore';
import { DateUtils } from '../utils/DateUtils';
import { Record, CategoryType, Category, TabItem } from '../models/Record';
import { CommonNavBar } from '../components/CommonNavBar';
import { CommonTabBar, DefaultTabItems } from '../components/CommonTabBar';

@Entry
@Component
export struct RecordPage {
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
  @State currentType: CategoryType = CategoryType.EXPENSE;
  @State isIconError: boolean = false;
  // ===== 时间选择器（来自 EditPage）=====
  @State selectedDate: string = DateUtils.getCurrentDate();
  @State selectedTime: string = DateUtils.getCurrentTime();
  @State selectedYear: number = new Date().getFullYear();
  @State selectedMonth: number = new Date().getMonth() + 1;
  @State selectedDay: number = new Date().getDate();
  @State selectedHour: number = new Date().getHours();
  @State selectedMinute: number = new Date().getMinutes();
  @State showDatePicker: boolean = false;
  @State showTimePicker: boolean = false;
  private categoryList = categories;

  async aboutToAppear(): Promise<void> {
    await this.recordStore.ready();
    this.expenseCategories = [...this.recordStore.getExpenseCategories()];
    this.incomeCategories = [...this.recordStore.getIncomeCategories()];
    if (this.expenseCategories.length > 0) {
      this.selectedCategory = this.expenseCategories[0];
    }
  }

  // 保存记账记录
  async saveRecord(): Promise<void> {
    if (!this.amount || parseFloat(this.amount) <= 0) {
      console.log('请输入有效金额');
      return;
    }
    if (!this.selectedCategory) {
      console.log('请选择分类');
      return;
    }
    const record: Record = {
      id: DateUtils.getCurrentTimestamp().toString(),
      amount: parseFloat(this.amount),
      type: this.recordType,
      category: this.selectedCategory.id,
      description: this.description || this.selectedCategory.name,
      date: DateUtils.getCurrentDate(),
      time: DateUtils.getCurrentTime(),
      timestamp: DateUtils.getCurrentTimestamp()
    };
    await this.recordStore.addRecord(record);
    console.log('保存成功：', record);
    // 返回主页面并携带刷新参数
    router.back({
      url: 'pages/MainPage',
      params: { refresh: true }
    });
  }


  // ===== 时间选择器方法（同 EditPage）=====
  getWeekday(): string {
    const GeneratedDestructArray_1 = this.selectedDate.split('-').map(Number);
    const y = GeneratedDestructArray_1[0];
    const m = GeneratedDestructArray_1[1];
    const d = GeneratedDestructArray_1[2];
    const date = new Date(y, m - 1, d);
    return ['周日', '周一', '周二', '周三', '周四', '周五', '周六'][date.getDay()];
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
    this.selectedDate =
      `${this.selectedYear}-${this.selectedMonth.toString().padStart(2, '0')}-${this.selectedDay.toString()
        .padStart(2, '0')}`;
    this.showDatePicker = false;
  }

  confirmTimeSelection(): void {
    this.selectedTime =
      `${this.selectedHour.toString().padStart(2, '0')}:${this.selectedMinute.toString().padStart(2, '0')}`;
    this.showTimePicker = false;
  }

  build() {
    Column() {
      // 顶部标题栏
      CommonNavBar({
        options: {
          showBack: true,
          onLeftClick: () => {
            router.replaceUrl({ url: 'pages/HomePage' })// 右侧按钮点击事件（可选）
          },
          title: '记账',
          rightText: '保存', // 右侧文本按钮内容（可选）
          onRightClick: () => {
            this.saveRecord()
            router.replaceUrl({ url: 'pages/HomePage' })// 右侧按钮点击事件（可选）
          }
        }
      });

      // 滚动内容区域（和我的页面保持一致：设置height('90%')）
      Scroll() {
        Column({ space: 24 }) {
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
              TextInput({ placeholder: '0.00' })
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

          // 描述输入区域（保持原逻辑）
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
                  .padding({
                    left: 20,
                    right: 20,
                    bottom: 20,
                    top: 16
                  });
                }
                .width('90%')
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .margin({ left: 20, right: 20 })
                .shadow({
                  radius: 16,
                  color: '#000000',
                  offsetX: 0,
                  offsetY: 4
                })
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
                  .padding({
                    left: 20,
                    right: 20,
                    bottom: 20,
                    top: 16
                  });
                }
                .width('90%')
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .margin({ left: 20, right: 20 })
                .shadow({
                  radius: 16,
                  color: '#000000',
                  offsetX: 0,
                  offsetY: 4
                })
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
        }
        .width('100%')
        .height('100%') // 保留原有属性，不影响核心对齐
        .backgroundColor('#F2F2F7');
      }
      .backgroundColor('#F2F2F7')
      .width('100%')
      .height('90%') // 关键修改：添加和我的页面一致的height('90%')
      .scrollBar(BarState.Off); // 可选：和我的页面统一隐藏滚动条

      // 底部导航栏（层级、属性和我的页面完全一致）
      CommonTabBar({
        tabItems: this.tabItems,
        activeColor: '#FF5722', // 自定义选中态颜色
        inactiveColor: '#999999' // 自定义未选中态颜色
      })
        .width('100%')
        //.height(56)
        .backgroundColor('#FFFFFF');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7');
  }
}