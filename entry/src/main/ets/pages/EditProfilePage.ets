// EditProfilePage.ets
import router from '@ohos.router';
import picker from '@ohos.file.picker';
import promptAction from '@ohos.promptAction';

interface storage{
  name: string,
  bio: string,
  avatar: string
}



@Entry
@Component
struct EditProfilePage {
  @State userName: string = '轻记用户';
  @State userBio: string = '让记账更简单';
  @State userAvatar: Resource = $r('app.media.User_Avatar');

  @StorageLink('userProfile') storageProfile: storage = {
    name: '轻记用户',
    bio: '让记账更简单',
    avatar: 'app.media.User_Avatar'
  };

  aboutToAppear() {
    // 从本地存储或父页面传入的数据初始化
    this.userName = this.storageProfile.name;
    this.userBio = this.storageProfile.bio;
    // 注意：实际项目中头像可能是路径或base64，这里简化处理
  }

  // 选择头像
  async selectAvatar() {
    try {
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new picker.PhotoViewPicker();
      const photoSelectResult = await photoPicker.select(photoSelectOptions);

      if (photoSelectResult && photoSelectResult.photoUris.length > 0) {
        // 这里简化处理，实际项目中需要将选择的图片转换为base64或保存到应用目录
        // this.userAvatar = photoSelectResult.photoUris[0];
        promptAction.showToast({
          message: '头像选择成功（需实现图片处理逻辑）',
          duration: 2000
        });
      }
    } catch (err) {
      console.error(`选择头像失败: ${JSON.stringify(err)}`);
    }
  }

  // 保存修改
  saveProfile() {
    // 更新本地存储
    this.storageProfile = {
      name: this.userName,
      bio: this.userBio,
      avatar: this.storageProfile.avatar // 实际项目中更新头像路径
    };

    promptAction.showToast({
      message: '资料保存成功',
      duration: 2000
    });

    // 延迟返回上一页，让用户看到保存成功的提示
    setTimeout(() => {
      router.back();
    }, 500);
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('编辑资料')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .margin({ left: 16 });

        Blank();

        Button('保存')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(20)
          .padding({
            left: 20,
            right: 20,
            top: 8,
            bottom: 8
          })
          .margin({ right: 16 })
          .onClick(() => {
            this.saveProfile();
          });
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 24 }) {
          // 头像编辑区域
          Column({ space: 12 }) {
            Text('头像')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#000000')
              .textAlign(TextAlign.Start)  // 文本左对齐
              .width('100%');  // 需要设置宽度才能生效


            Column() {
              Image(this.userAvatar)
                .width(100)
                .height(100)
                .borderRadius(50)
                .backgroundColor('#E5F1FF')
                .objectFit(ImageFit.Cover)

              Button('更换头像')
                .fontSize(14)
                .fontColor('#007AFF')
                .backgroundColor('#FFFFFF')
                .borderRadius(16)
                .padding({
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 8
                })
                .margin({ top: 12 })
                .onClick(() => {
                  this.selectAvatar();
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ top: 16 })

          // 用户名编辑区域
          Column({ space: 12 }) {
            Text('用户名')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#000000')
              .textAlign(TextAlign.Start)  // 文本左对齐
              .width('100%');  // 需要设置宽度才能生效

            TextInput({
              text: this.userName,
              placeholder: '请输入用户名'
            })
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor('#000000')
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .padding(12)
              .onChange((value: string) => {
                this.userName = value;
              })
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)

          // 简介编辑区域
          Column({ space: 12 }) {
            Text('简介')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#000000')
              .textAlign(TextAlign.Start)  // 文本左对齐
              .width('100%');  // 需要设置宽度才能生效

            TextInput({
              text: this.userBio,
              placeholder: '请输入个人简介'
            })
              .width('100%')
              .height(100)
              .fontSize(16)
              .fontColor('#000000')
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .padding(12)
              //.type(InputType.MultiLine) // 设置为多行模式
              .onChange((value: string) => {
                this.userBio = value;
              })
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
        }
        .width('100%')
        .padding(16)
      }
      .flexGrow(1)
      .backgroundColor('#F0F2F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F2F5')
  }
}