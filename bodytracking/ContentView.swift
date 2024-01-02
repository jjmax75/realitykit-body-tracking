//
//  ContentView.swift
//  bodytracking
//
//  Created by John Behan on 02/01/2024.
//
// https://www.youtube.com/watch?v=f86K8h-8C9A

import SwiftUI
import RealityKit
import ARKit

struct ContentView : View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

class BodySkeleton: Entity {
    var joints: [String: Entity] = [:] //jointNames mapped to jointEntities
    
    required init(for bodyAnchor: ARBodyAnchor) {
        super.init()
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            var jointRadius: Float = 0.03
            var jointColor: UIColor = .green
            
            
            
            let jointEntity = makeJoint(radius: jointRadius, color: jointColor)
            joints[jointName] = jointEntity
            self.addChild(jointEntity)
        }
        
        self.update(with: bodyAnchor)
    }
    
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
    
    func makeJoint(radius: Float, color: UIColor) -> Entity {
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: color, roughness: 0.8, isMetallic: false)
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        
        return modelEntity
    }
    
    func update(with bodyAnchor: ARBodyAnchor) {
        let rrootPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            if let jointEntity = joints[jointName], let jointTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName)) {
                let jointOffset = simd_make_float3(jointTransform.columns.3)
                jointEntity.position = rrootPosition + jointOffset
                jointEntity.orientation = Transform(matrix: jointTransform).rotation
            }
        }
        
    }
}

var bodySkeleton: BodySkeleton?
var bodySkeletonAnchor = AnchorEntity()

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        
        arView.setupForBodyTracking()
        
        arView.scene.addAnchor(bodySkeletonAnchor)
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

extension ARView: ARSessionDelegate {
    func setupForBodyTracking() {
        let config = ARBodyTrackingConfiguration()
        self.session.run(config)
        
        self.session.delegate = self
    }
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
//                print("DEBUG: updated body anchor")
//                
//                let skeleton = bodyAnchor.skeleton
//                
//                let rootJointTransform = skeleton.modelTransform(for: .root)!
//                let rootJointPosition = simd_make_float3(rootJointTransform.columns.3)
//                print("DEBUG: root: \(rootJointPosition)")
//                
//                let leftHandTransform = skeleton.modelTransform(for: .leftHand)!
//                let leftHandOffset = simd_make_float3(leftHandTransform.columns.3)
//                let leftHandPosition = rootJointPosition + leftHandOffset
//                print("DEBUG: left hand: \(leftHandPosition)")
                if let skeleton = bodySkeleton {
                    // bodySkeleton already exists, update pose for each joint
                    skeleton.update(with: bodyAnchor)
                } else {
                    // seeing body for the first time, create bodySkeleton
                    let skeleton = BodySkeleton(for: bodyAnchor)
                    bodySkeleton = skeleton
                    bodySkeletonAnchor.addChild(skeleton)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
