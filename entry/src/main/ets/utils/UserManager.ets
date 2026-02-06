import dataPreferences from '@ohos.data.preferences';

// utils/UserStateManager.ts
export class UserStateManager {
  // 保存登录状态
  static async saveLoginState(username: string): Promise<void> {
    try {
      // 保存到AppStorage
      AppStorage.setOrCreate('currentUsername', username);
      AppStorage.setOrCreate('isLoggedIn', true);
      AppStorage.setOrCreate('lastLoginTime', new Date().toISOString());

      // 也可以保存到Preferences
      const preferences = await dataPreferences.getPreferences(getContext(), 'user_preferences');
      await preferences.put('currentUsername', username);
      await preferences.put('isLoggedIn', true);
      await preferences.flush();
    } catch (error) {
      console.error('保存登录状态失败:', error);
    }
  }

  // 获取当前登录用户
  static getCurrentUsername(): string {
    try {
      const username = AppStorage.get('currentUsername') as string;
      return username || '';
    } catch (error) {
      console.error('获取登录用户失败:', error);
      return '';
    }
  }

  // 检查是否已登录
  static isLoggedIn(): boolean {
    try {
      const isLoggedIn = AppStorage.get('isLoggedIn') as boolean;
      return !!isLoggedIn;
    } catch (error) {
      console.error('检查登录状态失败:', error);
      return false;
    }
  }

  // 清除登录状态（登出时调用）
  static async clearLoginState(): Promise<void> {
    try {
      AppStorage.delete('currentUsername');
      AppStorage.delete('isLoggedIn');
      AppStorage.delete('userInfo');

      const preferences = await dataPreferences.getPreferences(getContext(), 'user_preferences');
      await preferences.delete('currentUsername');
      await preferences.delete('isLoggedIn');
      await preferences.flush();
    } catch (error) {
      console.error('清除登录状态失败:', error);
    }
  }
}