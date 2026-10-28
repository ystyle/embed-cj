package embed

import std.unittest.*
import std.unittest.testmacro.*

// ===== 包根目录推导（跨平台）=====
//
// 背景：@EmbedString("public/css/x.css") 这种相对路径要相对**包根**解析，而不是相对
// 编译器的工作目录。原来靠在一串命令行参数里找 `-p <包源码目录>` 再按硬编码的 "/src"
// 切出根目录 —— 在 Linux 上没问题，Windows 上 -p 给的是 `D:\a\repo\src`（反斜杠），
// `indexOf("/src")` 匹配不到，于是返回 None、路径退化成相对 cwd，宏在 Windows 上
// 报 "The file ... does not exist"。
//
// 这类 bug 只在目标平台暴露，本地无论怎么跑都绿。所以把切分逻辑抽成纯函数，
// 用两种分隔符各钉一条用例。

@Test
func packageRootUnixPath() {
    @Expect(packageRootOf("/home/me/proj/src"), "/home/me/proj")
    @Expect(packageRootOf("/home/me/proj/src/sub/pkg"), "/home/me/proj")
}

@Test
func packageRootWindowsPath() {
    // 反斜杠：这是 Windows CI 上真实的形态
    @Expect(packageRootOf("D:\\a\\chronomem\\chronomem\\src"), "D:\\a\\chronomem\\chronomem")
    @Expect(packageRootOf("D:\\a\\chronomem\\chronomem\\src\\cli"), "D:\\a\\chronomem\\chronomem")
}

@Test
func packageRootMixedSeparators() {
    // 混合分隔符也要能切（有些工具链会混着给）
    @Expect(packageRootOf("D:/a/proj\\src"), "D:/a/proj")
}

@Test
func packageRootRejectsLookalikeDir() {
    // "src" 必须是**完整的路径段**，不能把 "srcfoo" 当成 src
    @Expect(packageRootOf("/home/me/srcfoo"), "")
    @Expect(packageRootOf("/home/me/proj/src-old/x"), "")
}

@Test
func packageRootEmptyWhenNoSrcSegment() {
    @Expect(packageRootOf("/home/me/proj"), "")
    @Expect(packageRootOf(""), "")
}

@Test
func packageRootIgnoresTrailingSrc() {
    // 正好以 /src 结尾（没有子包）：根就是它前面那截
    @Expect(packageRootOf("/a/b/src"), "/a/b")
}
