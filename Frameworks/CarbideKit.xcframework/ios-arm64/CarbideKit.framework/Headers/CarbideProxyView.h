//
//  CarbideProxyView.h
//  CarbideKit
//
//  Created by John Millard on 6/10/2022.
//  Copyright © 2022 John Millard. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CarbideView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CarbideProxyView : UIView

@property(readonly) CarbideView* carbideView;

@end

NS_ASSUME_NONNULL_END
