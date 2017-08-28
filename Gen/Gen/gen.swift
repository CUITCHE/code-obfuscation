//
//  gen.swift
//  Gen
//
//  Created by hejunqiu on 2017/8/28.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

import Foundation

struct Gen {
    fileprivate var cache      = EnumerateObjectiveClass()
    fileprivate var fileBuffer = NSMutableString.init()

    func gencode() {
        guard validation() else {
            print("Invalid!")
            return
        }
        gen()
        do {
            try fileBuffer.write(toFile: (NSTemporaryDirectory() as NSString).appendingPathComponent("GenMetaData.cpp"), atomically: true, encoding: String.Encoding.utf8.rawValue)
            print("Generate successfully! File at \(NSTemporaryDirectory())GenMetaData.cpp")
            exit(0)
        } catch {
            print(error)
            exit(-1)
        }
    }
}

fileprivate extension Gen {
    func validation() -> Bool {
        let path = (NSTemporaryDirectory() as NSString).appendingPathComponent("output.data")
        guard NSKeyedArchiver.archiveRootObject(cache, toFile: path) else {
            print("Archiver Failed...")
            return false
        }
        if let data = NSData.init(contentsOfFile: path) {
            if let check = NSKeyedUnarchiver.unarchiveObject(with: data as Data) {
                return NSDictionary.init(dictionary: cache).isEqual(to: check as! [AnyHashable : Any])
            }
        }
        return false
    }

    func writeln(_ content: String) {
        fileBuffer.append("\(content)\n")
    }

    func write_prepare() {
        writeln("/////  For iOS SDK \(ProcessInfo.processInfo.operatingSystemVersionString)\n")
        writeln("#ifndef structs_h\n#define structs_h\n")

        writeln("struct __method__ {\n" +
                "    const char *name;\n" +
                "};\n")

        writeln("struct __method__list {\n" +
                "    unsigned int reserved;\n" +
                "    unsigned int count;\n" +
                "    struct __method__ methods[0];\n" +
                "};\n")

        writeln("struct __class__ {\n" +
                "    struct __class__ *superclass;\n" +
                "    const char *name;\n" +
                "    const struct __method__list *method_list;\n" +
                "};\n")

        writeln("#ifndef CO_EXPORT")
        writeln("#define CO_EXPORT extern \"C\"")
        writeln("#endif")
    }

    func _write(clazzName: String, methodcount: Int, methoddesc: String) {
        writeln("")
        writeln("/// Meta data for \(clazzName)")
        writeln("")
        writeln("static struct /*__method__list_t*/ {")
        writeln("    unsigned int entsize;")
        writeln("    unsigned int method_count;")
        writeln("    struct __method__ method_list[\(methodcount == 0 ? 1 : methodcount)];")
        writeln("} _CO_METHODNAMES_\(clazzName)_$ __attribute__ ((used, section (\"__DATA,__co_const\"))) = {")
        writeln("    sizeof(__method__),")
        writeln("    \(methodcount),")
        writeln("    {\(methoddesc)}\n};")

        var super_class_t: String? = nil
        if let superClass = class_getSuperclass(NSClassFromString(clazzName)) {
            super_class_t = "_CO_CLASS_$_\(NSString.init(utf8String: class_getName(superClass)) ?? "")"
            writeln("\nCO_EXPORT struct __class__ \(super_class_t!);")
        }
        writeln("CO_EXPORT struct __class__ _CO_CLASS_$_\(clazzName) __attribute__ ((used, section (\"__DATA,__co_data\"))) = {")
        if super_class_t != nil {
            writeln("    &\(super_class_t!),")
        } else {
            writeln("    0,")
        }
        writeln("    \"\(clazzName)\",")
        writeln("    (const struct __method__list *)&_CO_METHODNAMES_\(clazzName)_$\n};")
    }

    func write_tail() {
        writeln("\nCO_EXPORT struct __class__ *L_CO_LABEL_CLASS_$[\(cache.count)] __attribute__((used, section (\"__DATA, __co_classlist\"))) = {")
        for (key, _) in cache {
            writeln("    &_CO_CLASS_$_\(key),")
        }
        fileBuffer.deleteCharacters(in: NSMakeRange(fileBuffer.length - 2, 1))

        writeln("};")

        writeln("\nCO_EXPORT struct /*__image_info*/ {\n" +
                "    const char *version;\n" +
                "    unsigned long size;\n" +
                "} _CO_CLASS_IMAGE_INFO_$ __attribute__ ((used, section (\"__DATA,__co_const\"))) = {\n" +
                "    \"\(ProcessInfo.processInfo.operatingSystemVersionString)\",\n" +
                "    \(cache.count)\n" +
                "};");

        writeln("\n#endif");
    }

    func gen() {
        write_prepare()
        for (key, obj) in cache {
            var methods = [String]()
            for m in obj {
                methods.append(m.method)
            }
            _write(clazzName: key, methodcount: obj.count, methoddesc: "{\"\(methods.joined(separator: "\"},{\""))\"}")
        }
        write_tail()
    }
}
