// entry/src/main/ets/utils/HttpUtils.ets
import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';



// 定义智谱AI接口的响应类型
interface GeneratedTypeLiteralInterface_2 {
  role: string;
  content: string;
}

interface GeneratedTypeLiteralInterface_1 {
  message: GeneratedTypeLiteralInterface_2;
  finish_reason: string;
  index: number;
}

interface GeneratedTypeLiteralInterface_3 {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
}

interface ZhiPuAiResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: Array<GeneratedTypeLiteralInterface_1>;
  usage: GeneratedTypeLiteralInterface_3;
}
/**
 * 通用网络请求工具类
 * 封装POST请求，统一处理网络异常、响应解析、资源释放
 */
export class HttpUtils {
  /**
   * 通用POST请求方法
   * @param url 请求地址
   * @param data 请求体数据
   * @param headers 请求头
   * @returns 解析后的JSON响应数据
   * @throws 网络异常、解析异常等错误
   */
  static async post(url: string, data: object, headers: Record<string, string>): Promise<ZhiPuAiResponse> {
    // 1. 参数校验（防御性编程）
    if (!url || url.trim() === '') {
      throw new Error('请求地址不能为空');
    }
    if (!headers) {
      headers = {};
    }
    // 默认添加Content-Type（避免遗漏）
    if (!headers['Content-Type']) {
      headers['Content-Type'] = 'application/json';
    }

    const httpRequest = http.createHttp();
    try {
      // 2. 发起POST请求
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(data),
        connectTimeout: 60000, // 60秒连接超时
        readTimeout: 60000     // 60秒读取超时
      });

      // 3. 状态码校验
      if (response.responseCode !== 200) {
        throw new Error(`请求失败，状态码：${response.responseCode}，信息：${response.result}`);
      }

      // 4. 响应数据解析
      const resultStr = response.result as string;
      if (!resultStr) {
        throw new Error('响应数据为空');
      }
      return JSON.parse(resultStr);
    } catch (error) {
      // 5. 统一异常处理（区分网络错误和业务错误）
      const err = error as BusinessError;
      let errorMsg = '';
      if (err.code) {
        errorMsg = `网络请求异常 [${err.code}]：${err.message}`;
      } else {
        errorMsg = `请求处理异常：${err.message}`;
      }
      console.error(`HttpUtils POST 失败：${errorMsg}`);
      throw new Error(errorMsg); // 抛出异常让上层处理
    } finally {
      // 6. 确保资源释放
      httpRequest.destroy();
    }
  }
}