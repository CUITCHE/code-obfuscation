//
//  printc.swift
//  printc
//
//  Created by hejunqiu on 2017/7/17.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

import Foundation


/// Use `printc` to print color text on command applications.
/// There are two way to print.
///
/// Use static func to complete once print.
///
///     printc.print("Hello", .red)
///     // Prints "Hello" whose foreground color is red.
///
/// Use printc object to assemble some colorful words, and print them before the object destroying.
/// Contact write clause by `_` function. That looks like concise.
///
///     printc.write("int ", .red)._("main(")._("int", .red)
///     ._(" argc, ")._("char ", .red)._("*", .purple)
///     ._("argv[])")
///     // Prints int main(int argc, char *argv[]) with colors.
///
/// Also see function notes.
open class printc {
    private var buf: String = ""

    public enum Mark: UInt {
        /// All attributes off
        case closeAll = 0
        /// Bold on
        case bold
        /// Blur the text. May be not available.
        case obscure
        /// Italic font. May be not available.
        case italic
        /// Underscore (on monochrome display adapter only)
        case underline
        /// Blink on
        case flash
        /// Blink on quickly. May be not available.
        case twinkle
        /// Reverse video on
        case exchangeFB
        /// Concealed on
        case hidden

        /// Foreground colors
        case black = 30, red, green, yellow, blue, purple, navy, white
        /// Background colors
        case Black = 40, Red, Green, Yellow, Blue, Purple, Navy, White

        public var rawVal: UInt {
            return self.rawValue
        }
    }

    deinit {
        if buf.characters.count != 0 {
            fputs(buf, stderr)
        }
    }

    /// Create a printc object and write first text with marks.
    ///
    ///     printc.write("Hello", .red, .italic)
    ///     // Prints "Hello" with red and italic attribtue.
    ///
    /// - Parameters:
    ///   - str: A text will be written.
    ///   - marks: An array of mark.
    /// - Returns: A printc object.
    @discardableResult public static func write(_ str: String, _ marks: Mark...) -> printc {
        let obj = printc()
        printc.assemble(text: str, in: &obj.buf, with: marks)
        return obj
    }

    /// Write the text with marks.
    ///
    ///     printc.write("Hello", .red).append("World!", .bold, .Red, .yellow)
    ///     // Prints "Hello World!"
    ///     // "Hello" has red foreground.
    ///     // "World!" has a red backgournd and yellow font and bold attribute.
    ///
    /// - Parameters:
    ///   - str: A text will be written.
    ///   - marks: An array of mark.
    /// - Returns: Return self.
    @discardableResult public func write(_ str: String, _ marks: Mark...) -> printc {
        printc.assemble(text: str, in: &buf, with: marks)
        return self
    }

    /// Write the str with a '\n' character. Use `_`(::) or write(::) method
    /// to write str which you want to write a '\n' may be like:
    ///
    ///     printc.write("Mark the str contains \\n in mark code.\n", .red)
    ///     // Raw string is "[31mMark the str contains \\n in mark code.\n[0m".
    ///     // That cause the console right side left a red backgroud.
    ///
    /// Use this method to resolve it.
    ///
    /// - Parameters:
    ///   - str: A text will be written.
    ///   - marks: An array of mark.
    /// - Returns: the self of invoking object.
    @discardableResult public func writeln(_ str: String, _ marks: Mark...) -> printc {
        printc.assemble(text: str, in: &buf, with: marks, appendNewline: true)
        return self
    }

    /// Print the text with marks
    ///
    /// - Parameters:
    ///   - text: The text will be modify some color or other mark by marks
    ///   - marks: see enum `Mark`
    public static func print(text: String, marks: Mark...) {
        var buffer = ""
        assemble(text: text, in: &buffer, with: marks)
        fputs(buffer, stderr)
    }

    /// Print the text with marks and '\n'
    ///
    /// - Parameters:
    ///   - text: The text will be modify some color or other mark by marks
    ///   - marks: see enum `Mark`
    public static func println(text: String, marks: Mark...) {
        var buffer = ""
        assemble(text: text, in: &buffer, with: marks, appendNewline: true)
        fputs(buffer, stderr)
    }

    /// Return the buffer and clean the buffer. If you use this method that means you want
    /// to controle the buffer.
    ///
    /// - Returns: String buffer content.
    public func takeAssembleBuffer() -> String {
        defer {
            buf.removeAll()
        }
        return buf
    }
}

fileprivate extension printc {
    fileprivate static func assemble(text: String, in buffer: inout String, with marks: [Mark], appendNewline: Bool = false) {
        if marks.count == 0 {
            appendNewline ? buffer.append("\(text)\n") : buffer.append(text)
            return
        }
        buffer.append("\u{001b}[")
        for m in marks {
            buffer.append("\(m.rawVal);")
        }
        buffer.remove(at: buffer.index(before: buffer.endIndex))
        appendNewline ? buffer.append("m\(text)\u{001b}[0m\n") : buffer.append("m\(text)\u{001b}[0m");
    }
}
