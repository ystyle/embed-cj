package demo

import std.fs.Path
import embed.macros.*

let cjpm:String = @EmbedString("cjpm.toml")
let cjpmbs:Array<Byte> = @EmbedBytes("cjpm.toml")
let assets:EmbedFS = @EmbedDir(".")

main(): Int64 {
    let arr = assets.readDir(Path("."))
    println(assets.toString())
    println("--------------------------------")
    for (a in arr) {
        let stat = a.stat()
        println(stat.path)
    }
    println("--------------------------------")
    println("assets")
    let bs = assets.readFile("./cjpm.toml")
    println(String.fromUtf8(bs))
    println("--------------------------------")
    println(cjpm)
    println("--------------------------------")
    println(String.fromUtf8(cjpmbs))
    println("--------------------------------")
    return 0
}