//
//  UndoManager.swift
//  Ink - Pattern Drawing App
//
//  Simple undo/redo system for drawing operations
//  Created on November 10, 2025.
//

import Foundation
import Metal

/// Represents a drawing command that can be undone/redone
enum DrawingCommand {
    case drawStroke(Stroke, layerId: UUID)
    case clearLayer(layerId: UUID, previousTexture: Data?)
    // Future: eraseStroke, transformLayer, etc.
}

class DrawingUndoManager {

    // MARK: - Properties

    private var undoStack: [DrawingCommand] = []
    private var redoStack: [DrawingCommand] = []

    private let maxUndoLevels: Int

    // Callbacks
    var onUndoStackChanged: ((Bool, Bool) -> Void)? // (canUndo, canRedo)

    // MARK: - Initialization

    init(maxUndoLevels: Int = 50) {
        self.maxUndoLevels = maxUndoLevels
    }

    // MARK: - Recording Commands

    /// Record a stroke drawing command
    func recordStroke(_ stroke: Stroke) {
        let command = DrawingCommand.drawStroke(stroke, layerId: stroke.layerId)
        pushCommand(command)
    }

    /// Record a layer clear command
    func recordLayerClear(layerId: UUID, previousTexture: Data? = nil) {
        let command = DrawingCommand.clearLayer(layerId: layerId, previousTexture: previousTexture)
        pushCommand(command)
    }

    private func pushCommand(_ command: DrawingCommand) {
        undoStack.append(command)

        // Limit undo stack size
        if undoStack.count > maxUndoLevels {
            undoStack.removeFirst()
        }

        // Clear redo stack when new command is added
        redoStack.removeAll()

        notifyStackChanged()
    }

    // MARK: - Undo/Redo

    /// Undo last command
    func undo() -> DrawingCommand? {
        guard !undoStack.isEmpty else { return nil }

        let command = undoStack.removeLast()
        redoStack.append(command)

        notifyStackChanged()

        return command
    }

    /// Redo last undone command
    func redo() -> DrawingCommand? {
        guard !redoStack.isEmpty else { return nil }

        let command = redoStack.removeLast()
        undoStack.append(command)

        notifyStackChanged()

        return command
    }

    // MARK: - Query

    /// Check if undo is available
    func canUndo() -> Bool {
        return !undoStack.isEmpty
    }

    /// Check if redo is available
    func canRedo() -> Bool {
        return !redoStack.isEmpty
    }

    /// Get number of undo levels
    func undoCount() -> Int {
        return undoStack.count
    }

    /// Get number of redo levels
    func redoCount() -> Int {
        return redoStack.count
    }

    // MARK: - Clear

    /// Clear all undo/redo history
    func clearAll() {
        undoStack.removeAll()
        redoStack.removeAll()
        notifyStackChanged()
    }

    /// Clear redo stack only
    func clearRedoStack() {
        redoStack.removeAll()
        notifyStackChanged()
    }

    // MARK: - Notifications

    private func notifyStackChanged() {
        onUndoStackChanged?(canUndo(), canRedo())
    }

    // MARK: - Debug

    func printStack() {
        print("=== Undo Stack ===")
        print("Undo: \(undoStack.count) commands")
        print("Redo: \(redoStack.count) commands")
        print("Can undo: \(canUndo())")
        print("Can redo: \(canRedo())")
    }
}
