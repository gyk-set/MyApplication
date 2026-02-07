import router from '@ohos.router';
import { BusinessError } from '@ohos.base';

// 保持原有接口命名风格（小写开头），包含所有属性
interface options {
  showBack?: boolean;
  title?: string;
  rightText?: string;
  onLeftClick?: () => void;
  onRightClick?: () => void;
  backgroundColor?: string;
  titleColor?: string;
  backIconColor?: string;
}

@Component
export struct CommonNavBar {
  // 只保留 options 属性，包含所有默认值
  @Prop options: options = {
    showBack: true,
    title: '',
    backgroundColor: '#FFFFFF',
    titleColor: '#333333',
    backIconColor: '#333333',
  };

  build() {
      Row() {
        // 左侧返回按钮
        if (this.options.showBack) {
          Button() {
            Image($r('app.media.ic_back'))
              .width(24)
              .height(24)
              .fillColor(this.options.backIconColor)
          }
          .width(44)
          .height(44)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            try {
              if (this.options.onLeftClick) {
                this.options.onLeftClick();
              } else {
                router.back();
              }
            } catch (error) {
              const err = error as BusinessError;
              console.error(`导航栏返回按钮点击失败: ${err.code} - ${err.message}`);
            }
          })
        } else {
          Blank().width(44).height(44);
        }

        // 中间标题
        Text(this.options.title || '')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.options.titleColor)
          .flexGrow(1)
          .textAlign(TextAlign.Center)

        // 右侧操作按钮（和固定态逻辑完全一致）
        if (this.options.rightText) {
          Button() {
            Text(this.options.rightText)
              .fontColor('#007AFF')
          }
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .width(60)
          .height(44)
          .onClick(() => {
            try {
              if (this.options.onRightClick) {
                this.options.onRightClick();
              }
            } catch (error) {
              const err = error as BusinessError;
              console.error(`导航栏右侧按钮点击失败: ${err.code} - ${err.message}`);
            }
          })
        }  else {
          Blank().width(44).height(44);
        }
      }
      .width('100%')
      .height(56)
      .backgroundColor(this.options.backgroundColor)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
    }
  }
