import router from '@ohos.router';
import { BusinessError } from '@ohos.base';

interface options{
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
  // 只保留 options 属性
  @Prop options: options = {
    showBack: true,
    title: '',
    backgroundColor: '#FFFFFF',
    titleColor: '#333333',
    backIconColor: '#333333'
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
          if (this.options.onLeftClick) {
            this.options.onLeftClick();
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

      // 右侧操作按钮
      if (this.options.rightText) {
        Button() {
          Text(this.options.rightText)
        }
        .fontSize(16)
        .fontColor('#007AFF')
        .backgroundColor(Color.Transparent)
        .width(60)
        .height(44)
        .onClick(() => {
          if (this.options.onRightClick) {
            this.options.onRightClick();
          }
        })
      } else {
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