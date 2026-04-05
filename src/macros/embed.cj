macro package embed.macros

import std.ast.*
import std.fs.{File, Directory, OpenMode, Path, FileInfo, exists}
import std.io.{readString, readToEnd}
import std.collection.ArrayList
import stdx.encoding.base64.toBase64String
import std.env.getCommandLine
public import embed.{EmbedFS, addEmbedFile}
public import stdx.encoding.base64.fromBase64String

func getPackageRoot(): ?String {
    let cmdLine = getCommandLine()
    var idx = 0
    while (idx < cmdLine.size) {
        if (cmdLine[idx] == "-p" && idx + 1 < cmdLine.size) {
            let pkgPath = cmdLine[idx + 1].toString()
            if (let Some(srcPos) <- pkgPath.indexOf("/src/")) {
                return Some(pkgPath[0..srcPos])
            }
            break
        }
        idx++
    }
    return None
}

func resolvePath(relativePath: String): String {
    if (let Some(root) <- getPackageRoot()) {
        let fullPath = Path(root).join(relativePath).toString()
        if (exists(fullPath)) {
            return fullPath
        }
    }
    return relativePath
}

public macro EmbedString(input: Tokens): Tokens {
    let filePath = resolvePath(input[0].value)
    let f = File(filePath, OpenMode.Read)
    let text = readString(f)
    return quote( $(text) )
}

public macro EmbedBytes(input: Tokens): Tokens {
    let filePath = resolvePath(input[0].value)
    let f = File(filePath, OpenMode.Read)
    let bs = readToEnd(f)
    let text = toBase64String(bs)
    return quote( fromBase64String($(text)).getOrThrow() )
}

public macro EmbedDir(input: Tokens): Tokens {
    let p = Path(input[0].value)
    let dirName = p.toString()
    
    if (let Some(root) <- getPackageRoot()) {
        let fullPath = Path(root).join(p)
        
        if (exists(fullPath)) {
            
            let files = listdirs(fullPath)
            var lines = quote()
            var fidx = 0
            for (f in files) {
                let relativePath = f.info.path.toString().replace(fullPath.toString() + "/", "")
                let embedPath = "${dirName}/${relativePath}"
                let bs = readToEnd(f)
                let text = toBase64String(bs)
                let id = Token(TokenKind.IDENTIFIER, "f_${fidx}")
                lines += quote(
                    let $(id):String = $(text)
                    addEmbedFile(fs, $(embedPath), $(id))
                )
                fidx++
            }
            
            return quote( {=>
                let fs = EmbedFS()
                $(lines)
                return fs
            }())
        }
    }
    
    if (p.isAbsolute()) {
        diagReport(DiagReportLevel.ERROR, input, "嵌入目录错误", '嵌入目录应以相对项目根目录')
    }
    
    let parent = FileInfo(p).path.parent
    let files = listdirs(p)
    var lines = quote()
    var i = 0
    for (f in files) {
        let path = f.info.path.toString().replace(parent.toString() + '/', '')
        let embedPath = "${dirName}/${path}"
        let bs = readToEnd(f)
        let text = toBase64String(bs)
        let id = Token(TokenKind.IDENTIFIER, "f_${i}")
        lines += quote(
            let $(id):String = $(text)
            addEmbedFile(fs, $(embedPath), $(id))
         )
         i++
    }

    return quote( {=>
        let fs = EmbedFS()
        $(lines)
        return fs
     }())
}

func listdirs(path:Path):ArrayList<File> {
    let files = ArrayList<File>()
    Directory.walk(path, { f =>
        if (f.isDirectory()) {
            files.add(all: listdirs(f.path))
        } else {
            files.add(File(f.path, OpenMode.Read))
        }
        return true
    })
    return files
}
