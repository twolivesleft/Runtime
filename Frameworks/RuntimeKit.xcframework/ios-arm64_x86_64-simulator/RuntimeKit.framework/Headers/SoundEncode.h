//
//  SoundEncode.h
//  Codea
//
//  Created by Dylan Sale on 8/01/12.
//  Copyright (c) 2012 Two Lives Left. All rights reserved.
//

#ifndef Codify_SoundEncode_h
#define Codify_SoundEncode_h

#import <Foundation/Foundation.h>

typedef struct sfxr sfxr;
@class ALBuffer;

#if TARGET_OS_SUPPORTS_OPENAL
//Defined in SoundCommands.mm
ALBuffer* playSfxr(sfxr* instance, float volume);

//Defined in SoundCommands.mm
NSString* encodeParametersShort(sfxr* instance);
NSString* encodeParametersFull(sfxr* instance);
bool decodeParameters(const char* base64Encoding, sfxr *instance);
#endif

#endif
