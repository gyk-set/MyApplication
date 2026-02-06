// utils/EventManager.ts
interface GeneratedObjectLiteralInterface_1 {
  RECORD_UPDATED: string;
  RECORD_DELETED: string;
  RECORD_ADDED: string;
}

interface EventData {
  id: number;
  content: string;
  // 其他字段...
}

export class EventManager {
  private static listeners: Map<string, Function[]> = new Map();

  // 事件类型
  static readonly EVENTS: GeneratedObjectLiteralInterface_1 = {
    RECORD_UPDATED: 'record_updated',
    RECORD_DELETED: 'record_deleted',
    RECORD_ADDED: 'record_added'
  };

  // 添加事件监听
  static on(event: string, callback: Function): void {
    if (!EventManager.listeners.has(event)) {
      EventManager.listeners.set(event, []);
    }
    EventManager.listeners.get(event)!.push(callback);
  }

  // 移除事件监听
  static off(event: string, callback: Function): void {
    if (EventManager.listeners.has(event)) {
      const callbacks = EventManager.listeners.get(event)!;
      const index = callbacks.indexOf(callback);
      if (index > -1) {
        callbacks.splice(index, 1);
      }
    }
  }

  // 触发事件
  static emit(event: string, data?: EventData): void {
    if (EventManager.listeners.has(event)) {
      EventManager.listeners.get(event)!.forEach(callback => {
        try {
          callback(data);
        } catch (error) {
          console.error('事件回调执行失败:', error);
        }
      });
    }
  }

  // 清空所有监听器
  static clear(): void {
    EventManager.listeners.clear();
  }
}