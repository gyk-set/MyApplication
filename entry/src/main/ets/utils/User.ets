// 这个类就是“装账号密码的盒子”，没有任何复杂东西
export default class User {
  id: number = 0;
  // 账号唯一编号（自动增长，不用管）
  username: string = '';
  // 你输入的用户名
  password: string = '';
  // 加密后的密码
}