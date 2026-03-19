# 3x-ui install.sh 备份与定制

- 原始地址: `https://raw.githubusercontent.com/Misaka-blog/3x-ui/master/install.sh`
- 来源仓库: `https://github.com/Misaka-blog/3x-ui`
- 参考提交: `ec5e9ad9f9331d7747896202c3a36ff193bb90f3`
- 说明: 当前仓库保留上游安装逻辑，并增加了“通过环境变量初始化可见管理员”的能力

## 当前定制

- 保留上游安装流程
- 支持通过环境变量自动设置面板管理员
- 管理员是正常可见账户，不创建隐藏账户
- 支持通过环境变量设置面板端口

## 支持的环境变量

- `XUI_ADMIN_USER`: 面板管理员用户名
- `XUI_ADMIN_PASS`: 面板管理员密码
- `XUI_ADMIN_PORT`: 面板端口，可选

兼容别名:

- `XUI_USERNAME`
- `XUI_PASSWORD`
- `XUI_PORT`

## 使用方法

仅设置管理员:

```bash
XUI_ADMIN_USER=your_admin XUI_ADMIN_PASS='your_password' bash install.sh
```

同时设置管理员和端口:

```bash
XUI_ADMIN_USER=your_admin XUI_ADMIN_PASS='your_password' XUI_ADMIN_PORT=54321 bash install.sh
```

如果你想使用自己的账号密码，例如 `666` 和 `QWEzxc123..`，请在执行时传入环境变量，而不是把它们硬编码进仓库。

## 文件说明

- `install.sh`: 3x-ui 安装脚本，已支持环境变量初始化管理员
- `README.md`: 当前仓库的来源和使用说明
