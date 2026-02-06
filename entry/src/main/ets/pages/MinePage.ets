import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { TabItem, FeatureItems } from '../models/Record';
import { CommonTabBar, DefaultTabItems } from '../components/CommonTabBar'
import { CommonNavBar } from '../components/CommonNavBar'

@Entry
@Component
export struct MinePage {
  @State currentIndex: number = 2; // 我的页高亮
  private tabItems: Array<TabItem> = DefaultTabItems;
  private featureItems: Array<FeatureItems> = [
    { title: '数据备份', desc: '本地数据备份与恢复' },
    { title: '导出记录', desc: '导出CSV或图片' },
    { title: '关于轻记', desc: '版本信息与更新' }
  ];

  build() {
    Column() {
      // 1. 顶部导航栏（CommonNavBar）
      CommonNavBar({

        options: {
          showBack: true,
          onLeftClick: () =>{
            router.replaceUrl({ url: 'pages/MainPage' })// 右侧按钮点击事件（可选）
          },
          title: '我的',
          rightText: '设置', // 右侧文本按钮内容（可选）
          onRightClick: () => {
            router.push({ url: 'pages/SettingsPage' }) // 右侧按钮点击事件（可选）
          }
        }
      });
      // 主体信息
      Scroll() {
        Column({ space: 16 }) {
          // 个人信息卡

          Row() {
            Image($r('app.media.User_Avatar'))
              .width(64)
              .height(64)
              .borderRadius(32) // 宽高的一半 = 圆形
              .backgroundColor('#E5F1FF')
              .objectFit(ImageFit.Cover)
              .margin({ right: 16 });

            Column({ space: 6 }) {
              Text('轻记用户')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#000000');
              Text('让记账更简单')
                .fontSize(14)
                .fontColor('#666666');
            }

            Blank();
            Button('编辑资料')
              .fontSize(14)
              .fontColor('#007AFF')
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .padding({
                left: 12,
                right: 12,
                top: 6,
                bottom: 6
              })
              .onClick(() => promptAction.showToast({ message: '暂未实现' }));
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ top: 16 })
          .shadow({
            radius: 8,
            color: 'rgba(0,0,0,0.1)', // 优化阴影颜色（原红色太刺眼，改为浅黑半透明）
            offsetX: 0,
            offsetY: 2
          });

          // 其他功能入口


          Column() {
            ForEach(this.featureItems, (item: FeatureItems) => {
              Row() {
                Column() {
                  Text(item.title)
                    .fontSize(16)
                    .fontColor('#000000');
                  Text(item.desc)
                    .fontSize(12)
                    .fontColor('#888888')
                    .margin({ top: 4 });
                }

                Blank();
                Text('>')
                  .fontSize(14)
                  .fontColor('#C0C0C0');
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 });

              Divider().color('#F2F2F7');
            });
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
          .backgroundColor('#FFFFFF')
          .borderRadius(16);
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 20 })
      }
      .backgroundColor('#F2F2F7')
      .scrollBar(BarState.Off)
      .width('100%')
      .height('90%');

      // 底部导航栏
      CommonTabBar({
        tabItems: this.tabItems,
        activeColor: '#FF5722', // 自定义选中态颜色
        inactiveColor: '#999999' // 自定义未选中态颜色
      })
        .width('100%')
        .height(56)
        .backgroundColor('#FFFFFF');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7');
  }
}