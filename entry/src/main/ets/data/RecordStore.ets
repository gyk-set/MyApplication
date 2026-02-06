import preferences from '@ohos.data.preferences';
import { Record } from '../models/Record';
import { Category } from '../models/Record';
import { CategoryDistributionItem, CategoryType } from '../models/Record';
import { DateUtils } from '../utils/DateUtils';
import { getAppContext } from '../utils/AppContextHolder';
import emitter from '@ohos.events.emitter'; // 引入事件通知


export const categories: Category[] = [
  // 支出分类
  {
    id: 'food',
    name: '餐饮',
    color: '#FF6B6B',
    icon: 'restaurant',
    type: CategoryType.EXPENSE
  },
  {
    id: 'transport',
    name: '交通',
    color: '#4ECDC4',
    icon: 'directions_car',
    type: CategoryType.EXPENSE
  },
  {
    id: 'shopping',
    name: '购物',
    color: '#FFD166',
    icon: 'shopping_cart',
    type: CategoryType.EXPENSE
  },
  {
    id: 'daily',
    name: '日用品',
    color: '#6A0572',
    icon: 'home',
    type: CategoryType.EXPENSE
  },
  {
    id: 'entertainment',
    name: '娱乐',
    color: '#06D6A0',
    icon: 'sports_esports',
    type: CategoryType.EXPENSE
  },
  {
    id: 'medical',
    name: '医疗',
    color: '#118AB2',
    icon: 'medical_services',
    type: CategoryType.EXPENSE
  },
  {
    id: 'education',
    name: '教育',
    color: '#073B4C',
    icon: 'school',
    type: CategoryType.EXPENSE
  },

  // 收入分类
  {
    id: 'salary',
    name: '工资',
    color: '#34C759',
    icon: 'payments',
    type: CategoryType.INCOME
  },
  {
    id: 'investment',
    name: '投资',
    color: '#32D74B',
    icon: 'trending_up',
    type: CategoryType.INCOME
  },
  {
    id: 'gift',
    name: '红包/礼物',
    color: '#64D2FF',
    icon: 'card_giftcard',
    type: CategoryType.INCOME
  },
  {
    id: 'other_income',
    name: '其他收入',
    color: '#0A84FF',
    icon: 'attach_money',
    type: CategoryType.INCOME
  }
];

interface GeneratedTypeLiteralInterface_1 {
  totalIncome: number;
  totalExpense: number;
  balance: number;
}

interface EmitterEvent {
  eventId: number;
  eventName: string;
  data?: object;
}

export interface Data{
  todaySpend: number,
  todayIncome: number,
  yesterdayChange: string
}

interface Data1{
  todaySpend: number,
  todayIncome: number,
  balance: number
}

interface GeneratedTypeLiteralInterface_2 {
  amount: number;
  type: 'expense' | 'income';
  category: string;
  description?: string;
}

export class RecordStore {
  private static instance: RecordStore;
  public records: Record[] = [];
  public categories = categories;
  private prefs: preferences.Preferences | undefined = undefined;
  private isInitialized = false;
  private initPromise: Promise<void>;
  private dataChangedEvent = 'RECORD_DATA_CHANGED'; // 自定义事件名
  private isReady: boolean = false;





  private constructor() {
    this.initPromise = this.loadFromStorage();
  }

  static getInstance(): RecordStore {
    if (!RecordStore.instance) {
      RecordStore.instance = new RecordStore();
    }
    return RecordStore.instance;
  }

  async ready(): Promise<void> {
    await this.initPromise;
    this.isReady = true;
  }

  private async ensurePrefs(): Promise<preferences.Preferences> {
    if (this.prefs) {
      return this.prefs;
    }
    const ctx = getAppContext();
    const pref = await preferences.getPreferences(ctx, 'record_store');
    this.prefs = pref;
    return pref;
  }

  private async loadFromStorage(): Promise<void> {
    const prefs = await this.ensurePrefs();
    try {
      const stored = (await prefs.get('records', '')) as string;
      if (stored) {
        this.records = JSON.parse(stored);
        // 确保记录按时间戳倒序排序
        this.records.sort((a, b) => b.timestamp - a.timestamp);
      } else {
        // 第一次使用，没有数据，初始化为空数组
        this.records = [];
        await this.saveRecords();
      }
    } catch (err) {
      console.error('加载本地记录失败，重置为空数组:', err);
      // 出错时重置为空数组
      this.records = [];
      await this.saveRecords();
    }
    this.isInitialized = true;
  }

  private async saveRecords(): Promise<void> {
    try {
      const prefs = await this.ensurePrefs();
      await prefs.put('records', JSON.stringify(this.records));
      await prefs.flush();

      // 2. 同步写入公共Preferences（供卡片读取）
      const ctx = getAppContext();
      const publicPref = await preferences.getPreferences(ctx, 'public_record_store');
      await publicPref.put('todaySpend', this.getTodayExpense());
      await publicPref.put('todayIncome', this.getTodayIncome());
      await publicPref.put('yesterdayChange', this.getExpenseChangePercent());
      await publicPref.flush();

      console.log('数据已同步到公共存储');
    } catch (err) {
      console.error('保存记录失败:', err);
      // 这里可以添加重试逻辑或者错误处理
    }
  }
  // ========== 新增：数据变更通知核心方法 ==========
  // 发送数据变更事件
  private emitDataChanged(): void {
    // 使用显式接口声明类型，不再用any
    const event: EmitterEvent = {
      eventId: 1, // 自定义唯一ID
      eventName: this.dataChangedEvent,
      data: []
    };
    // 对emitter.emit做类型断言（仅针对方法入参）
    emitter.emit(this.dataChangedEvent, {});
    console.log('RecordStore: 数据变更通知已发送');
  }

  // 监听数据变更
  public onDataChanged(callback: () => void): void {
    const event: EmitterEvent = {
      eventId: 1,
      eventName: this.dataChangedEvent
    };
    emitter.on(this.dataChangedEvent, callback);
  }

  // 取消监听数据变更
  public offDataChanged(callback: () => void): void {
    const event: EmitterEvent = {
      eventId: 1,
      eventName: this.dataChangedEvent
    };
    emitter.off(this.dataChangedEvent, callback);
  }

  // 内部方法：同步写入内存并排序（不触发存储）
  private addRecordDirect(record: Record): void {
    this.records.unshift(record); // 使用unshift将新记录添加到数组开头
    // 由于记录已经是按时间戳倒序排序的，添加新记录后重新排序
    this.records.sort((a, b) => b.timestamp - a.timestamp);
  }

  // 添加记录（外部接口）
  async addRecord(record: Record): Promise<void> {
    await this.ready();
    this.addRecordDirect(record);
    await this.saveRecords();
  }

  // 删除记录
  async deleteRecord(recordId: string): Promise<boolean> {
    await this.ready();
    const initialLength = this.records.length;
    this.records = this.records.filter(record => record.id !== recordId);

    if (this.records.length !== initialLength) {
      await this.saveRecords();
      return true;
    }
    return false;
  }

  // 更新记录
  async updateRecord(updatedRecord: Record): Promise<boolean> {
    await this.ready();
    const index = this.records.findIndex(record => record.id === updatedRecord.id);

    if (index !== -1) {
      this.records[index] = updatedRecord;
      // 更新后重新排序
      this.records.sort((a, b) => b.timestamp - a.timestamp);
      await this.saveRecords();
      return true;
    }
    return false;
  }
  // 获取所有记录
  getAllRecords(): Record[] {
    return this.records;
  }

  // 根据ID获取记录
  getRecordById(id: string): Record | undefined {
    return this.records.find(record => record.id === id);
  }

  // 获取今日记录
  getTodayRecords(): Record[] {
    const today = DateUtils.getCurrentDate();
    return this.records.filter(record => record.date === today);
  }

  // 获取昨日记录
  getYesterdayRecords(): Record[] {
    const yesterday = DateUtils.getYesterdayDate();
    return this.records.filter(record => record.date === yesterday);
  }

  // 获取指定日期的记录
  getRecordsByDate(date: string): Record[] {
    return this.records.filter(record => record.date === date);
  }

  // 获取指定月份的记录
  getRecordsByMonth(year: number, month: number): Record[] {
    return this.records.filter(record => {
      const recordDate = new Date(record.timestamp);
      return recordDate.getFullYear() === year && recordDate.getMonth() === month;
    });
  }

  // 获取今日支出总额
  getTodayExpense(): number {
    const todayRecords = this.getTodayRecords();
    return todayRecords
      .filter(record => record.type === 'expense')
      .reduce((sum, record) => sum + record.amount, 0);
  }

  // 获取今日收入总额
  getTodayIncome(): number {
    const todayRecords = this.getTodayRecords();
    return todayRecords
      .filter(record => record.type === 'income')
      .reduce((sum, record) => sum + record.amount, 0);
  }

  // 获取昨日支出总额
  getYesterdayExpense(): number {
    const yesterdayRecords = this.getYesterdayRecords();
    return yesterdayRecords
      .filter(record => record.type === 'expense')
      .reduce((sum, record) => sum + record.amount, 0);
  }

  // 计算较昨日变化百分比
  getExpenseChangePercent(): string {
    const todayExpense = this.getTodayExpense();
    const yesterdayExpense = this.getYesterdayExpense();

    if (yesterdayExpense === 0) {
      return todayExpense > 0 ? '+100%' : '0%';
    }

    const change = ((todayExpense - yesterdayExpense) / yesterdayExpense) * 100;
    return change >= 0 ? `+${change.toFixed(0)}%` : `${change.toFixed(0)}%`;
  }

  // 获取今日消费分类分布
  getTodayCategoryDistribution(): CategoryDistributionItem[] {
    const todayExpense = this.getTodayExpense();
    if (todayExpense === 0) {
      return [];
    }

    const todayExpenseRecords = this.getTodayRecords()
      .filter(record => record.type === 'expense');

    const categoryMap = new Map<string, number>();

    // 计算每个分类的总额
    todayExpenseRecords.forEach(record => {
      const current = categoryMap.get(record.category) || 0;
      categoryMap.set(record.category, current + record.amount);
    });

    // 转换为数组并计算百分比
    const result = Array.from(categoryMap.entries()).map((entry) => {
      // 内部解构（ArkTS允许函数内解构，仅禁止参数解构）
      const categoryId = entry[0];
      const amount = entry[1];
      const category = this.getCategoryById(categoryId);
      const percent = (amount / todayExpense) * 100;

      // 对象字面量指定CategoryDistributionItem类型
      const distributionItem: CategoryDistributionItem = {
        category: category,
        amount: amount,
        percent: percent,
      };
      return distributionItem;
    });

    // 按金额降序排序
    return result.sort((a, b) => b.amount - a.amount);
  }

  // 获取最近记录（今日+昨日）
  getRecentRecords(limit: number = 10): Record[] {
    const today = DateUtils.getCurrentDate();
    const yesterday = DateUtils.getYesterdayDate();

    return this.records
      .filter(record => record.date === today || record.date === yesterday)
      .slice(0, limit);
  }

  // 获取分类信息
  getAllCategories(): Category[] {
    return this.categories;
  }

  getCategoryById(id: string): Category {
    return this.categories.find(cat => cat.id === id) || this.categories[0];
  }

  getExpenseCategories(): Category[] {
    return this.categories.filter(cat => cat.type === 'expense');
  }

  getIncomeCategories(): Category[] {
    return this.categories.filter(cat => cat.type === 'income');
  }

  // 获取指定时间范围内的统计
  getStatistics(startDate?: number, endDate?: number): GeneratedTypeLiteralInterface_1 {
    let filteredRecords = this.records;

    if (startDate !== undefined && endDate !== undefined) {
      filteredRecords = this.records.filter(record =>
      record.timestamp >= startDate && record.timestamp <= endDate
      );
    }

    const totalIncome = filteredRecords
      .filter(record => record.type === 'income')
      .reduce((sum, record) => sum + record.amount, 0);

    const totalExpense = filteredRecords
      .filter(record => record.type === 'expense')
      .reduce((sum, record) => sum + record.amount, 0);

    const balance = totalIncome - totalExpense;

    return {
      totalIncome,
      totalExpense,
      balance
    };
  }

  // 清除所有数据（用于调试或重置）
  async clearAllData(): Promise<void> {
    this.records = [];
    await this.saveRecords();
  }

  // 检查是否初始化完成
  public isRecordReady(): boolean {
    return this.isReady;
  }

  // RecordStore.ts 中需要添加以下方法（在现有类中）

  // 添加卡片专用方法
  public getCardStatistics(): Data {
    return {
      todaySpend: this.getTodayExpense(),
      todayIncome: this.getTodayIncome(),
      yesterdayChange: this.getExpenseChangePercent()
    };
  }
  public getCardStatistics1(): Data1 {
    return {
      todaySpend: this.getTodayExpense(),
      todayIncome: this.getTodayIncome(),
      balance: this.getTodayIncome() - this.getTodayExpense()
    };
  }

  // 从卡片添加记录（供卡片调用）
  async addRecordFromCard(recordData: GeneratedTypeLiteralInterface_2): Promise<boolean> {
    try {
      await this.ready();

      const record: Record = {
        id: DateUtils.getCurrentTimestamp().toString(),
        amount: recordData.amount,
        type: recordData.type,
        category: recordData.category,
        description: recordData.description || this.getCategoryById(recordData.category).name,
        date: DateUtils.getCurrentDate(),
        time: DateUtils.getCurrentTime(),
        timestamp: DateUtils.getCurrentTimestamp()
      };

      this.addRecordDirect(record);
      await this.saveRecords();
      this.emitDataChanged(); // 触发数据变更通知

      return true;
    } catch (err) {
      console.error('从卡片添加记录失败:', err);
      return false;
    }
  }

  // 获取常用分类（用于卡片快速选择）
  public getCommonCategories(): Category[] {
    // 返回常用的分类：餐饮、交通、购物、工资、其他收入
    const commonIds = ['food', 'transport', 'shopping', 'salary', 'other_income'];
    return this.categories.filter(cat => commonIds.includes(cat.id));
  }
}