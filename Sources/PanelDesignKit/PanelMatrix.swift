import Foundation

/// A whole panel: every judge's labels over the same items, validated once.
public struct PanelMatrix: Sendable, Equatable {

    /// Labels indexed `[judge][item]`.
    public let labels: [[Int]]

    /// How many categories the judges were choosing between.
    public let categoryCount: Int

    /// - Throws: ``PanelDesignError/judgeCountTooSmall(_:)``,
    ///   ``PanelDesignError/categoryCountTooSmall(_:)``,
    ///   ``PanelDesignError/itemCountTooSmall(_:)``,
    ///   ``PanelDesignError/itemCountMismatch(first:second:)`` or
    ///   ``PanelDesignError/labelOutOfRange(judge:item:label:)``.
    public init(labels: [[Int]], categoryCount: Int) throws {
        guard labels.count >= 2 else {
            throw PanelDesignError.judgeCountTooSmall(labels.count)
        }
        guard categoryCount >= 2 else {
            throw PanelDesignError.categoryCountTooSmall(categoryCount)
        }
        let items = labels[0].count
        guard items >= 2 else {
            throw PanelDesignError.itemCountTooSmall(items)
        }
        for row in labels where row.count != items {
            throw PanelDesignError.itemCountMismatch(first: items, second: row.count)
        }
        for (judge, row) in labels.enumerated() {
            for (item, label) in row.enumerated() where label < 0 || label >= categoryCount {
                throw PanelDesignError.labelOutOfRange(judge: judge, item: item, label: label)
            }
        }
        self.labels = labels
        self.categoryCount = categoryCount
    }

    /// How many judges the panel has.
    public var judgeCount: Int { labels.count }

    /// How many items every judge saw.
    public var itemCount: Int { labels[0].count }

    /// One judge's marginal.
    ///
    /// - Throws: ``PanelDesignError/judgeOutOfRange(_:)``.
    public func margin(_ judge: Int) throws -> MarginalProfile {
        try requireJudge(judge)
        return try MarginalProfile.fromLabels(labels[judge], categoryCount: categoryCount, judge: judge)
    }

    /// The joint table for one pair of judges.
    ///
    /// - Throws: ``PanelDesignError/judgeOutOfRange(_:)`` or
    ///   ``PanelDesignError/judgePairNotDistinct(_:)``.
    public func table(_ first: Int, _ second: Int) throws -> JointTable {
        try requireJudge(first)
        try requireJudge(second)
        guard first != second else {
            throw PanelDesignError.judgePairNotDistinct(first)
        }
        var cells = [[Int]](
            repeating: [Int](repeating: 0, count: categoryCount), count: categoryCount
        )
        for (row, column) in zip(labels[first], labels[second]) { cells[row][column] += 1 }
        return try JointTable(cells: cells)
    }

    private func requireJudge(_ judge: Int) throws {
        guard judge >= 0, judge < judgeCount else {
            throw PanelDesignError.judgeOutOfRange(judge)
        }
    }
}
