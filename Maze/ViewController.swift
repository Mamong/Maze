//
//  ViewController.swift
//  Maze
//
//  Created by marco on 2020/6/26.
//  Copyright © 2020 flywire. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //configurable
    var rowNum = 10
    var colNum = 10
    
    //1-left 2-bottom 3-right 4-top
    var entrance = 2
    var exit = 1
    
    var canvasWidth = 320
    var canvasHeight = 320
    var margin = 10
    
    
    // private
    private var length = 10
    private var vertices = 100
    private var dimension = [Int]()

    private var direction:MoveDirection = .up
    private var currentPoint = CGPoint.zero
    private var path = CGMutablePath()
    
    private var graph:[[Int]] = []
    private var inList:[Int] = []
    private var frontierList:[Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //config
        readConfig()
        
        //init graph matrix
        initGraph()
        
        //generate maze connection data
        generateMaze()
        
        //draw maze
        drawMaze()
    }
    
    // Step 1: read user's input
    func readConfig(){
        
        //do some config
        rowNum = 10
        colNum = 10
        
        entrance = 2
        exit = 1
        
        canvasWidth = 320
        canvasHeight = 320
        margin = 10
        
        //generated
        dimension = [rowNum,colNum]
        length = min((canvasWidth-2*margin)/rowNum, (canvasHeight-2*margin)/colNum)
        vertices = rowNum * colNum
    }
    
    /*
    # Step 2: initialize the adjacency matrix (of size vertices x vertices)
    # index the cell in the following manner:
    # 0 3 6 9 12
    # 1 4 7 10 13
    # 2 5 8 11 14 ...
    # then each row of the graph represents the relationship between the i-th cell and other cells
    # 0 - not a neighbor; 1 - unconnected neighbor; 2 - connected neighbor
    */
    func initGraph(){
        //generate a vertices*vertices and zero initialized array
        for _ in 0..<vertices {
            let v = Array.init(repeating: 0, count: vertices)
            graph.append(v)
        }
        
        //mark all the neighbors; initially all neighbors are unconnected (separated by a line segment)
        //any cell(except boundary cells) has 4 neighbors,so just find them out and mark the relationship to 1
        for i in 0..<vertices {
            if i % rowNum >= 1 {
                //upper neighbor
                graph[i][i-1] = 1
            }
            if i % rowNum < rowNum - 1 {
                //lower neighbor
                graph[i][i+1] = 1
            }
            if i / rowNum >= 1 {
                //left neighbor
                graph[i][i-rowNum] = 1
            }
            if i / rowNum < colNum - 1 {
                //right neighbor
                graph[i][i+rowNum] = 1
            }
        }
    }
    
    /*
     # Step 3: Prim's algorithm (modified) starting from the upper left cell
     # the 'in' list contains all cells already carved into the maze;
     # the 'frontier' list contains cells not in the maze yet, but are next to a cell that's already 'in'
     */
    func generateMaze(){
        //initialize the two lists (start the algorithm from the center of the maze to ensure symmetry)
        locateStartingCell()
        //stop when all of the cells are connected (carved into the maze)
        while inList.count < vertices {
            let count = UInt32(frontierList.count)
            let randomIndex = Int(arc4random() % count)
            //randomly pick a cell from the 'frontier list' to add to the maze
            let cell = frontierList[randomIndex]
            frontierList.remove(at: randomIndex)
            //add this cell to the 'in' list
            inList.append(cell)
            //carve it into the maze and add the new neighbors to the 'frontier' list
            carveIntoMazeAndAddNeighbors(cell)
        }
    }
    
    //calculate the index of the starting cell and its neighbors
    //starting cell is in the center of the maze
    func locateStartingCell(){
        let startX = colNum / 2
        let startY = rowNum / 2
        //expand the maze from the center
        let startIndex = startX * rowNum + startY
        
        //add the neighbors of the central cell to the 'frontier' list
        inList.append(startIndex)
        for i in 0..<vertices {
            if graph[startIndex][i] == 1 {
                frontierList.append(i)
            }
        }
    }
    
    /*
     when each new cell is added to the maze, randomly connect it with a neighbor already in the maze,
     and at the same time add the remaining neighbors to the 'frontier' list
     */
    func carveIntoMazeAndAddNeighbors(_ cell: Int){
        //the list of neighbors that are already in the maze
        var tempList = [Int]()
        for i in 0..<vertices {
            if graph[cell][i] == 1 {
                if inList.contains(i) {
                    //pick up cell's neighbors those are already in maze
                    tempList.append(i)
                }else if !frontierList.contains(i){
                    //when add a cell in maze,the cell's neighbors should be added to
                    //frontierList,do not duplicate
                    frontierList.append(i)
                }
            }
        }
        //randomly pick one neighbor and connect to the cell,that means
        //we just clear the segment between them.
        let count = UInt32(tempList.count)
        let randomIndex = Int(arc4random() % count)
        let selectedNeighbor = tempList[randomIndex]
        graph[cell][selectedNeighbor] = 2
        graph[selectedNeighbor][cell] = 2
    }
    
    //draw a boundary with an entrance
    func drawBoundaryWithEntrance(_ i:Int){
        
        //draw half of the boundary
        forward(CGFloat(dimension[i]/2 * length))
        
        //draw the entrance,just skip it
        move(CGFloat(length))
        
        //draw the other half of the boundary
        forward(CGFloat((dimension[i]-1)/2 * length))
    }
    
    //add line along the last direction
    func forward(_ distance:CGFloat) {
        currentPoint = currentPoint.pointForward(distance: distance,direction:direction)
        path.addLine(to:currentPoint)
    }
    
    //skip some distance along the last direction
    func move(_ distance:CGFloat) {
        currentPoint = currentPoint.pointForward(distance: distance,direction:direction)
        path.move(to: currentPoint)
    }
    
    //move to some point
    func goto(_ point:CGPoint) {
        currentPoint = point
        path.move(to: currentPoint)
    }
    
    //Step 4: draw entire maze
    func drawMaze() {
        
        UIGraphicsBeginImageContextWithOptions(CGSize.init(width: canvasWidth, height: canvasHeight), false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        ctx.setLineWidth(1)
        ctx.setStrokeColor(UIColor.black.cgColor)
        
        //draw 4 boundaries
        goto(CGPoint.init(x: margin, y: margin))
        
        //face down
        direction = .down
        for i in 0...3{
            if i != entrance-1 && i != exit - 1 {
                forward(CGFloat(dimension[i%2] * length))
                //draw boundary without entrance/exit, boundary length = (number of cells) x (length per cell)
            }else{
                drawBoundaryWithEntrance(i%2)
                //draw boundary with entrance/exit, boundary length = (number of cells) x (length per cell)
            }
            //turn left, anti-clockwise, that means:
            //   |4<------|3^
            //   |        |
            // 1V|------>2|
            direction = MoveDirection(rawValue: (direction.rawValue + 1) % 4)!
        }
        
        //draw inner lines
        //print all the vertical lines from left to right and top to bottom
        //now direction == .down
        for i in 0..<vertices-rowNum{
            //right neighbor
            if graph[i][i+rowNum] == 1 {
                let point = CGPoint.init(x: margin + length + Int(i / rowNum) * length, y: margin + (i % rowNum) * length)
                //locate the upper endpoint
                goto(point)
                //draw the line segment from top to bottom
                forward(CGFloat(length))
            }
        }
        
        //print all the horizontal lines from left to right and top to bottom
        direction = .right
        for i in 0..<vertices-1{
            //lower neighbor
            if graph[i][i+1] == 1 {
                let point = CGPoint.init(x: margin + Int(i / rowNum) * length, y: margin + length + (i % rowNum) * length)
                //locate the left endpoint
                goto(point)
                //draw the line segment from left to right
                forward(CGFloat(length))
            }
        }
        
        ctx.addPath(path)
        ctx.drawPath(using: .stroke)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 100, width: canvasWidth, height:canvasHeight))
        imageView.image = image
        view.addSubview(imageView)
    }
}

//anti-clockwise
enum MoveDirection:Int{
    case up, left, down, right
}

extension CGPoint {
    
    func pointForward(distance:CGFloat, direction:MoveDirection) -> CGPoint{
        switch direction{
        case .up:
            return CGPoint.init(x: x, y: y - distance)
        case .left:
            return CGPoint.init(x: x - distance, y: y)
        case .down:
            return CGPoint.init(x: x, y: y + distance)
        case .right:
            return CGPoint.init(x: x + distance, y: y)
        }
    }
}
