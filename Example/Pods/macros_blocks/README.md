Useful Macros for Objective-c
===

#### Macros for Blocks
Tired with `block != nil` check? Too many code lines to run block on dispatch queue? This macros for you!

Add `pod 'macros_blocks'` to [Podfile](http://guides.cocoapods.org/syntax/podfile.html)

**Call Block Safely**

```objective-c
safe_block(block, arguments);
```

is equal to

```objective-c
if (block)
{
    block(arguments);
}
```

**Call Block on Main Queue**

```objective-c
main_queue_block(block, arguments);
```

is equal to

```objective-c
dispatch_async(dispatch_get_main_queue(), ^
{
    if (block)
    {
        block(arguments);
    }
});
```

**Call Block on Custom Queue Asynchronously**

```objective-c
async_queue_block(queue, block, arguments)
```

is equal to

```objective-c
dispatch_async(queue, ^
{
    if (block)
    {
        block(arguments);
    }
});

```

#### Extra Macros

Add `pod 'macros_blocks/extra'` to [Podfile](http://guides.cocoapods.org/syntax/podfile.html)

**Trim Value in Range**
Value should be greater or equal then minimum and less or equal then maximum. Otherwise it will equal minimum if less or maximum if greater.
```objective-c
range_value(5, 1, 10);   // 1 < 5 < 10 => 5
range_value(0, 1, 10);   // 1 > 0 => 1
range_value(12, 1, 10);  // 10 < 12 => 12
```

**Safe Malloc**
Return `NULL` if `malloc` size is 0.
```objective-c
size_t x = 0;
safe_malloc(x);
```

#### All Macros
Install both 'blocks' and 'extra' macros.

Add `pod 'macros_blocks/all'` to [Podfile](http://guides.cocoapods.org/syntax/podfile.html)
```objective-c
#import <macros_blocks/macros_all.h>
```


#### Updates

Follow updates on twitter [@okolodev](https://twitter.com/okolodev)

**Changelog**

**0.0.3**
* Improved autocomplete for value in range macro

**0.0.2**
* Added trim value in range macro
* Added safe malloc macro

**0.0.1**
* First release
