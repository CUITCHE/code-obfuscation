//
//  FileOutStream.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/8/15.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

fileprivate extension String {
    static func encrypt_md5(content: String) -> String {
        return ("\(content)\(content.characters.count)" as NSString).md5
    }

    static func md5_for_self(content: String) -> String? {
        let text = content as NSString
        var range = text.range(of: "[self] = ")
        if range.location == NSNotFound {
            return nil
        }
        range.location = NSMaxRange(range)
        range.length   = 32
        let `self` = text.replacingCharacters(in: range, with: "")
        return (`self` as NSString).md5
    }

    static let obfusedmd5 = "fileold"   // [String: String]
    static let obfusemd5  = "files"     // String
    static let selfmd5    = "self"      // String
}

struct FileOutStream {
    var needGenerateObfuscationCode: Bool { return gen != nil }

    fileprivate var headerFilename = ""
    fileprivate var selfLocation   = 0

    fileprivate let filepath: String
    fileprivate let originalFileContent: String
    fileprivate var attributed = [String: Any]()
    fileprivate var gen: String? = nil

    fileprivate static let fmtter: DateFormatter = {
        let fmtter = DateFormatter.init()
        fmtter.dateFormat = "yyyy/MM/dd"
        return fmtter
    }()

    init?(filepath: String) {
        do {
            let content = try String.init(contentsOfFile: filepath)
            originalFileContent = content
            self.filepath = filepath
        } catch {
            print(error)
            return nil
        }
    }

    mutating func read() {
        if attributed.count > 0 {
            return
        }
        var cohFileSearchEndIndex = 0
        var scanner = Scanner.init(string: originalFileContent)
        if scanner.scanUpTo("[self] =", into: nil) {
            cohFileSearchEndIndex = scanner.scanLocation
            scanner.scanString("[self] =", into: nil)
            var selfmd5: NSString? = nil
            scanner.scanUpToCharacters(from: .whitespaces, into: &selfmd5)
            if let selfmd5 = selfmd5 {
                let curCOHMd5 = String.md5_for_self(content: originalFileContent)
                self.attributed[.selfmd5] = curCOHMd5 ?? ""
                // coh文件校验
                if selfmd5.isEqual(to: curCOHMd5 ?? "") == false {
                    gen = ""
                }
            } else {
                gen = ""
            }
        }
        // 扫描关联文件的md5值
        scanner = Scanner.init(string: originalFileContent.substring(to: originalFileContent.index(originalFileContent.startIndex, offsetBy: cohFileSearchEndIndex)))
        var oldmd5 = [String: String]()
        while scanner.scanUpTo("[", into: nil) {
            scanner.scanString("[", into: nil);
            var filename: NSString? = nil
            scanner.scanUpTo("]", into: &filename)

            scanner.scanUpTo("= ", into: nil)
            scanner.scanString("= ", into: nil)

            var md5: NSString? = nil
            scanner.scanUpToCharacters(from: .whitespacesAndNewlines, into: &md5)
            if let filename = filename, let md5 = md5 {
                if filename.isEqual(to: .selfmd5) {
                    oldmd5[filename as String] = md5 as String
                }
            }
        }
        self.attributed[.obfusedmd5] = oldmd5
    }

    mutating func worth(parsing file: String, filename: String) -> Bool {
        let md5 = String.encrypt_md5(content: file)
        var md5s = self.attributed[.obfusemd5] as? [String: String]
        if md5s == nil {
            md5s = [String: String]()
        }
        md5s![filename] = md5
        self.attributed[.obfusemd5] = md5s!
        if md5 == (self.attributed[.obfusemd5] as! [String: String])[filename] {
            // FIXME: 由于当前设计缺陷，暂且决策每次都需要重新生成混淆数据
            return true
        }
        if gen == nil {
            gen = ""
        }
        return true
    }

    mutating func begin() {
        assert(gen != nil, "Logic error, you need not to generate code")
        assert(originalFileContent.characters.count != 0, "No original data")

        // 写头部注释
        let headerfilename = (self.filepath as NSString).lastPathComponent
        gen!.append("//\n//  \(headerfilename)\n")
        gen!.append("//  Code-Obfuscation Auto Generator\n\n")
        gen!.append("//  Created by \((Arguments.arguments.executedPath as NSString).lastPathComponent) on \(FileOutStream.fmtter.string(from: Date.init())).\n")
        gen!.append("//  Copyright © 2102 year \((Arguments.arguments.executedPath as NSString).lastPathComponent). All rights reserved.\n\n")

        gen!.append("//  DO NOT TRY TO MODIFY THIS FILE!\n")
        let md5s = self.attributed[.obfusemd5]
        if let md5s = md5s {
            for (key, value) in md5s as! [String: String] {
                gen!.append("//  [\(key)] = \(value)\n")
            }
        }
        gen!.append("//  [self] = ")
        self.selfLocation = gen!.characters.count
        self.headerFilename = headerfilename.replacingOccurrences(of: ".coh", with: "_coh").uppercased()

        // 写头文件header 宏
        gen!.append("#ifndef \(self.headerFilename)\n")
        gen!.append("#define \(self.headerFilename)\n\n")

        // 生成COF的必用宏
        _write(macro: "CO_CONFUSION_CLASS")
        _write(macro: "CO_CONFUSION_CATEGORY")
        _write(macro: "CO_CONFUSION_PROPERTY")
        _write(macro: "CO_CONFUSION_METHOD")

        // 尝试包含features头文件
        gen!.append("#if __has_include(\"CO-Features.h\")\n")
        gen!.append("# include \"CO-Features.h\"\n")
        gen!.append("#endif // __has_include\n\n")

        // debug下才生效
        gen!.append("#if !defined(DEBUG)\n")
    }

    mutating func write(obfuscation code: [String: String]) {
        assert(gen != nil, "Logic error, you need not to generate code")
        for (key, value) in code {
            _write(fake: value, realText: key)
        }
    }

    mutating func end() {
        assert(gen != nil, "Logic error, you need not to generate code")
        gen!.append("#endif\n\n")
        gen!.append("#endif /* \(self.headerFilename) */")

        let md5 = String.encrypt_md5(content: gen!)
        let text = NSMutableString.init(string: gen!)
        text.insert("\(md5)\n\n", at: selfLocation)

        do {
            try text.write(toFile: filepath, atomically: true, encoding: String.Encoding.utf8.rawValue)
        } catch {
            print(error)
        }

    }
}

fileprivate extension FileOutStream {
    mutating func _write(fake text: String, realText: String) {
        gen!.append("#ifndef \(realText)\n")
        gen!.append("#define \(realText) \(text)\n")
        gen!.append("#endif\n\n")
    }

    mutating func _write(macro: String) {
        gen!.append("#ifndef \(macro)\n")
        gen!.append("# define \(macro)\n")
        gen!.append("#endif // !\(macro)\n\n")
    }
}
