export class DateUtils {
  static dateTimeToTimestamp(selectedDate: string, selectedTime: string): number {
    throw new Error('Method not implemented.');
  }
  // 获取当前日期字符串
  static getCurrentDate(): string {
    const now = new Date();
    return now.toISOString().split('T')[0]; // YYYY-MM-DD
  }

  // 获取当前时间字符串
  static getCurrentTime(): string {
    const now = new Date();
    return now.toLocaleTimeString('zh-CN', { hour12: false, hour: '2-digit', minute: '2-digit' });
  }

  // 获取当前时间戳
  static getCurrentTimestamp(): number {
    return new Date().getTime();
  }

  // 格式化日期为中文
  static formatChineseDate(dateStr: string): string {
    const date = new Date(dateStr);
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    const weekday = weekdays[date.getDay()];
    return `${month}月${day}日 周${weekday}`;
  }

  // 获取昨天的日期
  static getYesterdayDate(): string {
    const now = new Date();
    const yesterday = new Date(now);
    yesterday.setDate(now.getDate() - 1);
    return yesterday.toISOString().split('T')[0];
  }
}
