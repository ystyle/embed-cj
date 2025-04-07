macro package embed.macros

import std.ast.*
import std.fs.{File,Directory, OpenMode, Path, FileInfo}
import std.io.{readString, readToEnd}
import std.collection.ArrayList
import encoding.base64.toBase64String
public import embed.{EmbedFS, addEmbedFile}
public import encoding.base64.fromBase64String


// 嵌入字符串
public macro EmbedString(input: Tokens): Tokens {
    let f = File(input[0].value, OpenMode.Read)
    let text = readString(f)
    return quote( $(text) )
}

// 嵌入字节数组
public macro EmbedBytes(input: Tokens): Tokens {
    let f = File(input[0].value, OpenMode.Read)
    let bs = readToEnd(f)
    let text = toBase64String(bs)
    return quote( fromBase64String($(text)).getOrThrow() )
}

// 嵌入目录
public macro EmbedDir(input: Tokens): Tokens {
    let p = Path(input[0].value)
    if (p.isAbsolute()) {
        diagReport(DiagReportLevel.ERROR, input, "嵌入目录错误", '嵌入目录应以相对项目根目录')
    }
    let parent = FileInfo(p).path.parent.toString()
    let files = listdirs(p)
    var lines = quote()
    var i = 0
    for (f in files) {
        let path = f.info.path.toString().replace(parent+'/', '')
        let bs = readToEnd(f)
        let text = toBase64String(bs)
        let id = Token(TokenKind.IDENTIFIER, "f_${i}")
        lines += quote( 
            let $(id):String = $(text)
            addEmbedFile(fs, $(path), $(id))
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