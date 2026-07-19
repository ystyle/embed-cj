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
