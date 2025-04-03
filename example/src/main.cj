package demo

import std.fs.Path
import embed.*
import embed.macros.*

let cjpm:String = @EmbedString("cjpm.toml")
let cjpmbs:Array<Byte> = @EmbedBytes("cjpm.toml")
let assets:EmbedFS = @EmbedDir(".")

main(): Int64 {
    let arr = assets.readDir(Path("src"))
    println(assets.toString())
    for (a in arr) {
        let stat = a.stat()
        println(stat.name)
    }
    println("--------------------------------")
    println(cjpm)
    println("--------------------------------")
    println(String.fromUtf8(cjpmbs))
    println("--------------------------------")
    return 0
}