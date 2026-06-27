package demo

import std.fs.Path
import embed.macros.*

let cjpm:String = @EmbedString("cjpm.toml")
let cjpmbs:Array<Byte> = @EmbedBytes("cjpm.toml")
let assets:EmbedFS = @EmbedDir("testdata")

main(): Int64 {
    println("--------------- @EmbedString -----------------")
    // 打印嵌入的字符串
    println(cjpm)
    println("--------------- @EmbedBytes -----------------")
    // 打印嵌入的字节数组
    println(String.fromUtf8(cjpmbs))
    println("--------------- @EmbedFS -----------------")
    // 打印所有的文件key
    println(assets)
    println("--------------------------------")
    // 读取目录
    let arr = assets.readDir(Path("testdata"))
    for (a in arr) {
        let stat = a.stat()
        println(stat.path)
        println(stat.size)
        println("path: ${stat.path}, size: ${stat.size}")
    }
    println("--------------------------------")
    // 读取文件
    println("assets")
    let bs = assets.readFile("testdata/cjpm.toml")
    println(String.fromUtf8(bs))
    return 0
}
