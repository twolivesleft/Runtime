//
//  TKPDFView.h
//
//  Created by Nigel Barber on 15/10/2011.
//  Copyright 2011 Mindbrix Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TKPDFView : UIView 
{

}

@property( nonatomic, assign ) NSInteger page;
@property( nonatomic, assign ) NSString *resourceName;
@property( nonatomic, assign ) NSURL *resourceURL;

+(CGRect) mediaRect:(NSString *)resourceName;
+(CGRect) mediaRectForURL:(NSURL *)resourceURL;
+(CGRect) mediaRectForURL:(NSURL *)resourceURL atPage:(NSInteger)page;
+(NSInteger) pageCountForURL:(NSURL *)resourceURL;
+(NSURL *)resourceURLForName:(NSString *)resourceName;
  
@end
