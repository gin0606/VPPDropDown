//
//  DropDownExample.h
//  KKLibraries
//
//  Created by Víctor on 13/12/11.
//  Copyright (c) 2011 Víctor Pena Placer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKDropDown.h"
#import "KKDropDownDelegate.h"

@interface DropDownExample : UITableViewController <KKDropDownDelegate, UIActionSheetDelegate> {
@private
    KKDropDown *_dropDownSelection;
    KKDropDown *_dropDownDisclosure;
    KKDropDown *_dropDownCustom;
    
    NSIndexPath *_ipToDeselect;
}

@end
