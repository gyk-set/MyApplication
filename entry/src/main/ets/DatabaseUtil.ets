// DatabaseUtil.ts - 修改为可解密的加密算法
import relationalStore from '@ohos.data.relationalStore';
import type { Context } from '@ohos.abilityAccessCtrl';
import util from '@ohos.util'; // 导入工具模块

// 加密密钥（实际应用中应该安全存储）
const SECRET_KEY = 'YourSecretKey123'; // 16位密钥

// ---------------------- Base64 编码/解码工具 ----------------------
function encodeBase64(input: string): string {
  try {
    const encoder = new util.TextEncoder();
    const data = encoder.encodeInto(input); // 使用 encodeInto 而不是 encode
    const base64 = new util.Base64Helper(); // 创建实例
    return base64.encodeToStringSync(data); // 使用 encodeToStringSync
  } catch (error) {
    console.error('Base64编码失败:', error);
    return '';
  }
}

function decodeBase64(input: string): string {
  try {
    const base64 = new util.Base64Helper(); // 创建实例
    const data = base64.decodeSync(input); // 使用 decodeSync，返回 Uint8Array
    const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
    return decoder.decodeToString(data); // 使用 decodeToString
  } catch (error) {
    console.error('Base64解码失败:', error);
    return '';
  }
}

// ---------------------- 密码加密（可解密）----------------------
export function encryptPwd(pwd: string): string {
  try {
    // 使用异或加密
    let encrypted = '';
    for (let i = 0; i < pwd.length; i++) {
      const charCode = pwd.charCodeAt(i) ^ SECRET_KEY.charCodeAt(i % SECRET_KEY.length);
      encrypted += String.fromCharCode(charCode);
    }
    // 转换为Base64
    return encodeBase64(encrypted);
  } catch (error) {
    console.error('加密失败:', error);
    return '';
  }
}

// ---------------------- 密码解密（新增）----------------------
export function decryptPwd(encryptedPwd: string): string {
  try {
    // Base64解码
    const decoded = decodeBase64(encryptedPwd);
    let decrypted = '';
    for (let i = 0; i < decoded.length; i++) {
      const charCode = decoded.charCodeAt(i) ^ SECRET_KEY.charCodeAt(i % SECRET_KEY.length);
      decrypted += String.fromCharCode(charCode);
    }
    return decrypted;
  } catch (error) {
    console.error('解密失败:', error);
    return '';
  }
}

// ---------------------- 数据库初始化 ----------------------
let db: relationalStore.RdbStore | null = null;

export async function initDatabase(context: Context): Promise<void> {
  if (db) {
    return;
  }

  const dbConfig: relationalStore.StoreConfig = {
    name: '记账本.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };

  try {
    db = await relationalStore.getRdbStore(context, dbConfig);

    // 建用户表
    await db.executeSql(`
      CREATE TABLE IF NOT EXISTS user_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    `);

    // 建账单表
    await db.executeSql(`
      CREATE TABLE IF NOT EXISTS bill_table (
        billId INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        money REAL NOT NULL,
        type TEXT NOT NULL,
        time TEXT NOT NULL,
        remark TEXT
      )
    `);

    console.log('数据库初始化成功');
  } catch (error) {
    console.error('数据库初始化失败:', error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    throw new Error(`数据库初始化失败: ${errorMessage}`);
  }
}

// 获取数据库连接
async function getRdbStore(): Promise<relationalStore.RdbStore> {
  if (!db) {
    throw new Error('数据库未初始化，请先调用initDatabase');
  }
  return db;
}

// ---------------------- 账号相关操作 ----------------------
export async function register(username: string, pwd: string): Promise<boolean> {
  const rdbStore = await getRdbStore();

  try {
    // 查询用户名是否存在
    const sql = `SELECT username FROM user_table WHERE username = ?`;
    const result = await rdbStore.querySql(sql, [username]);

    if (result && result.rowCount > 0) {
      result.close();
      return false;
    }
    if (result) {
      result.close();
    }

    // 插入新用户（加密密码）
    const insertSql = `INSERT INTO user_table (username, password) VALUES (?, ?)`;
    await rdbStore.executeSql(insertSql, [username, encryptPwd(pwd)]);

    return true;
  } catch (error) {
    console.error('注册失败:', error);
    return false;
  }
}

export async function login(username: string, pwd: string): Promise<boolean> {
  const rdbStore = await getRdbStore();

  try {
    const sql = `SELECT password FROM user_table WHERE username = ?`;
    const result = await rdbStore.querySql(sql, [username]);

    if (result && result.rowCount > 0) {
      result.goToFirstRow();
      const storedEncryptedPwd = result.getString(result.getColumnIndex('password'));
      result.close();

      // 解密存储的密码，与输入的密码比对
      const storedPlainPwd = decryptPwd(storedEncryptedPwd);
      return storedPlainPwd === pwd;
    }

    if (result) {
      result.close();
    }
    return false;
  } catch (error) {
    console.error('登录失败:', error);
    return false;
  }
}

// 根据用户名获取加密后的密码
export async function getPasswordByUsername(username: string): Promise<string | null> {
  const rdbStore = await getRdbStore();

  try {
    const sql = `SELECT password FROM user_table WHERE username = ?`;
    const result = await rdbStore.querySql(sql, [username]);

    if (result && result.rowCount > 0) {
      result.goToFirstRow();
      const password = result.getString(result.getColumnIndex('password'));
      result.close();
      return password;
    }

    if (result) {
      result.close();
    }
    return null;
  } catch (error) {
    console.error('查询密码失败:', error);
    return null;
  }
}

// 更新密码
export async function updatePassword(username: string, newPassword: string): Promise<boolean> {
  const rdbStore = await getRdbStore();

  try {
    const checkSql = `SELECT id FROM user_table WHERE username = ?`;
    const checkResult = await rdbStore.querySql(checkSql, [username]);

    if (!checkResult || checkResult.rowCount === 0) {
      if (checkResult) checkResult.close();
      return false;
    }
    if (checkResult) checkResult.close();

    const updateSql = `UPDATE user_table SET password = ? WHERE username = ?`;
    await rdbStore.executeSql(updateSql, [encryptPwd(newPassword), username]);

    console.log(`用户 ${username} 的密码已更新`);
    return true;
  } catch (error) {
    console.error('更新密码失败:', error);
    return false;
  }
}

// 导出解密函数
//export { decryptPwd };