# embed-cj
使用宏嵌入资源文件

### 功能
- 嵌入文件到字符串变量
- 嵌入文件到节点数组
- 嵌入目录到EmbedFS

### 安装
[dependencies]
mustache = {git = "https://github.com/ystyle/embed-cj", branch = "master"}

### 示例

```
// 嵌入到字符串
let cjpm:String = @EmbedString("cjpm.toml")

// 嵌入到字节数组
let cjpmbs:Array<Byte> = @EmbedBytes("cjpm.toml")

// 嵌入到EmbedFS（虚拟文件系统）
let assets:EmbedFS = @EmbedDir(".")
```

### 类定义
- `EmbedFS` 代表嵌入文件系统
  - `public func open(path: Path): ?EmbedFile`: 打开文件
  - `public func readDir(path:Path):Array<EmbedFile>`: 读取目录
  - `public func readFile(path:String):Array<Byte>`: 读取诊所
- `EmbedFile` 嵌入的文件对象
  - `public func read(): Array<Byte>`: 读取文件
  - `public func stat(): EmbedFileStat`: 反回文件元信息
- `EmbedFileStat`
  - `name:String`: 文件名
  - `path:Path`: 文件路径 
  - `size:Int64`: 文件大小
  - `isDir:Bool`: 是否目录
  - `modTime:DateTime`: 嵌入时间