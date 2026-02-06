// 记账记录模型
export interface Record {
  id: string; // 记录ID
  amount: number; // 金额
  type: 'expense' | 'income'; // 类型：支出/收入
  category: string; // 分类
  description: string; // 描述
  date: string; // 日期 YYYY-MM-DD
  time: string; // 时间 HH:mm
  timestamp: number; // 时间戳
}

export interface FeatureItems {
  title: string;
  desc: string
}

export interface TabItem {
  title: string;
  iconSelected: Resource; // 选中态图标（media目录下）
  iconNormal: Resource; // 未选中态图标（media目录下）
  pageUrl: string; // 跳转的页面路径
}

export interface Items {
  title: string,
  iconSelected: Resource,
  iconNormal: Resource
}

// 定义分类类型枚举
export enum CategoryType {
  EXPENSE = 'expense', // 支出
  INCOME = 'income' // 收入
}

// 消费分类模型
export interface Category {
  id: string; // 分类ID
  name: string; // 分类名称
  color: string; // 分类颜色
  icon: string; // 分类图标
  type: CategoryType; // 分类类型
}

// 1. 定义接口
export interface BudgetInfo {
  spent: number;
  remaining: number;
  total: number;
}

// 1. 定义路由参数接口
export interface RecordParams {
  recordId: string | number;
}


export interface CategoryItem {
  name: string,
  amount: number,
  percent: number,
  color: string
}

export interface LoginButton {
  text: string,
  icon: string, // 图片资源名（需放在media目录下）
  type: string
}

export interface MonthlyTrend {
  day: string,
  amount: number,
  month: string; // 新增month属性
  expense: number;
  income: number;
  balance: number;
}

export interface ConsumptionRanking {
  category: string,
  amount: number
}

// 定义分类分布项的接口（复用Category）
export interface CategoryDistributionItem {
  category: Category; // 关联已有的消费分类模型
  amount: number;
  percent: number;
  //recordIds: string[]; // 新增：存储该分类下的记录ID列表
}

// 权限信息接口
export interface PermissionItem {
  name: string;
  description: string;
  icon: string; // 图标资源名称
}

export interface NavBarOptions {
  title?: string; // 导航栏标题
  showBack?: boolean; // 是否显示返回按钮（默认true）
  rightText?: string; // 右侧文本按钮内容（可选）
  onRightClick?: () => void; // 右侧按钮点击事件（可选）
  backgroundColor?: string; // 导航栏背景色（默认白色）
  titleColor?: string; // 标题颜色（默认黑色）
  backIconColor?: string; // 返回按钮颜色（默认黑色）
}

export interface Statistics {
  totalIncome: number;
  totalExpense: number;
  balance: number;
}