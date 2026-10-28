package embed

import std.fs.Path
import std.time.DateTime
import std.collection.{HashMap, ArrayList}
import std.sort.sort

public class EmbedFS <: ToString{
    let files = HashMap<String, Array<Byte>>()
    let stats = HashMap<String, EmbedFileStat>()
    public init(){}
    func addEmbedFile(path:String, data:Array<Byte>):Unit {
        this.files.add(path, data)
        let stat = EmbedFileStat(Path(path).fileName, path, data.size, data.size == 0, DateTime.now())
        this.stats.add(path, stat)
    }
    public func open(path: Path): ?EmbedFile {
        let p = path.normalize().toString()
        if (let Some(bs) <- this.files.get(p)) {
            let stat = this.stats[p]
            return EmbedFile(p, bs, stat)
        }
        return None
    }
    public func readDir(path: Path): Array<EmbedFile> {
        let p = path.normalize().toString()
        let prefix = p + "/"
        let dirFiles = ArrayList<EmbedFile>()
        for ((filepath, bs) in this.files) {
            if (filepath.startsWith(prefix)) {
                let stat = this.stats[filepath]
                dirFiles.add(EmbedFile(filepath, bs, stat))
            }
        }
        return dirFiles.toArray()
    }
    public func readFile(path: String): Array<Byte> {
        let p = Path(path).normalize().toString()
        return this.files[p]
    }
    public func toString(): String {
        let keys = ArrayList<String>()
        let allKeys = this.files.keys()
        for (k in allKeys) {
            keys.add(k)
        }
        sort<String>(keys)
        var result = ArrayList<String>()
        var printedDirs = ArrayList<String>()
        for (k in keys) {
            let parts = k.split("/")
            var dir = ""
            var i = 0
            while (i < parts.size - 1) {
                if (dir != "") { dir += "/" }
                dir += parts[i]
                if (!printedDirs.contains(dir)) {
                    result.add(indent(i) + parts[i] + "/")
                    printedDirs.add(dir)
                }
                i++
            }
            result.add(indent(parts.size - 1) + parts[parts.size - 1])
        }
        return String.join(result.toArray(), delimiter: '\n')
    }
}

func indent(n: Int64): String {
    var s = ""
    var i = 0
    while (i < n) {
        s += "  "
        i++
    }
    return s
}

public class EmbedFile {
    EmbedFile(let path:String, let data:Array<Byte>, let fileStat:EmbedFileStat) {

    }
    public func read(): Array<Byte> {
        return this.data
    }
    public func close(): Unit {
    }
    public func stat(): EmbedFileStat {
        this.fileStat
    }
}

public class EmbedFileStat {
    public let name:String
    public let path: String
    public let size:Int64
    public let isDir:Bool
    public let modTime:DateTime
    init(name:String,path: String, size:Int64, isDir:Bool, modTime:DateTime){
        this.name = name
        this.path = path
        this.size = size
        this.isDir = isDir
        this.modTime = modTime
    }
}

public func addEmbedFile(fs:EmbedFS, path:String, data:Array<Byte>):Unit {
    fs.addEmbedFile(path, data)
}

/**
 * 从包源码目录（编译器 `-p` 参数）推出包根目录，推不出时返回空串。
 *
 * **必须同时接受 `/` 与 `\`**：Windows 上 `-p` 给的是 `D:\a\repo\src`。
 * 旧实现写死 `indexOf("/src")`，在 Windows 上匹配不到 → 返回 None → 上层退回
 * 相对路径 → `@EmbedString("public/css/x.css")` 按编译器 cwd 去找，报
 * "The file ... does not exist"。这个 bug 只在 Windows 暴露，本地 Linux 永远绿。
 *
 * `src` 必须是**完整路径段**：`/a/srcfoo` 与 `/a/src-old` 都不算，
 * 否则会把「恰好以 src 开头的兄弟目录」误当成包根。
 */
public func packageRootOf(pkgPath: String): String {
    if (pkgPath == "") { return "" }
    // 统一成正斜杠再切，最后按原串下标还原长度（两种分隔符都只占 1 字节，
    // 且路径里不会出现多字节字符影响段边界，所以规范化后下标可直接用于原串）。
    let normalized = pkgPath.replace("\\", "/")
    var from = Int64(0)
    while (true) {
        let rest = normalized[from..normalized.size]
        let idx = match (rest.indexOf("/src")) {
            case Some(i) => i + from
            case None => -1
        }
        if (idx < 0) { return "" }
        let after = idx + 4
        // 段边界：/src 之后要么到末尾，要么是分隔符
        let isBoundary = after >= normalized.size || normalized[after..after + 1] == "/"
        if (isBoundary && idx > 0) {
            return pkgPath[0..idx]
        }
        from = idx + 4
        if (from >= normalized.size) { return "" }
    }
    ""
}

