//
//  CloudFile.h
//  MultiFiles
//
//  Created by Riccardo Rizzo on 03/06/16.
//  Copyright © 2016 Riccardo Rizzo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudFile : NSObject {

@public
    NSString *fileName;
    NSString *createdAt;
    NSString *fileSize;
    NSString *fileRating;
    NSString *fileID;
    
@private
}
@end
