package demo

import std.fs.Path
import embed.macros.*

let assets:EmbedFS = @EmbedDir("testdata")
let cjpm:String = @EmbedString("cjpm.toml")
let cjpmbs:Array<Byte> = @EmbedBytes("cjpm.toml")

main(): Int64 {
    // 打印所有的文件key
    println(assets)
    println("--------------------------------")
    // 读取目录
    let arr = assets.readDir(Path("testdata"))
    for (a in arr) {
        let stat = a.stat()
        println(stat.path)
    }
    println("--------------------------------")
    // 读取文件
    println("assets")
    let bs = assets.readFile("testdata/cjpm.toml")
    println(String.fromUtf8(bs))
    println("--------------------------------")
    // 打印嵌入的字符串
    println(cjpm)
    println("--------------------------------")
    // 打印嵌入的字节数组
    println(String.fromUtf8(cjpmbs))
    println("--------------------------------")
    return 0
}