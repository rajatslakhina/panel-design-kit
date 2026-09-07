import Foundation

/// A joint table turned back into the two label vectors a judge pipeline consumes.
///
/// The table is the design; this is the fixture. Downstream packages in this series take label
/// vectors, not contingency tables, so a design that cannot be realised as items is a design that
/// cannot be handed to the thing it was built for.
public struct PanelRealization: Sendable, Equatable {

    /// The first judge's label per item.
    public let first: [Int]

    /// The second judge's label per item.
    public let second: [Int]

    /// How many categories the two judges were choosing between.
    public let categoryCount: Int

    /// Expands `table` into items and shuffles them deterministically from `seed`.
    ///
    /// The shuffle matters for anything downstream that resamples by position or splits the panel
    /// in half; the counts are the same either way, but a panel laid out cell by cell has all its
    /// agreements at the front.
    public init(table: JointTable, seed: UInt64) {
        var items: [(Int, Int)] = []
        items.reserveCapacity(table.itemCount)
        for row in 0..<table.categoryCount {
            for column in 0..<table.categoryCount {
                items.append(contentsOf: repeatElement((row, column), count: table.cells[row][column]))
            }
        }
        var generator = SeededGenerator(seed: seed)
        items.shuffle(using: &generator)
        self.first = items.map(\.0)
        self.second = items.map(\.1)
        self.categoryCount = table.categoryCount
    }

    /// How many items the panel has.
    public var itemCount: Int { first.count }

    /// The panel as a two-judge matrix, ready to diagnose.
    ///
    /// - Throws: whatever ``PanelMatrix/init(labels:categoryCount:)`` refuses.
    public func matrix() throws -> PanelMatrix {
        try PanelMatrix(labels: [first, second], categoryCount: categoryCount)
    }
}
