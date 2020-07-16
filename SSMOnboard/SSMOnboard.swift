//
//  SSMOnboard.swift
//  SSMOnboard
//
//  Created by Song on 2020/07/16.
//  Copyright © 2020 FACTORY X. All rights reserved.
//

import UIKit

public protocol SSMOnboardDataSource: class {
    func onboardBackgroundColorFor(_ onboard: SSMOnboard, atIndex index: Int) -> UIColor?
    func onboardNumberOfPages(_ onboard: SSMOnboard) -> Int
    func onboardViewForBackground(_ onboard: SSMOnboard) -> UIView?
    func onboardPageForIndex(_ onboard: SSMOnboard, index: Int) -> SSMOnboardPage?
    func onboardViewForOberlay(_ onboard: SSMOnboard) -> SSMOnboardOverlay?
    func onboardOverlayForPosition(_ onboard: SSMOnboard, overlay: SSMOnboardOverlay, for position: Double)
}

public protocol SSMOnboardDelegate: class {
    func onboard(_ onboard: SSMOnboard, currentPage index: Int)
    func onboard(_ onboard: SSMOnboard, leftEdge position: Double)
    func onboard(_ onboard: SSMOnboard, tapped index: Int)
}

public class SSMOnboard: UIView {
    
    open weak var dataSource: SSMOnboardDataSource? {
        didSet {
            if let color = dataSource?.onboardBackgroundColorFor(self, atIndex: 0) {
                backgroundColor = color
            }
        }
    }
    
    open weak var delegate: SSMOnboardDelegate?
    
    fileprivate var containerView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isUserInteractionEnabled = true
        scrollView.isScrollEnabled = true
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        return scrollView
    }()
    
    fileprivate var pageCount = 0
    fileprivate var overlay: SSMOnboardOverlay?
    fileprivate var pages = [SSMOnboardPage]()
    
    open var currentPage: Int{
        return Int(getCurrentPosition())
    }
    open var shouldSwipe = true
    open var fadePages = true
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setupView()
    }
    
    open func goToPage(index: Int, animated: Bool) {
        if index < self.pageCount {
            let index = CGFloat(index)
            containerView.setContentOffset(CGPoint(x: index * self.frame.width, y: 0), animated: animated)
        }
    }
}

//MARK: - SetupView
extension SSMOnboard {
    private func setupView() {
        setBackgroundView()
        setUpContainerView()
        setUpPages()
        setOverlayView()
        containerView.isScrollEnabled = shouldSwipe
    }
    
    fileprivate func setUpContainerView() {
        self.addSubview(containerView)
        self.containerView.frame = self.frame
        containerView.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedPage))
        containerView.addGestureRecognizer(tap)
    }
    
    fileprivate func setBackgroundView() {
        if let dataSource = dataSource, let background = dataSource.onboardViewForBackground(self) {
            self.addSubview(background)
            self.sendSubviewToBack(background)
        }
    }
    
    fileprivate func setUpPages() {
        if let dataSource = dataSource {
            pageCount = dataSource.onboardNumberOfPages(self)
            for index in 0..<pageCount{
                if let view = dataSource.onboardPageForIndex(self, index: index) {
                    self.contentMode = .scaleAspectFit
                    containerView.addSubview(view)
                    var viewFrame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
                    viewFrame.origin.x = self.frame.width * CGFloat(index)
                    view.frame = viewFrame
                    self.pages.append(view)
                }
            }
            containerView.contentSize = CGSize(width: self.frame.width * CGFloat(pageCount), height: self.frame.height)
        }
    }
    
    fileprivate func setOverlayView() {
        if let dataSource = dataSource {
            if let overlay = dataSource.onboardViewForOberlay(self) {
                overlay.page(count: self.pageCount)
                self.addSubview(overlay)
                self.bringSubviewToFront(overlay)
                let viewFrame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
                overlay.frame = viewFrame
                self.overlay = overlay
                self.overlay?.pageControl.addTarget(self, action: #selector(didTapPageControl), for: .allTouchEvents)
            }
        }
    }
}

//MARK: - UIScrollViewDelegate
extension SSMOnboard: UIScrollViewDelegate {
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = Int(getCurrentPosition())
        self.delegate?.onboard(self, currentPage: currentPage)
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPosition = Double(getCurrentPosition())
        self.overlay?.currentPage(index: Int(round(currentPosition)))
        if self.fadePages {
            fadePageTransitions(containerView: scrollView, currentPage: Int(getCurrentPosition()))
        }
        
        self.delegate?.onboard(self, leftEdge: currentPosition)
        if let overlayView = self.overlay {
            self.dataSource?.onboardOverlayForPosition(self, overlay: overlayView, for: currentPosition)
        }
    }
}

//MARK: - Supporting
extension SSMOnboard {
    fileprivate func getCurrentPosition() -> CGFloat {
        let boundsWidth = containerView.bounds.width
        let contentOffset = containerView.contentOffset.x
        let currentPosition = contentOffset / boundsWidth
        return currentPosition
    }
    
    fileprivate func fadePageTransitions(containerView: UIScrollView, currentPage: Int) {
        for (index,page) in pages.enumerated() {
            page.alpha = 1 - abs(abs(containerView.contentOffset.x) - page.frame.width * CGFloat(index)) / page.frame.width
        }
    }
}

//MARK: - IBAction
extension SSMOnboard {
    @objc
    func tappedPage() {
        let currentpage = Int(getCurrentPosition())
        self.delegate?.onboard(self, tapped: currentpage)
    }
    
    @objc
    open func didTapPageControl(_ sender: Any) {
        let pager = sender as! UIPageControl
        let page = pager.currentPage
        self.goToPage(index: page, animated: true)
    }
}
