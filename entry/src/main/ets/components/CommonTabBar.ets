import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@ohos.base';
import { TabItem } from '../models/Record';
import display from '@ohos.display'; // 替换原错误的import


export const DefaultTabItems: Array<TabItem> = [{
  title: '首页',
  iconSelected: $r('app.media.home_selected'), // 选中态图标（如home_selected.png）
  iconNormal: $r('app.media.home_normal'), // 未选中态图标（如home_normal.png）
  pageUrl: 'pages/HomePage'                    // 跳转的首页路径
},
  {
    title: '记账',
    iconSelected: $r('app.media.jiyibi_selected'),
    iconNormal: $r('app.media.jiyibi_normal'),
    pageUrl: 'pages/RecordPage'
  },
  {
    title: '我的',
    iconSelected: $r('app.media.mine_selected'),
    iconNormal: $r('app.media.mine_normal'),
    pageUrl: 'pages/MinePage'
  }
];

/**
 * 底部导航栏组件
 * 支持3个Tab切换、图标状态变化、页面跳转
 */
@Component
export struct CommonTabBar {
  // Tab选项列表（固定3个）
  @Prop tabItems: TabItem[] = [];
  // 当前选中的Tab索引（默认选中第一个）
  @State currentIndex: number = 0;
  // 选中态文字颜色
  @Prop activeColor: string = '#FF5722';
  // 未选中态文字颜色
  @Prop inactiveColor: string = '#999999';
  // 导航栏高度（默认56px）
  @Prop barHeight: number = 56;

  // 底部Tab样式
  @Builder
  TabBarBuilder(item: TabItem, index: number) {
    Column({ space: 4 }) {
      Image(this.currentIndex === index ? item.iconSelected : item.iconNormal)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .margin({ top: 2 }); // 轻微上边距，垂直居中;

      Text(item.title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? this.activeColor : this.inactiveColor)
        .margin({ bottom: 2 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  build() {
    // 底部导航栏容器
    Row() {
      ForEach(this.tabItems, (item: TabItem, index: number) => {
        Column() {
          this.TabBarBuilder(item, index);
        }
        .width('33.33%')
        .height(this.barHeight)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.currentIndex = index;
          try {
            router.pushUrl({ url: item.pageUrl, params: { from: 'MinePage' } });
            promptAction.showToast({ message: `跳转到${item.title}` });
          } catch (e) {
            console.error('跳转失败：', e);
            promptAction.showToast({ message: '页面跳转失败' });
          }
        });
      }, (item: TabItem, index: number) => index.toString());
    }
    .width('100%')
    .height(this.barHeight)
    .backgroundColor('#FFFFFF')
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(VerticalAlign.Center)
    // 顶部细边框，区分内容区
    .border({
      width: { top: 0.5 }, // 按方向指定宽度
      color: { top: '#E5E5E5' } // 按方向指定颜色
    })
    // 无多余内边距，避免挤压图标
    .padding(0)
    .margin(0);
  }
}