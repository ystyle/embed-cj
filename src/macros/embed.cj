macro package embed.macros

import std.ast.*
import std.fs.{File, Directory, OpenMode, Path, exists}
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
            let sep = "/src"
            if (let Some(srcPos) <- pkgPath.indexOf(sep)) {
                let after = srcPos + sep.size
                if (after >= pkgPath.size) {
                    return Some(pkgPath[0..srcPos])
                }
                if (pkgPath[after..after + 1] == "/") {
                    return Some(pkgPath[0..srcPos])
                }
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
    let t = Token(TokenKind.MULTILINE_RAW_STRING, text)
    return quote( $(t) )
}

public macro EmbedBytes(input: Tokens): Tokens {
    let filePath = resolvePath(input[0].value)
    let f = File(filePath, OpenMode.Read)
    let bs = readToEnd(f)
    let text = toBase64String(bs)
    return quote( fromBase64String($(text)).getOrThrow() )
}

public macro EmbedDir(input: Tokens): Tokens {
    let dirName = input[0].value

    if (Path(dirName).isAbsolute()) {
        diagReport(DiagReportLevel.ERROR, input, "嵌入目录错误", '嵌入目录应以相对项目根目录')
    }

    let resolved = resolvePath(dirName)
    let files = listdirs(Path(resolved))
    var lines = quote()
    var i = 0
    for ((relPath, f) in files) {
        let embedPath = "${dirName}/${relPath}"
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

func listdirs(path:Path):ArrayList<(String, File)> {
    let files = ArrayList<(String, File)>()
    Directory.walk(path, { f =>
        let name = f.path.fileName
        if (f.isDirectory()) {
            let subPrefix = "${name}/"
            for ((relPath, file) in listdirs(f.path)) {
                files.add(("${subPrefix}${relPath}", file))
            }
        } else {
            files.add((name, File(f.path, OpenMode.Read)))
        }
        return true
    })
    return files
}
