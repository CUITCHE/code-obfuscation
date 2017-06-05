# code-obfuscation

A code obfuscation tool for iOS.

# Pre-Setting

Copy the directory [Obfuscation-Objective-C File.xctemplate](./Obfuscation-Objective-C File.xctemplate) to `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/File Templates/Source`, like below order:

```sh
sudo cp -r Obfuscation-Objective-C\ File.xctemplate/ /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/File\ Templates/Source
```

Now, you can create obfuscation files in your projects. You might try to create them in your project, and then you will get 3 files.

# How to Use

Execute the order `./CodeObfuscation` at your root path of your project.

> Also set the shell script at you Xcode project to exectue it.

# Obfuscation Syntax

- Add macro `CO_CONFUSION_CLASS` after keyword `@interface` and before classname. It tags the class is added to obfuscation task. e.g.

  ```objective-c
  @interface CO_CONFUSION_CLASS COTemplateFile : NSObject
  @end
  ```

- Also modify the category by `CO_CONFUSION_CATEGORY`. And the macro `CO_CONFUSION_CATEGORY` must be before category-name at bracket e.g.

  ```objective-c
  @interface NSString (CO_CONFUSION_CATEGORY abcde)
  @end
  ```

- Add macro `CO_CONFUSION_PROPERTY` before a property-name declared. It tags the property is added to obfuscation task. e.g.

  ```objective-c
  @interface CO_CONFUSION_CLASS COTemplateFile : NSObject

  @property (nonatomic, strong) NSString * CO_CONFUSION_PROPERTY prop1;
  @property CGFloat CO_CONFUSION_PROPERTY prop2;

  @end
  ```

  ​

- Add macro `CO_CONFUSION_METHOD` before a method head of declare or implementation. It tags the method is added to obfuscation task. e.g.

  ```objective-c
  // .h
  @interface CO_CONFUSION_CLASS COTemplateFile : NSObject

  CO_CONFUSION_METHOD
  - (void)makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2;

  CO_CONFUSION_METHOD
  - (instancetype)initWithArg1:(CGFloat)arg, ...;

  @end

  // .m or .mm
  @implementation COTemplateFile

  CO_CONFUSION_METHOD
  - (void)_private:(NSString *)arg1 method:(float)arg2 scanned:(BOOL)scanned
  {
      ;
  }

  @end
  ```

# Notice

- `CO_CONFUSION_CLASS` and `CO_CONFUSION_CATEGORY` is a prerequisite for `CO_CONFUSION_PROPERTY` and `CO_CONFUSION_METHOD`.
- **COULD NOT** use the code-obfuscation if your code contains runtime code. Unless you control it.

# License

The MIT License.