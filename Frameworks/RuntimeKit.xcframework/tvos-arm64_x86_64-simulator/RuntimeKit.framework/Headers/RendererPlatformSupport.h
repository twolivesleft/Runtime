//
//  RendererPlatformSupport.h
//  Runtime
//
//  Created by Sim Saens on 5/12/2023.
//  Copyright © 2023 Two Lives Left. All rights reserved.
//

#ifdef __OBJC__
    #import <Foundation/Foundation.h>
    #define TARGET_OS_SUPPORTS_GL (!TARGET_OS_MACCATALYST && !TARGET_OS_VISION)
    #define TARGET_OS_SUPPORTS_OPENAL !TARGET_OS_VISION
    #define TARGET_OS_SUPPORTS_CAPTURE (!TARGET_OS_VISION && !TARGET_OS_TV)
#else
    #define TARGET_OS_SUPPORTS_GL 0
    #define TARGET_OS_SUPPORTS_OPENAL 0
    #define TARGET_OS_SUPPORTS_CAPTURE 0
#endif
