//
//  Test.swift
//  EYViewPager
//
//  Created by Ezimet Yusuf on 7/4/16.
//  Copyright © 2016 Ezimet Yusup. All rights reserved.
//

import Foundation
import UIKit
protocol WormTabStripDelegate:class {
    
    //return the Number SubViews in the ViewPager
    func WTSnumberOfTab()->Int
    //return the View for sepecific position
    func WTSviewOfTab(index:Int)->UIView
    //return the title for each view
    func WTStitlesOfTab(index:Int) -> String
    
    //the delegate that ViewPager has got End with Left Direction
    func WTSgotLeftEdge(panParam:UIPanGestureRecognizer)
    //the delegate that ViewPager has got End with Right Direction
    func WTSgotRightEdge(panParam:UIPanGestureRecognizer)
    
}

enum WormStyle{
    case BUBBLE
    case LINE
}

struct WormTabStripStylePropertyies {
    
    var wormStyel:WormStyle = .BUBBLE
    /**********************
      Heights
     **************************/
    
    var kHeightOfWorm:CGFloat = 3
    
    var kHeightOfWormForBubble:CGFloat = 45
    
    var kHeightOfDivider:CGFloat = 2
    
    var kHeightOfTopScrollView:CGFloat = 50
    
    
    /**********************
     paddings
     **************************/
    
    //Padding of tabs text to each side
    var kPaddingOfIndicator:CGFloat = 30
    
    //initial value for the tabs margin
    var kWidthOfButtonMargin:CGFloat = 0
    
    
    var isHideTopScrollView = false
    
    var spacingBetweenTabs:CGFloat = 15
    
    var isWormEnable = true
    
    /**********
     fonts
     ************/
    // font size of tabs
    //let kFontSizeOfTabButton:CGFloat = 15
    var tabItemDefaultFont:UIFont = UIFont(name: "arial", size: 14)!
    var tabItemSelectedFont:UIFont = UIFont(name: "arial", size: 15)!
    
    /*****
     colors
     ****/
    
    var tabItemDefaultColor:UIColor = .whiteColor()
    
    var tabItemSelectedColor:UIColor = .redColor()
    
    //color for worm
    var WormColor:UIColor = UIColor(netHex: 0x1EAAF1)
    
    var topScrollViewBackgroundColor:UIColor = UIColor(netHex: 0x364756)
    
    var contentScrollViewBackgroundColor:UIColor = UIColor.grayColor()
    
    var dividerBackgroundColor:UIColor = UIColor.redColor()
    
}


class WormTabStrip: UIView,UIScrollViewDelegate {
    
    private let topScrollView:UIScrollView = UIScrollView()
    
    private let contentScrollView:UIScrollView = UIScrollView()
    
    
    var Width:CGFloat!
    
    var Height:CGFloat!
    
    private var titles:[String]! = []
    
    private var contentViews:[UIView]! = []
    
    private var tabs:[WormTabStripButton]! = []
    
    private let divider:UIView = UIView()
    
    private let worm:UIView = UIView()
    
    var eyStyle:WormTabStripStylePropertyies = WormTabStripStylePropertyies()
    
    //delegate
    weak var delegate:WormTabStripDelegate?
    
    //Justify flag
    private var isJustified = false
    
    //tapping flag
    private var isUserTappingTab = false
    
    private var dynamicWidthOfTopScrollView:CGFloat = 0
    
    private let plusOneforMarginOfLastTabToScreenEdge = 1
    //MARK: init
    override init(frame: CGRect) {
        super.init(frame: frame)
        Width = self.frame.width
        Height = self.frame.height
    }
    convenience required init(key:String) {
        self.init(frame:CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
    }
    
    
    func buildUI()  {
        validate()
        addTopScrollView()
        addWorm()
        addDivider()
        addContentScrollView()
        buildContent()
        checkAndJustify()
        natruallySlideWormToPosition(tabs[0])
    }
    
    private func validate(){
        if delegate == nil {
                assert(false, "EYDelegate is null, please set the EYDelegate")
        }
        //        for i in 0..<delegate.EYnumberOfTab() {
        //            titles.append(delegate.EYTitlesOfTab(i))
        //            contentViews.append(delegate.EYviewOfTab(i))
        //        }
        //        
        //        if titles.count != contentViews.count {
        //            assert(false, "title's size and contentView's size not matching")
        //        }
    }
    
    
    // add top scroll view to the view stack which will contain the all the tabs
    private func addTopScrollView(){
        topScrollView.frame = CGRectMake(0, 0, Width,eyStyle.kHeightOfTopScrollView)
        topScrollView.backgroundColor = eyStyle.topScrollViewBackgroundColor
        topScrollView.showsHorizontalScrollIndicator = false
        self.addSubview(topScrollView)
    }
    // add divider between the top scroll view and content scroll view
    private func addDivider(){
        divider.frame = CGRectMake(0, eyStyle.kHeightOfTopScrollView, Width, eyStyle.kHeightOfDivider)
        divider.backgroundColor = eyStyle.dividerBackgroundColor
        self.addSubview(divider)
    }
    // add content scroll view to the view stack which will hold mian  views such like table view ...
    private func addContentScrollView(){
        if eyStyle.isHideTopScrollView {
            //rootScrollView = UIScrollView(frame: CGRectMake(0,0,Width,Height))
            contentScrollView.frame =  CGRectMake(0,0,Width,Height);
        }else{
            contentScrollView.frame = CGRectMake(0, eyStyle.kHeightOfTopScrollView+eyStyle.kHeightOfDivider, Width, Height-eyStyle.kHeightOfTopScrollView-eyStyle.kHeightOfDivider)
        }
        contentScrollView.backgroundColor = eyStyle.contentScrollViewBackgroundColor
        contentScrollView.pagingEnabled = true
        contentScrollView.delegate = self
        contentScrollView.showsHorizontalScrollIndicator = false
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.bounces = false
        contentScrollView.panGestureRecognizer.addTarget(self, action: #selector(scrollHandleUIPanGestureRecognizer))
        self.addSubview(contentScrollView)
    }
    
    private func addWorm(){
        topScrollView.addSubview(worm)
        
        resetHeightOfWorm()
        worm.frame.size.width = 100
        worm.backgroundColor = eyStyle.WormColor
        
    }
    
    private func buildContent(){
        
        buildTopScrollViewsContent()
        buildContentScrollViewsContent()
    }
    
    private func buildTopScrollViewsContent(){
        dynamicWidthOfTopScrollView = 0
        var XOffset:CGFloat = eyStyle.spacingBetweenTabs;
        for i in 0..<delegate!.WTSnumberOfTab() {
            //build the each tab and position it
            let tab:WormTabStripButton = WormTabStripButton()
            tab.index = i
            formatButton(tab, XOffset: XOffset)
            XOffset += eyStyle.spacingBetweenTabs + tab.frame.width
            dynamicWidthOfTopScrollView += eyStyle.spacingBetweenTabs + tab.frame.width
            topScrollView.addSubview(tab)
            tabs.append(tab)
            topScrollView.contentSize.width = dynamicWidthOfTopScrollView
        }
    }
    
    /**************************
     format tab style, tap event
    ***************************************/
    private func formatButton(tab:WormTabStripButton,XOffset:CGFloat){
        tab.frame.size.height = eyStyle.kHeightOfTopScrollView
        tab.paddingToEachSide = eyStyle.kPaddingOfIndicator
        //            tab.backgroundColor = UIColor.yellowColor()
        tab.tabText = delegate!.WTStitlesOfTab(tab.index!)
        tab.textColor = eyStyle.tabItemDefaultColor
        tab.frame.origin.x = XOffset
        tab.frame.origin.y = 0
        tab.textAlignment = .Center
        tab.userInteractionEnabled = true
        let tap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(WormTabStrip.tabPress(_:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tab.addGestureRecognizer(tap)
    }
    
    // add all content views to content scroll view and tabs to top scroll view
    private func buildContentScrollViewsContent(){
        let count = delegate!.WTSnumberOfTab()
        contentScrollView.contentSize.width = CGFloat(count)*self.frame.width
        for i in 0..<count{
            //position each content view
            let view = delegate!.WTSviewOfTab(i)
            view.frame.origin.x = CGFloat(i)*Width
            view.frame.origin.y = 0
            view.frame.size.height = contentScrollView.frame.size.height
            contentScrollView.addSubview(view)
        }
    }
    
    /*** if the content width of the topScrollView smaller than screen width
        do justification to the tabs  by increasing spcases between the tabs
        and rebuild all top and content views
     ***/
    private func checkAndJustify(){
        if dynamicWidthOfTopScrollView < Width && !isJustified {
            isJustified = true            
            // calculate the available space
            let gap:CGFloat = Width - dynamicWidthOfTopScrollView
            // increase the space by dividing available space to # of tab plus one 
            //plus one bc we always want to have margin from last tab to to right edge of screen
            eyStyle.spacingBetweenTabs +=  gap/CGFloat(delegate!.WTSnumberOfTab()+plusOneforMarginOfLastTabToScreenEdge)
            dynamicWidthOfTopScrollView = 0
            var XOffset:CGFloat = eyStyle.spacingBetweenTabs;
            for tab in tabs {
                tab.frame.origin.x = XOffset
                XOffset += eyStyle.spacingBetweenTabs + tab.frame.width
                dynamicWidthOfTopScrollView += eyStyle.spacingBetweenTabs + tab.frame.width
                topScrollView.contentSize.width = dynamicWidthOfTopScrollView
            }
        }
    }
    
    /*******
     tabs selector
     ********/
     func tabPress(sender:AnyObject){
        
        isUserTappingTab = true
        
        let tap:UIGestureRecognizer = sender as! UIGestureRecognizer
        let tab:WormTabStripButton = tap.view as! WormTabStripButton
        
        currentTabIndex = tab.index!
        natruallySlideWormToPosition(tab)
        natruallySlideContentScrollViewToPosition(tab.index!)
        adjustTopScrollViewsContentOffsetX(tab)
    }
    
    /*******
     move worm to the correct position with slinding animation when the tabs are clicked
     ********/
    private func natruallySlideWormToPosition(tab:WormTabStripButton){
        UIView.animateWithDuration(0.3) {
            self.slideWormToTabPosition(tab)
        }
    }
    
    private func slideWormToTabPosition(tab:WormTabStripButton){
        self.worm.frame.origin.x = tab.frame.origin.x
        self.worm.frame.size.width = tab.frame.width
    }
    /*********************
        if the tab was at position of only half of it was showing up,
            we need to adjust it by setting content OffSet X of Top ScrollView
                when the tab was clicked
    *********************/
    private func adjustTopScrollViewsContentOffsetX(tab:WormTabStripButton){
        let widhtOfTab:CGFloat = tab.bounds.size.width
        let XofTab:CGFloat = tab.frame.origin.x
        let spacingBetweenTabs = eyStyle.spacingBetweenTabs
        //if tab at right edge of screen
        if XofTab - topScrollView.contentOffset.x > Width - (spacingBetweenTabs+widhtOfTab) {
            topScrollView.setContentOffset(CGPointMake(XofTab - (Width-(spacingBetweenTabs+widhtOfTab)) , 0), animated: true)
        }
        //if tab at left edge of screen
        if XofTab - topScrollView.contentOffset.x  < spacingBetweenTabs {
            topScrollView.setContentOffset(CGPointMake(XofTab - spacingBetweenTabs, 0), animated: true)
        }
    }
    
    /*******
     move content scroll view to the correct position with animation when the tabs are clicked
     ********/
    private func natruallySlideContentScrollViewToPosition(index:Int){
        let point = CGPointMake(CGFloat(index)*Width, 0)
        UIView.animateWithDuration(0.3, animations: { 
                self.contentScrollView.setContentOffset(point, animated: false)
        }) { (finish) in
                self.isUserTappingTab = false
        }
        
    }
    
    /*************************************************
    //MARK: UIScrollView Delegate start
    ******************************************/
    var currentTabIndex = 0
    var currentWormX:CGFloat = 0
    var currentWormWidth:CGFloat = 0
    var contentScrollContentOffsetX:CGFloat = 0
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        currentTabIndex = Int(scrollView.contentOffset.x/Width)
        let tab = tabs[currentTabIndex]
        currentWormX = tab.frame.origin.x
        currentWormWidth = tab.frame.width
        contentScrollContentOffsetX = scrollView.contentOffset.x
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //if user was tapping tab no need to do worm animation
        if isUserTappingTab == true {return}
        
        let currentX = scrollView.contentOffset.x
        var gap:CGFloat = 0
        
        
        //if user dragging to right, which means scrolling finger from right to left
        //which means scroll view is scrolling to right, worm also should worm to right
        if currentX > contentScrollContentOffsetX {
            gap = currentX -  contentScrollContentOffsetX
            
            if gap > Width {
                contentScrollContentOffsetX = currentX
                currentTabIndex = Int(currentX/Width)
                let tab = tabs[currentTabIndex]
                natruallySlideWormToPosition(tab)
                return
            }
            
            //if currentTab is not last one do worm to next tab position 
            if currentTabIndex + 1 <= tabs.count {
                let nextDistance:CGFloat = calculateNextMoveDistance(gap, nextTotal: getNextTotalWormingDistance(currentTabIndex+1))
                // println(nextDistance)
                setWidthAndHeightOfWormForDistance(nextDistance)

            }
            
            
        }else{
            //else  user dragging to left, which means scrolling finger from  left to right
            //which means scroll view is scrolling to left, worm also should worm to left
            gap = contentScrollContentOffsetX - currentX
            //if current is not first tab at left do worm to left
            if currentTabIndex  >= 1  {
                let nextDistance:CGFloat = calculateNextMoveDistance(gap, nextTotal: getNextTotalWormingDistance(currentTabIndex-1))
                 print(nextDistance)
                wormToNextLeft(nextDistance)
            }
            
            
        }
        
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let currentX = scrollView.contentOffset.x
        currentTabIndex = Int(currentX/Width)
        let tab = tabs[currentTabIndex]
        
        adjustTopScrollViewsContentOffsetX(tab)
        UIView.animateWithDuration(0.23) {
            self.slideWormToTabPosition(tab)
            self.resetHeightOfWorm()
        }
        
    }
    
    /*************************************************
    //MARK:  UIScrollView Delegate end
     ******************************************/
   
    
    /*************************************************
     //MARK:  UIScrollView Delegate Calculations  start
     ******************************************/
    private  func getNextTotalWormingDistance(index:Int)->CGFloat{
        let tab = tabs[index]
        let nextTotal:CGFloat = eyStyle.spacingBetweenTabs + tab.frame.width
        return nextTotal
    }
    
    private func calculateNextMoveDistance(gap:CGFloat,nextTotal:CGFloat)->CGFloat{
        let nextMove:CGFloat = (gap*nextTotal)/Width
        
        return nextMove
        
    }
    
    private func setWidthAndHeightOfWormForDistance(distance:CGFloat){
        if distance < 1 {
            resetHeightOfWorm()
            
        }else{
            let height:CGFloat  = self.calculatePrespectiveHeightOfIndicatorLine(distance)
            worm.frame.size.height = height
            
            worm.frame.size.width = currentWormWidth + distance
        }
        if eyStyle.wormStyel == .LINE {
                worm.frame.origin.y = eyStyle.kHeightOfTopScrollView - eyStyle.kHeightOfWorm
        }else{
                worm.frame.origin.y = (eyStyle.kHeightOfTopScrollView-worm.frame.size.height)/2
        }
        
        
        worm.layer.cornerRadius = worm.frame.size.height/2
    }
    
    private func wormToNextLeft(distance:CGFloat){
        setWidthAndHeightOfWormForDistance(distance)
        worm.frame.origin.x = currentWormX -  distance
    }
    
    private func resetHeightOfWorm(){
        // if the style is line it should be placed under the tab
        if eyStyle.wormStyel == .LINE {
            worm.frame.origin.y = eyStyle.kHeightOfTopScrollView - eyStyle.kHeightOfWorm
            worm.frame.size.height = eyStyle.kHeightOfWorm
            
        }else{
            worm.frame.origin.y = (eyStyle.kHeightOfTopScrollView - eyStyle.kHeightOfWormForBubble)/2
            worm.frame.size.height = eyStyle.kHeightOfWormForBubble
        }
        worm.layer.cornerRadius = worm.frame.size.height/2
    }
    
    private  func calculatePrespectiveHeightOfIndicatorLine(distance:CGFloat)->CGFloat{
        
        var height:CGFloat = 0
        var originalHeight:CGFloat = 0
        if eyStyle.wormStyel == .LINE {
            height =  eyStyle.kHeightOfWorm*(self.currentWormWidth/(distance+currentWormWidth))
            originalHeight = eyStyle.kHeightOfWorm
        }else{
            height =  eyStyle.kHeightOfWormForBubble*(self.currentWormWidth/(distance+currentWormWidth))
            originalHeight = eyStyle.kHeightOfWormForBubble
        }
        
        //if the height of worm becoming too small just make it half of it
        if height < (originalHeight*4/5) {
            height = originalHeight*4/5
        }
        
//        return worm.frame.height
        return height
    }

    /*************************************************
     //MARK:  UIScrollView Delegate Calculations Ends
     ******************************************/
    
    func scrollHandleUIPanGestureRecognizer(panParam:UIPanGestureRecognizer){
        
        if contentScrollView.contentOffset.x <= 0 {
            self.delegate?.WTSgotLeftEdge(panParam)
        }
            
        else
            if contentScrollView.contentOffset.x >= contentScrollView.contentSize.width -  contentScrollView.bounds.size.width {
                self.delegate?.WTSgotRightEdge(panParam)
        }
        
    }
}


extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}
