package embed

import std.fs.Path
import std.time.DateTime
import std.collection.{HashMap, ArrayList}
import stdx.encoding.base64.fromBase64String

public class EmbedFS <: ToString{
    let files = HashMap<String, String>()
    let stats = HashMap<String, EmbedFileStat>()
    public init(){}
    func addEmbedFile(path:String, data:String):Unit {
        this.files.add(path, data)
        let stat = EmbedFileStat(Path(path).fileName, path, data.size, data.size == 0, DateTime.now())
        this.stats.add(path, stat)
    }
    public func open(path: Path): ?EmbedFile {
        if (let Some(bs) <- this.files.get(path.toString())) {
            let stat = this.stats[path.toString()]
            return EmbedFile(path.toString(), bs, stat)
        }
        return None
    }
    public func readDir(path:Path):Array<EmbedFile>{
        let p = path.toString()
        let dirFiles = ArrayList<EmbedFile>()
        for ((filepath, bs) in this.files) {
            if (filepath.startsWith(p) && filepath != p) {
                let stat = this.stats[filepath]
                dirFiles.add(EmbedFile(filepath, bs, stat))
            }
        }
        return dirFiles.toArray()
    }
    public func readFile(path:String):Array<Byte>{
        let text = this.files[path]
        return fromBase64String(text).getOrThrow()
    }
    public func toString ():String {
        return String.join(this.files.keys().toArray(), delimiter: '\n')
    }
}

public class EmbedFile {
    EmbedFile(let path:String, let data:String, let fileStat:EmbedFileStat) {

    }
    public func read(): Array<Byte> {
        return fromBase64String(this.data).getOrThrow()
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

public func addEmbedFile(fs:EmbedFS, path:String, data:String):Unit {
    fs.addEmbedFile(path, data)
}
