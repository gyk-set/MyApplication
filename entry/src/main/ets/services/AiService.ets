// entry/src/main/ets/services/AiService.ets
import { HttpUtils } from '../utils/HttpUtils';


interface ChatMessage {
  role: string;
  content: string;
}
/**
 * 智谱AI服务封装层
 * 职责：统一管理AI接口配置、请求参数、响应解析，与页面解耦
 */
interface GeneratedObjectLiteralInterface_1 {
  model: string;
  messages: ChatMessage[];
  temperature: number;
  max_tokens: number;
}

export class AiService {
  // 1. 配置项抽离（便于维护和环境切换）
  private static readonly ZHIPU_URL = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';
  // 注意：答辩时说明：实际开发中API Key应放在安全存储（如鸿蒙的SecretManager），此处为演示简化
  private static readonly API_KEY = 'be43ff25cddf46e1a0cbf18189a4426b.x6QEFW0DyGZsQaRp';
  private static readonly DEFAULT_MODEL = 'glm-4'; // 也可使用glm-3-turbo（轻量版）

  /**
   * 智能问答核心方法
   * @param prompt 用户提问的文本
   * @returns AI返回的回答文本
   * @throws 接口调用异常、响应格式异常等错误
   */
  static async chat(prompt: string): Promise<string> {
    // 1. 参数校验
    if (!prompt || prompt.trim() === '') {
      throw new Error('提问内容不能为空，请输入有效问题');
    }

    // 2. 构造智谱AI接口要求的请求体（严格按官方文档）
    const requestBody: GeneratedObjectLiteralInterface_1 = {
      model: AiService.DEFAULT_MODEL,
      messages: [
        {
          role: 'user', // 角色固定为user
          content: prompt.trim() // 去除首尾空格，避免无效请求
        }
      ] as ChatMessage[],
      temperature: 0.7, // 随机性：0-1，值越高回答越灵活
      max_tokens: 2048 // 新增：限制返回文本长度，避免超长响应（可选）
    };

    // 3. 构造请求头（鉴权+内容类型）
    // 修正后：显式指定headers类型
    const headers: Record<string, string> = {
      'Authorization': `Bearer ${AiService.API_KEY}`,
      'Content-Type': 'application/json'
    };

    try {
      // 4. 调用网络工具类发起请求
      const response = await HttpUtils.post(AiService.ZHIPU_URL, requestBody, headers);

      // 5. 校验响应格式（避免接口返回异常导致程序崩溃）
      if (!response || !response.choices || response.choices.length === 0) {
        throw new Error('AI响应格式异常，未返回有效回答');
      }
      if (!response.choices[0].message || !response.choices[0].message.content) {
        throw new Error('AI未返回有效回答内容');
      }

      // 6. 提取并返回回答文本
      return response.choices[0].message.content;
    } catch (error) {
      const errMsg = (error as Error).message;
      console.error(`AiService chat 失败：${errMsg}`);
      // 封装错误信息，让上层更易理解
      throw new Error(`AI问答调用失败：${errMsg}`);
    }
  }
}