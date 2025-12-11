# GitHub Actions 构建工作流说明

本项目包含多个GitHub Actions工作流，用于构建Maven项目并上传到Maven私仓，同时提供接口供其他action使用。

## 工作流概览

### 1. quantum-common 模块构建
**文件**: `quantum-common/.github/workflows/build.yml`

- **触发条件**: 
  - 推送到 `main` 或 `develop` 分支，且修改了 `quantum-common/**` 路径
  - 对 `quantum-common` 相关文件的PR
  - 手动触发 (`workflow_dispatch`)

- **功能**:
  - 构建所有 common 子模块 (core, web, dubbo, cache, database, mail, mq, satoken, ai)
  - 部署到 GitHub Packages Maven 仓库
  - 提供构建产物给其他workflow使用

### 2. quantum-lib 模块构建
**文件**: `quantum-lib/.github/workflows/build.yml`

- **触发条件**: 
  - 推送到 `main` 或 `develop` 分支，且修改了 `quantum-lib/**` 路径
  - 对 `quantum-lib` 相关文件的PR
  - 手动触发 (`workflow_dispatch`)

- **功能**:
  - 构建 lib 子模块 (satoken, dubbo)
  - 自动依赖 quantum-common 模块
  - 部署到 GitHub Packages Maven 仓库
  - 提供构建状态信息给其他workflow

### 3. quantum-plugin 模块构建
**文件**: `quantum-plugin/.github/workflows/build.yml`

- **触发条件**: 
  - 推送到 `main` 或 `develop` 分支，且修改了 `quantum-plugin/**` 路径
  - 对 `quantum-plugin` 相关文件的PR
  - 手动触发 (`workflow_dispatch`)

- **功能**:
  - 构建 plugin 子模块 (codegen)
  - 自动依赖 quantum-common 和 quantum-lib 模块
  - 部署到 GitHub Packages Maven 仓库
  - 提供构建状态信息给其他workflow

## 环境变量配置

所有工作流使用以下环境变量：

```yaml
env:
  JAVA_VERSION: '25'      # Java版本
  MAVEN_VERSION: '3.9.9'  # Maven版本
  MAVEN_REPOSITORY_URL: 'https://maven.pkg.github.com/${{ github.repository }}'  # Maven仓库URL
```

## Maven 仓库配置

每个工作流都会自动配置Maven的settings.xml文件，包含以下配置：

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
          http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>github</id>
      <username>${env.GITHUB_ACTOR}</username>
      <password>${env.GITHUB_TOKEN}</password>
    </server>
  </servers>
</settings>
```

## 项目POM配置要求

为了使Maven部署到GitHub Packages正常工作，项目的pom.xml需要包含以下配置：

```xml
<distributionManagement>
  <repository>
    <id>github</id>
    <name>GitHub Packages</name>
    <url>https://maven.pkg.github.com/your-org/your-repo</url>
  </repository>
  <snapshotRepository>
    <id>github</id>
    <name>GitHub Packages</name>
    <url>https://maven.pkg.github.com/your-org/your-repo</url>
  </snapshotRepository>
</distributionManagement>
```

## 输出接口

每个工作流都提供以下输出给其他workflow使用：

```yaml
outputs:
  artifact-id:      # 构建的工件ID
  version:          # 版本号
  build-status:     # 构建状态
  dependencies-ready: # 依赖是否准备就绪
```

## 如何在其他Action中调用

### 方法1: 使用 workflow_call (推荐)

在您的workflow中：

```yaml
jobs:
  build-common:
    uses: your-org/quantum/.github/workflows/build-common.yml@main
  
  build-lib:
    needs: build-common
    uses: your-org/quantum/.github/workflows/build-lib.yml@main
  
  build-plugin:
    needs: [build-common, build-lib]
    uses: your-org/quantum/.github/workflows/build-plugin.yml@main
```

### 方法2: 使用 API 调用

```yaml
jobs:
  trigger-builds:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Common build
        run: |
          curl -X POST \
            -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
            -H "Accept: application/vnd.github.v3+json" \
            https://api.github.com/repos/${{ github.repository }}/actions/workflows/quantum-common.yml/dispatches \
            -d '{"ref":"main"}'
```

### 方法3: 手动触发

在GitHub仓库的Actions页面，选择相应的工作流，点击"Run workflow"按钮手动触发。

## 依赖关系

```
quantum-common (基础模块)
    ↓
quantum-lib (依赖 common)
    ↓
quantum-plugin (依赖 common + lib)
    ↓
quantum-web (依赖所有上层模块)
```

## 安全配置

- 使用 GitHub Token (`secrets.GITHUB_TOKEN`) 进行Maven仓库认证
- Maven缓存优化以提高构建速度
- 构件上传保留1天，便于调试

## 注意事项

1. **权限要求**: 确保仓库有访问 GitHub Packages 的权限
2. **依赖顺序**: 构建时按照依赖关系顺序进行，避免找不到依赖的问题
3. **版本管理**: 使用Maven版本管理，SNAPSHOT版本会自动部署到快照仓库
4. **错误处理**: 每个构建步骤都有适当的错误处理和日志输出
5. **仓库配置**: 确保项目的pom.xml包含正确的distributionManagement配置

## 监控和调试

- 所有工作流都会输出详细的构建日志
- 构件信息通过 `provide-artifacts` job 提供
- 可以通过 GitHub API 查询构建状态和构件信息
- 可以在GitHub仓库的Packages页面查看已部署的Maven构件