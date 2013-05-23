//
//  VPPDropDown.m
//  VPPLibraries
//
//  Created by Víctor on 12/12/11.

//Copyright (c) 2012 Víctor Pena Placer (@vicpenap)
//http://www.victorpena.es/
//
//
//Permission is hereby granted, free of charge, to any person obtaining a copy 
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights 
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
//copies of the Software, and to permit persons to whom the Software is furnished
//to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



#import "VPPDropDown.h"

#define CUSTOM_DETAILED_LABEL_COLOR_R	56.0
#define CUSTOM_DETAILED_LABEL_COLOR_G	84.0
#define CUSTOM_DETAILED_LABEL_COLOR_B	135.0


@interface VPPDropDown ()
@property (nonatomic, readwrite) VPPDropDownType type;
@property (nonatomic, readwrite, retain) NSArray *elements;
@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, retain) NSIndexPath *indexPath;
@property (nonatomic, readwrite, retain) UITableView *tableView;
@property (nonatomic, readwrite, assign) id<VPPDropDownDelegate> delegate;
@property (nonatomic, retain) NSIndexPath *globalRootIndexPath;
@end

@implementation VPPDropDown


/* a dictionary of tableviews (keys) and a dictionary of sections nsnumbered (values)
 each dictionary of sections will hold the section nsnumbered (key) and its current
 number of rows nsnumbered (value).
 
 PAY ATTENTION: it doesn't include the root cell in the count.
 */
static NSMutableDictionary *numberOfRows = nil;

/* a dictionary of tableviews (keys) and a dictionary of sections nsnumbered (values)
 each dictionary of sections will hold the section nsnumbered (key) and an array
 of dropdowns (value). */
static NSMutableDictionary *dropDowns = nil;


#pragma mark - Managing dropDowns collection

+ (VPPDropDown *) tableView:(UITableView *)tableView dropdownForIndexPath:(NSIndexPath *)indexPath {
    NSArray *dropDownsInSection = [[dropDowns objectForKey:[NSNumber numberWithInt:[tableView hash]]] 
                                   objectForKey:[NSNumber numberWithInt:indexPath.section]];   
    
   return [[dropDownsInSection filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"self.globalRootIndexPath.row <= %d",indexPath.row]]
           lastObject];
}

- (void) updateGlobalIndexPaths {
    NSArray *dropDownsInSection = [[dropDowns objectForKey:[NSNumber numberWithInt:[self.tableView hash]]] 
                                   objectForKey:[NSNumber numberWithInt:self.indexPath.section]];
    
    int selfPosition = [dropDownsInSection indexOfObject:self];
    
    if (selfPosition == [dropDownsInSection count]-1) {
        // this dropdown is the last one, so any dropdown will be modified
        // no matter the status of this one.
        return;
    }
    
    int numberOfCells = [self.elements count];
    if (!self.expanded) {
        numberOfCells = numberOfCells * (-1);
    }
    for (int i = selfPosition+1; i < [dropDownsInSection count]; i++) {
        VPPDropDown *selectedDD = (VPPDropDown *)[dropDownsInSection objectAtIndex:i];
        NSIndexPath *currentRelIP = selectedDD->_globalRootIndexPath;
        NSIndexPath *newRelIP = [NSIndexPath indexPathForRow:currentRelIP.row+numberOfCells inSection:currentRelIP.section];
        [selectedDD->_globalRootIndexPath release];
        selectedDD->_globalRootIndexPath = [newRelIP retain];
    }
}

+ (void) addNumberOfRows:(int)nnumberOfRows forSection:(int)section inTableView:(UITableView *)tableView {
    if (!numberOfRows) {
        numberOfRows = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableDictionary *sections = [numberOfRows objectForKey:[NSNumber numberWithInt:[tableView hash]]];
    if (!sections) {
        sections = [NSMutableDictionary dictionary];
    }    
    
    
    NSNumber *n = [sections objectForKey:[NSNumber numberWithInt:section]];
    if (!n) {
        n = [NSNumber numberWithInt:0];
    }
    n = [NSNumber numberWithInt:[n intValue]+nnumberOfRows];
    [sections setObject:n forKey:[NSNumber numberWithInt:section]];
    [numberOfRows setObject:sections forKey:[NSNumber numberWithInt:[tableView hash]]];
}

- (void) removeFromDropDownsList {
    if (!dropDowns) {
        return;
    }
    
    NSMutableDictionary *sections = [dropDowns objectForKey:[NSNumber numberWithInt:[self.tableView hash]]];
    if (!sections) {
        return;
    }
    NSMutableArray *dropdowns = [NSMutableArray arrayWithArray:
                                 [sections objectForKey:[NSNumber numberWithInt:self.indexPath.section]]];
    if (!dropdowns) {
        return;
    }
    if ([dropdowns containsObject:self]) {
        [dropdowns removeObject:self];
        
        [sections setObject:[dropdowns sortedArrayUsingDescriptors:
                             [NSArray arrayWithObject:
                              [NSSortDescriptor sortDescriptorWithKey:@"indexPath.row" ascending:YES]]] 
                     forKey:[NSNumber numberWithInt:self.indexPath.section]];
        [dropDowns setObject:sections forKey:[NSNumber numberWithInt:[self.tableView hash]]];
    }
}


- (void) dispose {
    if (self.expanded) {
        int numberOfRows = self.numberOfRows * -1;
        [VPPDropDown addNumberOfRows:numberOfRows forSection:self.indexPath.section inTableView:self.tableView];
        _expanded = NO;
        [self updateGlobalIndexPaths];
    }
    [self removeFromDropDownsList];
}


- (void) addToDropDownsList {
    if (!dropDowns) {
        dropDowns = [[NSMutableDictionary alloc] init]; 
    }
    
    NSMutableDictionary *sections = [dropDowns objectForKey:[NSNumber numberWithInt:[self.tableView hash]]];
    if (!sections) {
        sections = [NSMutableDictionary dictionary];
    }
    NSMutableArray *dropdowns = [NSMutableArray arrayWithArray:
                                 [sections objectForKey:[NSNumber numberWithInt:self.indexPath.section]]];
    if (!dropdowns) {
        dropdowns = [NSMutableArray array];
    }
    else {
        // let's see if there's already a dropdown for the indexPath specified.
        // if so, let's remove it.
        NSArray *filteredDDs = [dropdowns filteredArrayUsingPredicate:
                                [NSPredicate predicateWithFormat:@"indexPath.row == %d",self.indexPath.row]];
        
        if ([filteredDDs count] != 0) {
            VPPDropDown *dd = [filteredDDs objectAtIndex:0];
            [dd dispose];
            
            // after removing the dd, let's update the list
            dropdowns = [NSMutableArray arrayWithArray:
                         [sections objectForKey:[NSNumber numberWithInt:self.indexPath.section]]];
        }
    }
    
    [dropdowns addObject:self];
    
    [sections setObject:[dropdowns sortedArrayUsingDescriptors:
                         [NSArray arrayWithObject:
                          [NSSortDescriptor sortDescriptorWithKey:@"indexPath.row" ascending:YES]]] 
                 forKey:[NSNumber numberWithInt:self.indexPath.section]];
    [dropDowns setObject:sections forKey:[NSNumber numberWithInt:[self.tableView hash]]];
}




#pragma mark - Utilities

+ (UIColor *) detailColor {
    float R = CUSTOM_DETAILED_LABEL_COLOR_R/255.0;
    float G = CUSTOM_DETAILED_LABEL_COLOR_G/255.0;
    float B = CUSTOM_DETAILED_LABEL_COLOR_B/255.0;
    
    return [UIColor colorWithRed:R green:G blue:B alpha:1.0];
}

- (NSUInteger) hash {
    int prime = 31;
    int result = 1;
    
    result = prime * result + [self.indexPath hash];
    result = prime * result + [self.tableView hash];
    
    return result;
}

#pragma mark -
#pragma mark Constructors

- (VPPDropDown *) initWithTitle:(NSString *)title 
                           type:(VPPDropDownType)type
                      tableView:(UITableView *)tableView
                      indexPath:(NSIndexPath *)indexPath
                       elements:(NSArray *)elements 
                       delegate:(id<VPPDropDownDelegate>)delegate {
    
    if (self = [super init]) {
        self.title = title;
        self.type = type;
        self.elements = elements;
        self.delegate = delegate;
        self.indexPath = indexPath;
        self.globalRootIndexPath = indexPath;
        self.tableView = tableView;
        
        [self addToDropDownsList];
    }
    
    return self;
}


- (void) dealloc {
    self.object = nil;
    self.title = nil;
    self.elements = nil;
    self.delegate = nil;
    self.indexPath = nil;
    self.globalRootIndexPath = nil;
    self.tableView = nil;

    [super dealloc];
}


- (VPPDropDown *) initDisclosureWithTitle:(NSString *)title 
                                tableView:(UITableView *)tableView
                                indexPath:(NSIndexPath *)indexPath
                                 delegate:(id<VPPDropDownDelegate>)delegate
                            elementTitles:(NSString *)firstObject, ... {
    NSMutableArray *arr = [NSMutableArray array];
    
    NSString *eachObject;
    va_list argumentList;
    VPPDropDownElement *element;
    if (firstObject) // The first argument isn't part of the varargs list,
    {                                   // so we'll handle it separately.
        element = [[VPPDropDownElement alloc] init];
        element.title = firstObject;
        element.object = nil;
        [arr addObject:element];
        [element release];
        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
        while ((eachObject = va_arg(argumentList, NSString *))) {// As many times as we can get an argument of type "NSString *"
            // that isn't nil, add it to self's contents.
            element = [[VPPDropDownElement alloc] init];
            element.title = eachObject;
            element.object = nil;
            [arr addObject:element];
            [element release];
        }
        va_end(argumentList);
    }

    return [self initWithTitle:title type:VPPDropDownTypeDisclosure tableView:tableView indexPath:indexPath elements:arr delegate:delegate];
}

- (VPPDropDown *) initSelectionWithTitle:(NSString *)title
                               tableView:(UITableView *)tableView
                               indexPath:(NSIndexPath *)indexPath
                                delegate:(id<VPPDropDownDelegate>)delegate 
                           selectedIndex:(int)selectedIndex
                           elementTitles:(NSString *)firstObject, ... {
    NSMutableArray *arr = [NSMutableArray array];
    
    NSString *eachObject;
    va_list argumentList;
    VPPDropDownElement *element;
    if (firstObject) // The first argument isn't part of the varargs list,
    {                                   // so we'll handle it separately.
        element = [[VPPDropDownElement alloc] init];
        element.title = firstObject;
        element.object = nil;
        [arr addObject:element];
        [element release];
        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
        while ((eachObject = va_arg(argumentList, NSString *))) {// As many times as we can get an argument of type "NSString *"
            // that isn't nil, add it to self's contents.
            element = [[VPPDropDownElement alloc] init];
            element.title = eachObject;
            element.object = nil;
            [arr addObject:element];
            [element release];
        }
        va_end(argumentList);
    }
    
    VPPDropDown *dd = [self initWithTitle:title type:VPPDropDownTypeSelection tableView:tableView indexPath:indexPath elements:arr delegate:delegate];
    dd->_selectedIndex = selectedIndex;
    
    return dd;
}

#pragma mark -
#pragma mark Table View Data Source

+ (BOOL) tableView:(UITableView *)tableView dropdownsContainIndexPath:(NSIndexPath *)indexPath {
    NSArray *dropDownsInSection = [[dropDowns objectForKey:[NSNumber numberWithInt:[tableView hash]]] 
                                   objectForKey:[NSNumber numberWithInt:indexPath.section]];
    if (!dropDownsInSection) {
        return NO;
    }
    
    // pick VPPDropDown, that is show above indexPath.row.
    NSArray *filteredDDs = [dropDownsInSection filteredArrayUsingPredicate:
                            [NSPredicate predicateWithFormat:@"indexPath.section == %d && indexPath.row <= %d",
                             indexPath.section, indexPath.row]];
    
    // if no VPPDropDown, this cell is not VPPDropDown.
    if ([filteredDDs count] <= 0) {
        return NO;
    }
    
    NSUInteger numOfExpendedRow = 0;
    VPPDropDown *prevDD = nil;
    for (VPPDropDown *d in filteredDDs) {
        if (prevDD.isExpanded
            && prevDD.indexPath.row <= d.indexPath.row
            && d.indexPath.row <= prevDD.indexPath.row + prevDD.numberOfRows)
        {
            if (d.indexPath.row + numOfExpendedRow != indexPath.row) {
                break;
            }
        }
        prevDD = d;
        if (d.isExpanded) {
            numOfExpendedRow += d.numberOfRows;
        }
    }
    
    VPPDropDown *closelyDd = prevDD;
    
    NSInteger closelyDdExpandRow = closelyDd.isExpanded ? closelyDd.numberOfRows : 0;
    NSInteger ddDiff = numOfExpendedRow - closelyDdExpandRow;
    NSIndexPath *closelyDdIndexPath = [NSIndexPath indexPathForRow:closelyDd.indexPath.row + ddDiff
                                                         inSection:closelyDd.indexPath.section];
    if (numOfExpendedRow <= 0) {
        return [indexPath compare:closelyDdIndexPath] == NSOrderedSame;
    } else {
        return (closelyDdIndexPath.row <= indexPath.row
                && indexPath.row <= closelyDdIndexPath.row + closelyDdExpandRow);
    }
}

- (NSIndexPath *) convertIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *new = [NSIndexPath indexPathForRow:indexPath.row-self.globalRootIndexPath.row inSection:self.globalRootIndexPath.section];
    
    return new;
}


- (BOOL) isRootCellAtIndexPath:(NSIndexPath *)indexPath {
    return self.globalRootIndexPath.section-indexPath.section == 0
    && self.globalRootIndexPath.row-indexPath.row == 0;
}

+ (BOOL) tableView:(UITableView *)tableView isRootCellAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *dropdownsInSection = [[dropDowns objectForKey:[NSNumber numberWithInt:[tableView hash]]] 
                                   objectForKey:[NSNumber numberWithInt:indexPath.section]];
    
    dropdownsInSection = [dropdownsInSection filteredArrayUsingPredicate:
                          [NSPredicate predicateWithFormat:@"self.globalRootIndexPath.row == %d",indexPath.row]];
    
    return [dropdownsInSection count] == 1;
}


- (UITableViewCell *) disclosureCellForRowAtIndexPath:(NSIndexPath *)globalIndexPath  {
    static NSString *SelectionCellIdentifier = @"VPPDropDownDisclosureCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:SelectionCellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:SelectionCellIdentifier] autorelease];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor darkTextColor];    
    cell.accessoryView = nil;
    cell.detailTextLabel.text = nil;
    cell.textLabel.textColor = [UIColor darkTextColor];
    
    NSIndexPath *iPath = [self convertIndexPath:globalIndexPath];
    
    if (iPath.row == 0) {
        cell.textLabel.text = self.title;
        if (self.expanded) {
            UIImageView *imView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableContract"]];
            cell.accessoryView = imView;
            [imView release];
            cell.textLabel.textColor = [VPPDropDown detailColor];
        }
        else {
            UIImageView *imView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableExpand"]];
            cell.accessoryView = imView;
            [imView release];            
        }
        
    }
    else {
        VPPDropDownElement *elt = (VPPDropDownElement *) [self.elements objectAtIndex:iPath.row - 1]; // -1 because options cells start in 1 (0 is root cell)
        cell.textLabel.text = elt.title;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (UITableViewCell *) selectionCellForRowAtIndexPath:(NSIndexPath *)globalIndexPath  {
    static NSString *SelectionCellIdentifier = @"VPPDropDownSelectionCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:SelectionCellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:SelectionCellIdentifier] autorelease];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor darkTextColor];    
    cell.accessoryView = nil;
    cell.detailTextLabel.text = nil;
    cell.textLabel.textColor = [UIColor darkTextColor];
    
    NSIndexPath *iPath = [self convertIndexPath:globalIndexPath];
    
    if (iPath.row == 0) {
        cell.textLabel.text = self.title;
        if (self.expanded) {
            UIImageView *imView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableContract"]];
            cell.accessoryView = imView;
            [imView release];
            cell.textLabel.textColor = [VPPDropDown detailColor];
        }
        else {
            cell.detailTextLabel.text = [(VPPDropDownElement *) [self.elements objectAtIndex:_selectedIndex] title];
            UIImageView *imView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableExpand"]];
            cell.accessoryView = imView;
            [imView release];            
        }
        
    }
    else {
        VPPDropDownElement *elt = (VPPDropDownElement *) [self.elements objectAtIndex:iPath.row - 1]; // -1 because options cells start in 1 (0 is root cell)
        cell.textLabel.text = elt.title;
        if (_selectedIndex == iPath.row-1) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.textLabel.textColor = [VPPDropDown detailColor];
        }
    }
    
    return cell;
}


- (UITableViewCell *) customCellForRowAtIndexPath:(NSIndexPath *)globalIndexPath {
    NSIndexPath *iPath = [self convertIndexPath:globalIndexPath];
    
    UITableViewCell *cell = nil;
    if (iPath.row == 0) {
        cell = [self.delegate dropDown:self rootCellAtGlobalIndexPath:globalIndexPath];
        
    }
    else {
        cell = [self.delegate dropDown:self cellForElement:(VPPDropDownElement *) [self.elements objectAtIndex:iPath.row - 1] atGlobalIndexPath:globalIndexPath];
    }
    
    // if user doesn't return a customized cell, we'll create a basic one
    if (cell == nil) {
        cell = [self disclosureCellForRowAtIndexPath:globalIndexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if (iPath.row == 0) {
        if (self.expanded) {
            UIImageView *imView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableContract"]];
            cell.accessoryView = imView;
            [imView release];
        }
        else {
            UIImageView *imView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableExpand"]];
            cell.accessoryView = imView;
            [imView release];            
        }
        
    }
    
    return cell;
}


// PAY ATTENTION: numberOfRows doesn't include the root cell in the count.
+ (NSInteger) tableView:(UITableView *)tableView numberOfExpandedRowsInSection:(NSInteger)section {
    NSMutableDictionary *d = [numberOfRows objectForKey:[NSNumber numberWithInt:[tableView hash]]];
    NSNumber *n = [d objectForKey:[NSNumber numberWithInt:section]];
    
    return [n intValue];
}

+ (NSInteger)tableView:(UITableView *)tableView numberOfExpandedRowsInSection:(NSInteger)section aboveRow:(NSInteger)row {
    NSArray *dropDownsInSection = [[dropDowns objectForKey:[NSNumber numberWithInt:[tableView hash]]]
                                   objectForKey:[NSNumber numberWithInt:section]];
    if (!dropDownsInSection) {
        return NO;
    }

    NSArray *filteredDDs = [dropDownsInSection filteredArrayUsingPredicate:
                            [NSPredicate predicateWithFormat:@"indexPath.row < %d", row - 1]];
    NSUInteger numOfExpendedRow = 0;
    for (VPPDropDown *d in filteredDDs) {
        if (d.isExpanded) {
            numOfExpendedRow += d.numberOfRows;
        }
    }
    return numOfExpendedRow;
}

- (int) numberOfRows {
    int tmp = 0; // root cell is not counted
    if (self.expanded) {
        tmp += [self.elements count];
    }
    
    return tmp;
}


+ (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![VPPDropDown tableView:tableView dropdownsContainIndexPath:indexPath]) {
        NSLog(@"VPPDropDown - Receiving actions about an unknown cell");
        return nil;
    }
    
    VPPDropDown *dd = [VPPDropDown tableView:tableView dropdownForIndexPath:indexPath];
    switch (dd->_type) {
        case VPPDropDownTypeDisclosure:
            return [dd disclosureCellForRowAtIndexPath:indexPath];
            
        case VPPDropDownTypeSelection:
            return [dd selectionCellForRowAtIndexPath:indexPath];
            
        case VPPDropDownTypeCustom:
            return [dd customCellForRowAtIndexPath:indexPath];
    }
    
    return nil;
}



#pragma mark -
#pragma mark Table View Delegate

- (void) toggleDropDown {
    _expanded = !self.expanded;

    int rowsToAdd = [self.elements count];
    if (!self.expanded) {
        rowsToAdd = -1 * rowsToAdd;
    }
    [VPPDropDown addNumberOfRows:rowsToAdd forSection:self.indexPath.section inTableView:self.tableView];
    [self updateGlobalIndexPaths];

    if (self.usesEntireSection) {
        // we can add or remove the cells as we manage the entire section
        NSMutableArray *indexPaths = [NSMutableArray array];
        for (int i = 1; i <= [self.elements count]; i++) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:self.indexPath.row+i inSection:self.indexPath.section];
            [indexPaths addObject:ip];
        }
        
        if (self.expanded) {
            // table view insert rows
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
        }
        
        else {
            // table view remove rows
            [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
        }
        
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:self.indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }

    else {
        // as we dont manage the section, just refresh it, no additions or removals
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:self.indexPath.section];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
    
    if (self.expanded) {
        // scroll to last cell if needed
        NSIndexPath *lastRow = [NSIndexPath indexPathForRow:self.globalRootIndexPath.row + [self.elements count] inSection:self.globalRootIndexPath.section];
        UITableViewCell *lastVisibleCell = [self.tableView.visibleCells lastObject];
        NSIndexPath *lastVisibleIndexPath = [self.tableView indexPathForCell:lastVisibleCell];
        // lets scroll if only half of the cells are visible
        if (lastVisibleIndexPath.section <= lastRow.section && lastVisibleIndexPath.row <= lastRow.row) {
            [self.tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
}



- (void) disclosureDidSelectRowAtIndexPath:(NSIndexPath *)globalIndexPath {
    NSIndexPath *iPath = [self convertIndexPath:globalIndexPath];
    
    // delegate would do whatever it wants: change nspreference, ...
    [self.delegate dropDown:self elementSelected:[self.elements objectAtIndex:iPath.row - 1] atGlobalIndexPath:globalIndexPath];
}

- (void) selectionDidSelectRowAtIndexPath:(NSIndexPath *)globalIndexPath {
    NSIndexPath *iPath = [self convertIndexPath:globalIndexPath];

    _selectedIndex = iPath.row - 1;

    NSMutableArray *reloadIndexPaths = [NSMutableArray array];
    for (int i = 0; i <= [self.elements count]; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:self.indexPath.row + i
                                               inSection:self.indexPath.section];
        [reloadIndexPaths addObject:path];
    }

    [self.tableView reloadRowsAtIndexPaths:reloadIndexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView reloadRowsAtIndexPaths:@[globalIndexPath] withRowAnimation:UITableViewRowAnimationFade];

    // delegate would do whatever it wants: change nspreference, ...
    [self.delegate dropDown:self elementSelected:[self.elements objectAtIndex:_selectedIndex] atGlobalIndexPath:globalIndexPath];
}





+ (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)globalIndexPath {
    if ([VPPDropDown tableView:tableView dropdownsContainIndexPath:globalIndexPath]) {
        VPPDropDown *dd = [VPPDropDown tableView:tableView dropdownForIndexPath:globalIndexPath];
        if ([dd convertIndexPath:globalIndexPath].row == 0) {
            // we are on root cell
            [dd toggleDropDown];
        }
        
        else {
            switch (dd->_type) {
                case VPPDropDownTypeCustom: // at this time, clicking on custom dropdown does the same thing than clicking on disclosure
                case VPPDropDownTypeDisclosure:
                    [dd disclosureDidSelectRowAtIndexPath:globalIndexPath];
                    break;
                case VPPDropDownTypeSelection:
                    [dd selectionDidSelectRowAtIndexPath:globalIndexPath];
                    [tableView deselectRowAtIndexPath:globalIndexPath animated:YES];
                    break;
            }
        }
    }
    
    else {
        NSLog(@"VPPDropDown - Receiving actions about an unknown cell");
    }
}


+ (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([VPPDropDown tableView:tableView dropdownsContainIndexPath:indexPath]) {
        VPPDropDown *dd = [VPPDropDown tableView:tableView dropdownForIndexPath:indexPath];
        NSIndexPath *iPath = [dd convertIndexPath:indexPath];

        if ([dd.delegate respondsToSelector:@selector(dropDown:heightForElement:atIndexPath:)]) {
            VPPDropDownElement *element = nil;
            if (iPath.row > 0) {
                element = [dd.elements objectAtIndex:iPath.row-1];
            }
            return [dd.delegate dropDown:dd heightForElement:element atIndexPath:indexPath];
        }
        else {
            return tableView.rowHeight;
        }
    }
    else {
        NSLog(@"VPPDropDown - Receiving actions about an unknown cell");

        return -1;
    }
}


#pragma mark -
#pragma mark Managing dropdown status

- (void) setExpanded:(BOOL)expanded {
    if (self.expanded != expanded) {
        [self toggleDropDown];
    }
}

- (void) setSelectedIndex:(int)selectedIndex {
    _selectedIndex = selectedIndex;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
}







#pragma mark - Deprecated methods

- (BOOL) containsRelativeIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != self.indexPath.section) {
        return NO;
    }
    
    int tmp = indexPath.row - self.indexPath.row;
    return (tmp >= 0) && (tmp <= [self numberOfRows]);
}

- (NSIndexPath *) convertRelativeIndexPath:(NSIndexPath *)indexPath {
        //casting to id to supress deprecated warnings
    if (![(id)self containsRelativeIndexPath:indexPath]) {
        return nil;
    }
    
    NSIndexPath *new = [NSIndexPath indexPathForRow:indexPath.row-self.indexPath.row inSection:self.indexPath.section];
    
    return new;
}


- (BOOL) isRootCellAtRelativeIndexPath:(NSIndexPath *)relativeIndexPath {
    NSIndexPath *converted = [self convertRelativeIndexPath:relativeIndexPath];
    
    if (!converted) {
        return NO;
    }
    
    return converted.row == 0;
}

- (UITableViewCell *) disclosureCellForRowAtRelativeIndexPath:(NSIndexPath *)indexPath globalIndexPath:(NSIndexPath *)globalIndexPath  {
    static NSString *SelectionCellIdentifier = @"VPPDropDownDisclosureCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:SelectionCellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:SelectionCellIdentifier] autorelease];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor darkTextColor];    
    cell.accessoryView = nil;
    cell.detailTextLabel.text = nil;
    cell.textLabel.textColor = [UIColor darkTextColor];
    
    NSIndexPath *iPath = [self convertRelativeIndexPath:indexPath];
    
    if (iPath.row == 0) {
        cell.textLabel.text = self.title;
        if (self.expanded) {
            UIImageView *imView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableContract"]];
            cell.accessoryView = imView;
            [imView release];
            cell.textLabel.textColor = [VPPDropDown detailColor];
        }
        else {
            UIImageView *imView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableExpand"]];
            cell.accessoryView = imView;
            [imView release];            
        }
        
    }
    else {
        VPPDropDownElement *elt = (VPPDropDownElement *) [self.elements objectAtIndex:iPath.row - 1]; // -1 because options cells start in 1 (0 is root cell)
        cell.textLabel.text = elt.title;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (UITableViewCell *) selectionCellForRowAtRelativeIndexPath:(NSIndexPath *)indexPath globalIndexPath:(NSIndexPath *)globalIndexPath  {
    static NSString *SelectionCellIdentifier = @"VPPDropDownSelectionCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:SelectionCellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:SelectionCellIdentifier] autorelease];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor darkTextColor];    
    cell.accessoryView = nil;
    cell.detailTextLabel.text = nil;
    cell.textLabel.textColor = [UIColor darkTextColor];
    
    NSIndexPath *iPath = [self convertRelativeIndexPath:indexPath];
    
    if (iPath.row == 0) {
        cell.textLabel.text = self.title;
        if (self.expanded) {
            UIImageView *imView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableContract"]];
            cell.accessoryView = imView;
            [imView release];
            cell.textLabel.textColor = [VPPDropDown detailColor];
        }
        else {
            cell.detailTextLabel.text = [(VPPDropDownElement *) [self.elements objectAtIndex:_selectedIndex] title];
            UIImageView *imView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableExpand"]];
            cell.accessoryView = imView;
            [imView release];            
        }
        
    }
    else {
        VPPDropDownElement *elt = (VPPDropDownElement *) [self.elements objectAtIndex:iPath.row - 1]; // -1 because options cells start in 1 (0 is root cell)
        cell.textLabel.text = elt.title;
        if (_selectedIndex == iPath.row-1) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.textLabel.textColor = [VPPDropDown detailColor];
        }
    }
    
    return cell;
}


- (UITableViewCell *) customCellForRowAtRelativeIndexPath:(NSIndexPath *)relativeIndexPath globalIndexPath:(NSIndexPath *)globalIndexPath {
    NSIndexPath *iPath = [self convertRelativeIndexPath:relativeIndexPath];
    
    UITableViewCell *cell = nil;
    if (iPath.row == 0) {
        cell = [self.delegate dropDown:self rootCellAtGlobalIndexPath:globalIndexPath];
        
    }
    else {
        cell = [self.delegate dropDown:self cellForElement:(VPPDropDownElement *) [self.elements objectAtIndex:iPath.row - 1] atGlobalIndexPath:globalIndexPath];
    }
    
    // if user doesn't return a customized cell, we'll create a basic one
    if (cell == nil) {
        cell = [self disclosureCellForRowAtRelativeIndexPath:relativeIndexPath globalIndexPath:globalIndexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if (iPath.row == 0) {
        if (self.expanded) {
            UIImageView *imView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableContract"]];
            cell.accessoryView = imView;
            [imView release];
        }
        else {
            UIImageView *imView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableExpand"]];
            cell.accessoryView = imView;
            [imView release];            
        }
        
    }
    
    return cell;
}



- (UITableViewCell *) cellForRowAtRelativeIndexPath:(NSIndexPath *)indexPath globalIndexPath:(NSIndexPath *)globalIndexPath  {
    if (![self containsRelativeIndexPath:indexPath]) {
        NSLog(@"VPPDropDown - Receiving actions about an unknown cell");
        return nil;
    }
    
    switch (self.type) {
        case VPPDropDownTypeDisclosure:
            return [self disclosureCellForRowAtRelativeIndexPath:indexPath globalIndexPath:globalIndexPath];
            
        case VPPDropDownTypeSelection:
            return [self selectionCellForRowAtRelativeIndexPath:indexPath globalIndexPath:globalIndexPath];
            
        case VPPDropDownTypeCustom:
            return [self customCellForRowAtRelativeIndexPath:indexPath globalIndexPath:globalIndexPath];
    }
    
    return nil;
}


- (void) disclosureDidSelectRowAtRelativeIndexPath:(NSIndexPath *)relativeIndexPath globalIndexPath:(NSIndexPath *)globalIndexPath {
    NSIndexPath *iPath = [self convertRelativeIndexPath:relativeIndexPath];
    
    // delegate would do whatever it wants: change nspreference, ...
    [self.delegate dropDown:self elementSelected:[self.elements objectAtIndex:iPath.row - 1] atGlobalIndexPath:globalIndexPath];
}

- (void) selectionDidSelectRowAtRelativeIndexPath:(NSIndexPath *)relativeIndexPath globalIndexPath:(NSIndexPath *)globalIndexPath {
    NSIndexPath *iPath = [self convertRelativeIndexPath:relativeIndexPath];
    NSIndexPath *previousSelectedItem = [NSIndexPath indexPathForRow:_selectedIndex+1 inSection:relativeIndexPath.section];
    
    _selectedIndex = iPath.row-1;
    
    // delegate would do whatever it wants: change nspreference, ...
    [self.delegate dropDown:self elementSelected:[self.elements objectAtIndex:_selectedIndex] atGlobalIndexPath:globalIndexPath];

    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:previousSelectedItem, self.indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:globalIndexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
}


- (void) didSelectRowAtRelativeIndexPath:(NSIndexPath *)relativeIndexPath
                         globalIndexPath:(NSIndexPath *)globalIndexPath {
        //casting to id to supress deprecated warnings
    if ([(id)self containsRelativeIndexPath:relativeIndexPath]) {
        if ([self convertRelativeIndexPath:relativeIndexPath].row == 0) {
            // we are on root cell
            [self toggleDropDown];
        }
        
        else {
            switch (self.type) {
                case VPPDropDownTypeCustom: // at this time, clicking on custom dropdown does the same thing than clicking on disclosure
                case VPPDropDownTypeDisclosure:
                    [self disclosureDidSelectRowAtRelativeIndexPath:relativeIndexPath globalIndexPath:globalIndexPath];
                    break;
                case VPPDropDownTypeSelection:
                    [self selectionDidSelectRowAtRelativeIndexPath:relativeIndexPath globalIndexPath:globalIndexPath];
                    [self.tableView deselectRowAtIndexPath:globalIndexPath animated:YES];
                    break;
            }
        }
    }
    
    else {
        NSLog(@"VPPDropDown - Receiving actions about an unknown cell");
    }
}




@end



//Copied from http://developer.apple.com/library/mac/#qa/qa1405/_index.html
//
//- (void) appendObjects:(id) firstObject, ...
//{
//    id eachObject;
//    va_list argumentList;
//    if (firstObject) // The first argument isn't part of the varargs list,
//    {                                   // so we'll handle it separately.
//        [self addObject: firstObject];
//        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
//        while (eachObject = va_arg(argumentList, id)) // As many times as we can get an argument of type "id"
//            [self addObject: eachObject]; // that isn't nil, add it to self's contents.
//        va_end(argumentList);
//    }
//}
