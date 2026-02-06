import relationalStore from '@ohos.data.relationalStore';
import type { Context } from '@ohos.abilityAccessCtrl';

interface User {
  username: string;
  password: string;
}

// ---------------------- 密码加密 ----------------------
export function encryptPwd(pwd: string): string {
  let hash = 0;
  for (let i = 0; i < pwd.length; i++) {
    hash = pwd.charCodeAt(i) + ((hash << 5) - hash);
  }
  let hex = '';
  for (let i = 0; i < 8; i++) {
    hex += (hash >> (i * 4) & 0xF).toString(16);
  }
  return hex;
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
    // 直接使用getRdbStore打开数据库
    db = await relationalStore.getRdbStore(context, dbConfig);

    // 使用executeSql创建表
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

    // 插入新用户
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
    const sql = `SELECT id FROM user_table WHERE username = ? AND password = ?`;
    const encryptedPwd = encryptPwd(pwd);
    const result = await rdbStore.querySql(sql, [username, encryptedPwd]);

    const success = result && result.rowCount > 0;
    if (result) {
      result.close();
    }
    return success;
  } catch (error) {
    console.error('登录失败:', error);
    return false;
  }
}
