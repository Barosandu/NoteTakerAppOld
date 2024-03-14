//
//  Actions.swift
//  NoteTakerApp (macOS)
//
//  Created by Alexandru Ariton on 14.05.2022.
//

import Foundation
import SwiftUI

enum NoteActionType: Int {
    case strokeAction = 1
    case other = 2
    case creation = 3
}

enum StrokeAttributes: String {
    case color = "color"
    case width = "width"
    case points = "points"
    case textValue = "textValue"
}

extension Stroke {
    subscript<SValue>(attribute att: StrokeAttributes) -> SValue? {
        get {
            if att == .color {
                return self.color as! SValue
            } else if att == .points {
                return self.points as! SValue
            } else if att == .width {
                return self.width as! SValue
            } else if att == .textValue {
                return self.textValue as! SValue
            }
            return nil
        }
        set {
            if att == .color {
                self.color = newValue as! XColor
            } else if att == .points {
                self.points = newValue as! [CGPoint]
            } else if att == .width {
                self.width = newValue as! CGFloat
            } else if att == .textValue {
                self.textValue = newValue as! String
            }
        }
    }
}

enum PrimordialType: String {
    case normal = "normal"
    case reverted = "reverted"
}



class NoteAction {
    var environment: EnvironmentObject<ScrollEnv>
    var type: NoteActionType
    var strokeID: UUID
    var str: Stroke
    var strokeProperty: StrokeAttributes?
    var previousValue: Any?
    var currentValue: Any?
    var actionDate: Date
    var primordialType: PrimordialType
    var noteOwnerID: UUID
    
    var selfId: String {
        return "\(strokeID),\(type.rawValue),\(String(describing: previousValue)),\(String(describing: currentValue)),\(self.actionDate),\(self.primordialType.rawValue)";
    }
    
    
    var weakId: String {
        return "\(strokeID),\(self.primordialType.rawValue)";
        
    }
    
    var weakIdProps: String {
        return "\(strokeID),\(self.strokeProperty?.rawValue ?? "")";
        
    }

    func weakId(forStrokeId sid: UUID, andAttribute at: StrokeAttributes) -> String {
        return "\(sid),\(at.rawValue)";
    }
    
    func `is`(like rhs: NoteAction) -> Bool {
        if self.strokeProperty == nil || rhs.strokeProperty == nil {
            return false
        }
        return self.strokeID == rhs.strokeID && self.strokeProperty!.rawValue == rhs.strokeProperty!.rawValue
    }
    
    func `is`(equalTo rhs: NoteAction) -> Bool {
        return self.selfId == rhs.selfId
    }
    
    func `is`(weakEqualTo rhs: NoteAction) -> Bool {
        return self.weakId == rhs.weakId
    }
    
    func `is`(reverseOf rhs: NoteAction) -> Bool {
        if rhs.primordialType == .reverted && self.primordialType == .normal || rhs.primordialType == .normal && self.primordialType == .reverted {
            return "\(String(describing: self.previousValue))" == "\(String(describing: rhs.currentValue))" && "\(String(describing: self.currentValue))" == "\(String(describing: rhs.previousValue))" && self.strokeID == rhs.strokeID && self.strokeProperty == rhs.strokeProperty && rhs.strokeProperty != nil
        }
        return false
    }
    
    func revert() {
        
            
        
        
        let na = self.copy()
        
        if (self.environment.wrappedValue.allActions.firstIndex(where: {$0.selfId == self.selfId}) == nil) {
            return
        }
        
        if na.primordialType == .normal {
            let r = self.environment.wrappedValue.allActions.firstIndex(where: {$0.selfId == self.selfId})!
            na.primordialType = .reverted
            na.actionDate = Date()
            let h = na.previousValue
            na.previousValue = na.currentValue
            na.currentValue = h
            self.environment.wrappedValue.allActions.insert(na, at: r)
            self.environment.wrappedValue.allActions = self.environment.wrappedValue.allActions.filter{$0.selfId != self.selfId}
        } else {
            let r = self.environment.wrappedValue.allActions.firstIndex(where: {$0.selfId == self.selfId})!
            na.primordialType = .normal
            na.actionDate = Date()
            let h = na.previousValue
            na.previousValue = na.currentValue
            na.currentValue = h
            self.environment.wrappedValue.allActions.insert(na, at: r)
            self.environment.wrappedValue.allActions = self.environment.wrappedValue.allActions.filter{$0.selfId != self.selfId}
        }
        
        if self.type == .strokeAction {
            if let strokeProperty = strokeProperty, let previousValue = previousValue, let currentValue = self.currentValue {
                
                let values = self.getValue(forStrokeId: self.strokeID)
                
                if values[strokeProperty.rawValue] != nil {
                    self.stroke[attribute: strokeProperty] = values[strokeProperty.rawValue]!
                    
                } else {
                    self.stroke[attribute: strokeProperty] = self.lastPreviousValue(property: strokeProperty)
                }
                
                
                NotificationCenter.default.post(name: .revertedAction, object: self)
            }
        } else if self.type == .creation {
            self.environment.wrappedValue.strokes = self.environment.wrappedValue.strokes.filter({$0.id != strokeID})
        }
        
    }
    
    private var stroke: Stroke {
        get {
            return self.environment.wrappedValue.strokes[withId: self.strokeID]
            
        }
        set {
            self.environment.wrappedValue.strokes[withId: self.strokeID] = newValue
        }
    }
    
    func insert() {
        if !self.environment.wrappedValue.allActions.contains(where: {$0.is(equalTo: self)}) {
            self.environment.wrappedValue.allActions.insert(self, at: 0)
        }
    }
    
    func copy() -> NoteAction {
        
        return NoteAction(env: self.environment, strokeProperty: self.strokeProperty, type: self.type, strokeID: self.strokeID, previousValue: self.previousValue, setValueTo: self.currentValue, str: self.str, primordialType: self.primordialType, noteOwnerID: self.noteOwnerID)
    }
    
    init(env: EnvironmentObject<ScrollEnv>, strokeProperty: StrokeAttributes?, type: NoteActionType, strokeID: UUID?, previousValue pv: Any? = nil, setValueTo vv: Any? = nil, str: Stroke, primordialType: PrimordialType = .normal, noteOwnerID: UUID) {
        self.environment = env
        self.type = type
        self.strokeID = strokeID ?? UUID(uuid: UUID_NULL)
        self.str = str
        self.strokeProperty = strokeProperty //! as WritableKeyPath<Stroke, Any>
        self.noteOwnerID = noteOwnerID
        self.previousValue = pv
        self.currentValue = vv
        self.actionDate = Date()
        self.primordialType = primordialType
        
        
    }
    
    
}




extension NoteAction {
    func `is`(reverseOfNil rhs: NoteAction?) -> Bool {
        if rhs == nil {
            return false
        }
        return self.is(reverseOf: rhs!)
    }
    
    func lastPreviousValue(property: StrokeAttributes) -> Any {
        let act = self.environment.wrappedValue.allActions.last(where: {$0.weakIdProps == self.weakId(forStrokeId: self.strokeID, andAttribute: property)})
        var d: [String: Any?] = [:]
        
        let p = act?.primordialType == .reverted ? act?.currentValue : act?.previousValue
        
        if property == .color {
            d[property.rawValue] = p as? XColor
        } else if property == .textValue {
            d[property.rawValue] = p as? String
        } else if property == .width {
            d[property.rawValue] = p as? CGFloat
        } else if property == .points {
            d[property.rawValue] = p as? [CGPoint]
        }
        return d[property.rawValue]
    }
    
    func getValue(forStrokeId ss: UUID) -> [String: Any?] {
        let strokeAttr: [StrokeAttributes] = [.width, .points, .textValue, .color]
        var dict: [String: Any] = [:]

        var swDict: [String: Any] = [:]

        for act in self.environment.wrappedValue.allActions.filtered().reversed() {
            
            if act.strokeID == ss {
                swDict[act.weakIdProps] = act.currentValue
            }
        }
        
        
        let c = swDict[self.weakId(forStrokeId: ss, andAttribute: .color)] as? XColor
        
        let w = swDict[self.weakId(forStrokeId: ss, andAttribute: .width)] as? CGFloat
        
        let t = swDict[self.weakId(forStrokeId: ss, andAttribute: .textValue)] as? String
        
        let p = swDict[self.weakId(forStrokeId: ss, andAttribute: .points)] as? [CGPoint]

        
        dict[StrokeAttributes.color.rawValue] = c
        dict[StrokeAttributes.width.rawValue] = w
        dict[StrokeAttributes.textValue.rawValue] = t
        dict[StrokeAttributes.points.rawValue] = p
        return dict
    }
}
