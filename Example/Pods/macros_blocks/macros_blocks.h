//
//  macros_blocks.h
//  macros_blocks
//
//  Created by Alexey Belkevich on 5/14/14.
//  Copyright (c) 2014 okolodev. All rights reserved.
//

#ifndef macros_blocks_h
#define macros_blocks_h

#define safe_block(block, ...) block ? block(__VA_ARGS__) : nil
#define async_queue_block(queue, block, ...) dispatch_async(queue, ^ \
{ \
    safe_block(block, __VA_ARGS__); \
})
#define main_queue_block(block, ...) async_queue_block(dispatch_get_main_queue(), block, __VA_ARGS__);

#endif
