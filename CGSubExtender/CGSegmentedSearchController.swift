//
//  CGSegmentedSearchController.swift
//  CGSubExtender
//
//  Created by Chase Gorectke on 12/29/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

import UIKit

public class CGSegmentedSearchController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    public var selectedIndex: Int = 0
    public var segmentedControl: UISegmentedControl?
    var segmentedBackgroundBar: UIToolbar!
    
    public var searchController: UISearchController?
    public var searchTableController: UITableViewController?
    public var tableView: UITableView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
//        UIDevice.currentDevice().generatesDeviceOrientationNotifications
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadLayout", name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        self.view.addSubview(tableView)
        
        if let sTableController = searchTableController {
            sTableController.tableView.delegate = self
            searchController = UISearchController(searchResultsController: sTableController)
            
            if let sControl = searchController {
                sControl.searchResultsUpdater = self
                sControl.searchBar.sizeToFit()
                tableView.tableHeaderView = sControl.searchBar
                
                sControl.delegate = self
                sControl.hidesNavigationBarDuringPresentation = false
                sControl.dimsBackgroundDuringPresentation = false
                sControl.searchBar.delegate = self
                
                // Search is now just presenting a view controller. As such, normal view controller
                // presentation semantics apply. Namely that presentation will walk up the view controller
                // hierarchy until it finds the root view controller or one that defines a presentation context.
                definesPresentationContext = true
            }
        }
        
        // Set up segmented control... Add constraints
        if let sControl = segmentedControl {
            segmentedBackgroundBar = UIToolbar()
            segmentedBackgroundBar.setTranslatesAutoresizingMaskIntoConstraints(false)
            sControl.addTarget(self, action: "selectedSegment:", forControlEvents: .ValueChanged)
            sControl.setTranslatesAutoresizingMaskIntoConstraints(false)
            
            self.view.addSubview(segmentedBackgroundBar)
            self.view.addSubview(sControl)
        }
        
        self.loadLayout()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let tabBarController = self.tabBarController { tabBarController.tabBar.hidden = false }
        if let navController = self.navigationController {
            let imgTemp = self.findHairlineImageViewWithinView(navController.navigationBar)
            if let img = imgTemp { img.hidden = true }
        }
        if let sControl = segmentedControl {
            sControl.selectedSegmentIndex = selectedIndex
            if let candSuper = sControl.superview {
                if let topSuper = candSuper.superview {
                    topSuper.bringSubviewToFront(candSuper)
                }
            }
        }
    }
    
    public override func viewWillDisappear(animated: Bool) {
        if let navController = self.navigationController {
            let imgTemp = self.findHairlineImageViewWithinView(navController.navigationBar)
            if let img = imgTemp { img.hidden = true }
        }
        super.viewWillDisappear(animated)
    }
    
    public func findHairlineImageViewWithinView(view: UIView) -> UIImageView? {
        if view.isKindOfClass(UIImageView) && view.bounds.size.height <= 1.0 { return view as? UIImageView }
        for subview in view.subviews {
            let imageTemp = self.findHairlineImageViewWithinView(subview as UIView)
            if let imageView = imageTemp { return imageView }
        }
        return nil
    }
    
    func loadLayout() {
        self.view.removeConstraints(self.view.constraints())
        
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[tableView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "tableView" : tableView ]))
        
        // Set up segmented control... Add constraints
        if let sControl = segmentedControl {
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[segmentedBackgroundBar]|", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "segmentedBackgroundBar" : segmentedBackgroundBar ]))
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(10.0)-[segmentedControl]-(10.0)-|", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "segmentedControl" : sControl ]))
            
            var heightOffset: CGFloat = 0.0
            if let navController = self.navigationController {
                heightOffset = navController.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
            }
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(\(heightOffset))-[segmentedBackgroundBar(44.0)]-(-\(heightOffset))-[tableView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "segmentedBackgroundBar" : segmentedBackgroundBar, "tableView" : tableView ]))
            
            sControl.addConstraint(NSLayoutConstraint(item: sControl, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 29.0))
            self.view.addConstraint(NSLayoutConstraint(item: sControl, attribute: .CenterX, relatedBy: .Equal, toItem: segmentedBackgroundBar, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
            self.view.addConstraint(NSLayoutConstraint(item: sControl, attribute: .CenterY, relatedBy: .Equal, toItem: segmentedBackgroundBar, attribute: .CenterY, multiplier: 1.0, constant: 0.0))
        } else {
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[tableView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "tableView" : tableView ]))
        }
        
        self.view.layoutSubviews()
//        self.view.layoutIfNeeded()
    }
    
    func selectedSegment(sender: AnyObject?) {
        if let sController = segmentedControl { selectedIndex = sController.selectedSegmentIndex }
        tableView.reloadData()
    }
    
    // MARK: UISearchBarDelegate
    
    public func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: UISearchControllerDelegate
    
    public func presentSearchController(searchController: UISearchController) {
        //NSLog(__FUNCTION__)
    }
    
    public func willPresentSearchController(searchController: UISearchController) {
        //NSLog(__FUNCTION__)
    }
    
    public func didPresentSearchController(searchController: UISearchController) {
        //NSLog(__FUNCTION__)
    }
    
    public func willDismissSearchController(searchController: UISearchController) {
        //NSLog(__FUNCTION__)
    }
    
    public func didDismissSearchController(searchController: UISearchController) {
        //NSLog(__FUNCTION__)
    }
    
    // MARK: UISearchResultsUpdating
    
    public func updateSearchResultsForSearchController(searchController: UISearchController) { }
    
    // MARK: UITableViewDataSource
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 0 }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 0 }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell { return UITableViewCell() }
    
}
