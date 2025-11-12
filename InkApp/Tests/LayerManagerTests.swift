//
//  LayerManagerTests.swift
//  InkTests
//
//  Unit tests for layer management
//  Created on November 10, 2025.
//

import XCTest
@testable import Ink

class LayerManagerTests: XCTestCase {

    var layerManager: LayerManager!

    override func setUp() {
        super.setUp()
        layerManager = LayerManager()
    }

    override func tearDown() {
        layerManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertEqual(layerManager.layerCount(), 0, "Should start with no layers")
        XCTAssertEqual(layerManager.activeLayerIndex, 0)
        XCTAssertNil(layerManager.activeLayer)
    }

    // MARK: - Add/Remove Layer Tests

    func testAddLayer() {
        // Given
        let layer = createTestLayer(name: "Test Layer")

        // When
        layerManager.addLayer(layer)

        // Then
        XCTAssertEqual(layerManager.layerCount(), 1)
        XCTAssertNotNil(layerManager.activeLayer)
    }

    func testAddMultipleLayers() {
        // When
        for i in 0..<5 {
            layerManager.addLayer(createTestLayer(name: "Layer \(i)"))
        }

        // Then
        XCTAssertEqual(layerManager.layerCount(), 5)
    }

    func testRemoveLayer() {
        // Given
        layerManager.addLayer(createTestLayer(name: "Layer 1"))
        layerManager.addLayer(createTestLayer(name: "Layer 2"))
        layerManager.addLayer(createTestLayer(name: "Layer 3"))

        // When
        layerManager.removeLayer(at: 1)

        // Then
        XCTAssertEqual(layerManager.layerCount(), 2)
    }

    func testRemoveLayerAdjustsActiveIndex() {
        // Given - 3 layers, select last one
        layerManager.addLayer(createTestLayer(name: "Layer 1"))
        layerManager.addLayer(createTestLayer(name: "Layer 2"))
        layerManager.addLayer(createTestLayer(name: "Layer 3"))
        layerManager.selectLayer(at: 2)

        // When - remove last layer
        layerManager.removeLayer(at: 2)

        // Then - active index should adjust
        XCTAssertEqual(layerManager.activeLayerIndex, 1)
    }

    // MARK: - Layer Selection Tests

    func testSelectLayer() {
        // Given
        layerManager.addLayer(createTestLayer(name: "Layer 1"))
        layerManager.addLayer(createTestLayer(name: "Layer 2"))
        layerManager.addLayer(createTestLayer(name: "Layer 3"))

        // When
        layerManager.selectLayer(at: 1)

        // Then
        XCTAssertEqual(layerManager.activeLayerIndex, 1)
        XCTAssertEqual(layerManager.activeLayer?.name, "Layer 2")
    }

    func testSelectInvalidLayerIndex() {
        // Given
        layerManager.addLayer(createTestLayer(name: "Layer 1"))

        // When - try to select out of bounds
        layerManager.selectLayer(at: 5)

        // Then - should not change
        XCTAssertEqual(layerManager.activeLayerIndex, 0)
    }

    // MARK: - Layer Visibility Tests

    func testToggleLayerVisibility() {
        // Given
        let layer = createTestLayer(name: "Test", isVisible: true)
        layerManager.addLayer(layer)

        // When
        layerManager.toggleLayerVisibility(at: 0)

        // Then
        XCTAssertFalse(layerManager.layers[0].isVisible)

        // Toggle again
        layerManager.toggleLayerVisibility(at: 0)
        XCTAssertTrue(layerManager.layers[0].isVisible)
    }

    func testGetVisibleLayers() {
        // Given
        layerManager.addLayer(createTestLayer(name: "Visible 1", isVisible: true))
        layerManager.addLayer(createTestLayer(name: "Hidden", isVisible: false))
        layerManager.addLayer(createTestLayer(name: "Visible 2", isVisible: true))

        // When
        let visibleLayers = layerManager.getVisibleLayers()

        // Then
        XCTAssertEqual(visibleLayers.count, 2)
        XCTAssertTrue(visibleLayers.allSatisfy { $0.isVisible })
    }

    // MARK: - Layer Lock Tests

    func testToggleLayerLock() {
        // Given
        let layer = createTestLayer(name: "Test", isLocked: false)
        layerManager.addLayer(layer)

        // When
        layerManager.toggleLayerLock(at: 0)

        // Then
        XCTAssertTrue(layerManager.layers[0].isLocked)

        // Toggle again
        layerManager.toggleLayerLock(at: 0)
        XCTAssertFalse(layerManager.layers[0].isLocked)
    }

    func testIsActiveLayerLocked() {
        // Given - unlocked layer
        layerManager.addLayer(createTestLayer(name: "Unlocked", isLocked: false))
        layerManager.selectLayer(at: 0)

        // Then
        XCTAssertFalse(layerManager.isActiveLayerLocked())

        // When - lock it
        layerManager.toggleLayerLock(at: 0)

        // Then
        XCTAssertTrue(layerManager.isActiveLayerLocked())
    }

    // MARK: - Layer Opacity Tests

    func testSetLayerOpacity() {
        // Given
        layerManager.addLayer(createTestLayer(name: "Test"))

        // When
        layerManager.setLayerOpacity(0.5, at: 0)

        // Then
        XCTAssertEqual(layerManager.layers[0].opacity, 0.5)
    }

    func testSetLayerOpacityClamps() {
        // Given
        layerManager.addLayer(createTestLayer(name: "Test"))

        // When - try to set invalid values
        layerManager.setLayerOpacity(-0.5, at: 0)
        XCTAssertEqual(layerManager.layers[0].opacity, 0.0, "Should clamp to 0")

        layerManager.setLayerOpacity(1.5, at: 0)
        XCTAssertEqual(layerManager.layers[0].opacity, 1.0, "Should clamp to 1")
    }

    // MARK: - Layer Blend Mode Tests

    func testSetLayerBlendMode() {
        // Given
        layerManager.addLayer(createTestLayer(name: "Test"))

        // When
        layerManager.setLayerBlendMode(.multiply, at: 0)

        // Then
        XCTAssertEqual(layerManager.layers[0].blendMode, .multiply)
    }

    // MARK: - Layer Move Tests

    func testMoveLayer() {
        // Given
        layerManager.addLayer(createTestLayer(name: "Layer 0"))
        layerManager.addLayer(createTestLayer(name: "Layer 1"))
        layerManager.addLayer(createTestLayer(name: "Layer 2"))

        // When - move Layer 0 to position 2
        layerManager.moveLayer(from: 0, to: 2)

        // Then
        XCTAssertEqual(layerManager.layers[2].name, "Layer 0")
        XCTAssertEqual(layerManager.layers[0].name, "Layer 1")
        XCTAssertEqual(layerManager.layers[1].name, "Layer 2")
    }

    func testMoveLayerUpdatesActiveIndex() {
        // Given - select layer 0
        layerManager.addLayer(createTestLayer(name: "Layer 0"))
        layerManager.addLayer(createTestLayer(name: "Layer 1"))
        layerManager.addLayer(createTestLayer(name: "Layer 2"))
        layerManager.selectLayer(at: 0)

        // When - move active layer to position 2
        layerManager.moveLayer(from: 0, to: 2)

        // Then - active index should follow
        XCTAssertEqual(layerManager.activeLayerIndex, 2)
    }

    // MARK: - Clear Tests

    func testClearAllLayers() {
        // Given
        layerManager.addLayer(createTestLayer(name: "Layer 1"))
        layerManager.addLayer(createTestLayer(name: "Layer 2"))
        layerManager.selectLayer(at: 1)

        // When
        layerManager.clearAllLayers()

        // Then
        XCTAssertEqual(layerManager.layerCount(), 0)
        XCTAssertEqual(layerManager.activeLayerIndex, 0)
    }

    // MARK: - Load Layers Tests

    func testLoadLayers() {
        // Given - existing layers
        layerManager.addLayer(createTestLayer(name: "Old 1"))
        layerManager.addLayer(createTestLayer(name: "Old 2"))

        // When - load new layers
        let newLayers = [
            createTestLayer(name: "New 1"),
            createTestLayer(name: "New 2"),
            createTestLayer(name: "New 3"),
        ]
        layerManager.loadLayers(newLayers)

        // Then
        XCTAssertEqual(layerManager.layerCount(), 3)
        XCTAssertEqual(layerManager.layers[0].name, "New 1")
        XCTAssertEqual(layerManager.activeLayerIndex, 0)
    }

    // MARK: - Helper Methods

    private func createTestLayer(
        name: String,
        isVisible: Bool = true,
        isLocked: Bool = false
    ) -> Layer {
        return Layer(
            name: name,
            opacity: 1.0,
            blendMode: .normal,
            isVisible: isVisible,
            isLocked: isLocked
        )
    }
}
