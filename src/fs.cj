package embed

import std.fs.Path
import std.time.DateTime

// 文件系统
public interface FileSystem {
    // 打开文件
    func open(path: String): File {
        this.open(Path(path))
    }
    func open(path: Path): File
    // 读取目录
    func readDir(path:String):Array<File>{
        this.readDir(Path(path))
    }
    func readDir(path:Path):Array<File>
    // 获取元信息
    func stat(path: String): FileStat {
        this.stat(Path(path))
    }
    func stat(path: Path): FileStat
    // 遍历目录
    func walk(root: String, fn: WalkFunc): Unit {
        this.walk(Path(root), fn)
    }
    func walk(root: Path, fn: WalkFunc): Unit
}

// 文件接口
public interface File {
    func read(): Array<Byte>
    func close(): Unit
    func stat(): FileStat
}

// 文件元信息接口
public interface FileStat {
    prop name: String
    prop size: String
    prop isDir: Bool
    prop modTime: DateTime
}

type WalkFunc = (String, File) -> WalkResult

public enum WalkResult {
    Continue | SkipDir | Stop
}
