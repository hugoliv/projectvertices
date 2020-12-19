//
//  ProjectMesh.swift
//  ARKitFaceExample

import Foundation

/*
Abstract:
Project face mesh vertices on UIView.
*/

import ARKit
import SceneKit

class ProjectMesh: NSObject, VirtualContentController {
    
    var contentNode: SCNNode?
    var debugView: UIView?
    
    
    func setupDebugView(scenView: ARSCNView){
        DispatchQueue.main.async {
            let screenSize = UIScreen.main.bounds
            
            self.debugView = UIView(frame: screenSize)
            self.debugView!.backgroundColor = .clear
            
            scenView.addSubview(self.debugView!)
        }
    }
    
    /// - Tag: ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // This class adds AR content only for face anchors.
        guard let sceneView = renderer as? ARSCNView,
            anchor is ARFaceAnchor else { return nil }
        
        #if targetEnvironment(simulator)
        #error("ARKit is not supported in iOS Simulator. Connect a physical iOS device and select it as your Xcode run destination, or select Generic iOS Device as a build-only destination.")
        #else
        let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!)!
        let material = faceGeometry.firstMaterial!
        
        material.diffuse.contents = UIColor.lightGray
        material.lightingModel = .physicallyBased
        
        contentNode = SCNNode(geometry: faceGeometry)
        #endif
        
        // add a debug view on top of the scene view to write the 2d points
        if(debugView == nil){
            setupDebugView(scenView: sceneView)
        }
        
        // Provide the node to ARKit for keeping in sync with the face anchor.
        return contentNode
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceGeometry = node.geometry as? ARSCNFaceGeometry,
            let faceAnchor = anchor as? ARFaceAnchor,
            let sceneView = renderer as? ARSCNView
            else { return }
        
        faceGeometry.update(from: faceAnchor.geometry)
        
        let points:[ARFaceAnchor.VerticesAndProjection] = faceAnchor.verticeAndProjection(to: sceneView)

        DispatchQueue.main.async {
           
           // draw debug points
            let projected = points.map{ $0.projected}
            
            self.debugView?.drawCircles(points: projected)
        }
    }
}

extension ARFaceAnchor{
    
    struct VerticesAndProjection {
        var vertex: SIMD3<Float>
        var projected: CGPoint
    }
    
    func verticeAndProjection(to view: ARSCNView) -> [VerticesAndProjection]{
        
        let points = geometry.vertices.compactMap({ (vertex) -> VerticesAndProjection? in

            let col = SIMD4<Float>(SCNVector4())
            let pos = SIMD4<Float>(SCNVector4(vertex.x, vertex.y, vertex.z, 1))
            
            let pworld = transform * simd_float4x4(col, col, col, pos)
            
            let vect = view.projectPoint(SCNVector3(pworld.position.x, pworld.position.y, pworld.position.z))

            let p = CGPoint(x: CGFloat(vect.x), y: CGFloat(vect.y))
            return VerticesAndProjection(vertex:vertex, projected: p)
            })
        
        return points
    }
}


extension matrix_float4x4 {
    
    /// Get the position of the transform matrix.
    public var position: SCNVector3 {
        get{
            return SCNVector3(self[3][0], self[3][1], self[3][2])
        }
    }
    
    /// Retrieve translation from a quaternion matrix
    public var translation: SCNVector3 {
        get {
            return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
        }
    }
}


extension UIView{
    
    private struct drawCircleProperty{
        static let circleFillColor = UIColor.green
        static let circleStrokeColor = UIColor.black
        static let circleRadius: CGFloat = 3.0
    }
    
    func drawCircle(point: CGPoint) {
    
        let circlePath = UIBezierPath(arcCenter: point, radius: drawCircleProperty.circleRadius, startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = drawCircleProperty.circleFillColor.cgColor
        shapeLayer.strokeColor = drawCircleProperty.circleStrokeColor.cgColor
        
        self.layer.addSublayer(shapeLayer)
    }
    
    func drawCircles(points: [CGPoint]){
        
        self.clearLayers()
        
        for point in points{
            self.drawCircle(point: point)
        }
    }
    
    func clearLayers(){
        if let subLayers = self.layer.sublayers {
            for subLayer in subLayers {
                subLayer.removeFromSuperlayer()
            }
        }
    }
}
