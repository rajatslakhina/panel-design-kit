import Foundation

/// A square table of joint counts for two judges, with the readings taken off it.
///
/// The table is the fixture. Two marginals and one table is everything a pairwise coefficient
/// sees, so the diagnostics a design needs — how far the counts sit from independence, what
/// the odds ratio is, whether the panel can carry association at all — belong here rather than
/// in whatever is measuring it this week.
public struct JointTable: Sendable, Equatable {

    /// Counts indexed `[firstJudgeLabel][secondJudgeLabel]`.
    public let cells: [[Int]]

    /// How many items the table describes.
    public let itemCount: Int

    /// How many categories the judges were choosing between.
    public var categoryCount: Int { cells.count }

    /// - Throws: ``PanelDesignError/categoryCountTooSmall(_:)``,
    ///   ``PanelDesignError/tableNotSquare(rows:columns:)``,
    ///   ``PanelDesignError/negativeCount(category:count:)`` or
    ///   ``PanelDesignError/itemCountTooSmall(_:)``.
    public init(cells: [[Int]]) throws {
        guard cells.count >= 2 else {
            throw PanelDesignError.categoryCountTooSmall(cells.count)
        }
        for row in cells where row.count != cells.count {
            throw PanelDesignError.tableNotSquare(rows: cells.count, columns: row.count)
        }
        for (index, row) in cells.enumerated() {
            for count in row where count < 0 {
                throw PanelDesignError.negativeCount(category: index, count: count)
            }
        }
        let total = cells.reduce(0) { $0 + $1.reduce(0, +) }
        guard total >= 2 else {
            throw PanelDesignError.itemCountTooSmall(total)
        }
        self.cells = cells
        self.itemCount = total
    }

    /// The first judge's marginal.
    public var rowMargin: MarginalProfile {
        MarginalProfile(validated: cells.map { $0.reduce(0, +) }, itemCount: itemCount)
    }

    /// The second judge's marginal.
    public var columnMargin: MarginalProfile {
        let columns = (0..<categoryCount).map { column in
            cells.reduce(0) { $0 + $1[column] }
        }
        return MarginalProfile(validated: columns, itemCount: itemCount)
    }

    /// How many items the two judges labelled identically.
    public var diagonalTotal: Int {
        (0..<categoryCount).reduce(0) { $0 + cells[$1][$1] }
    }

    /// The raw agreement rate.
    public var agreementRate: Double {
        Double(diagonalTotal) / Double(itemCount)
    }

    /// The count independence predicts for cell `(row, column)`.
    public func expectedCount(row: Int, column: Int) -> Double {
        Double(rowMargin.counts[row]) * Double(columnMargin.counts[column]) / Double(itemCount)
    }

    /// The largest gap between an observed count and the count independence predicts.
    ///
    /// Exactly zero means the two judges are independent as a matter of arithmetic rather than
    /// of estimation, which is the property a fully crossed fixture has and the reason it can
    /// carry no association for anything to measure.
    public var maximumIndependenceDeviation: Double {
        var largest = 0.0
        for row in 0..<categoryCount {
            for column in 0..<categoryCount {
                let gap = abs(Double(cells[row][column]) - expectedCount(row: row, column: column))
                largest = max(largest, gap)
            }
        }
        return largest
    }

    /// `true` when every cell is exactly its independence prediction.
    public var isExactlyIndependent: Bool { maximumIndependenceDeviation == 0 }

    /// Cohen's chance term for this table.
    public var expectedAgreement: Double {
        let items = Double(itemCount)
        return zip(rowMargin.counts, columnMargin.counts)
            .reduce(0.0) { $0 + Double($1.0) * Double($1.1) } / (items * items)
    }

    /// Cohen's kappa, or `nil` when the chance term is one and the coefficient has no denominator.
    public var cohenKappa: Double? {
        let expected = expectedAgreement
        guard expected < 1 else { return nil }
        return (agreementRate - expected) / (1 - expected)
    }

    /// The odds ratio of a two-by-two table.
    ///
    /// - Throws: ``PanelDesignError/oddsRatioRequiresBinary(categoryCount:)`` above two
    ///   categories, and ``PanelDesignError/oddsRatioUndefined(row:column:)`` when a cell is
    ///   empty. An empty cell is not an infinite association, it is an association the table
    ///   has no information about, and the two read very differently on a page.
    public func oddsRatio() throws -> Double {
        guard categoryCount == 2 else {
            throw PanelDesignError.oddsRatioRequiresBinary(categoryCount: categoryCount)
        }
        for row in 0..<2 {
            for column in 0..<2 where cells[row][column] == 0 {
                throw PanelDesignError.oddsRatioUndefined(row: row, column: column)
            }
        }
        return Double(cells[0][0] * cells[1][1]) / Double(cells[0][1] * cells[1][0])
    }

    /// The table attaining the largest agreement these two marginals allow.
    ///
    /// Constructive rather than asserted: the diagonal takes `min(a_k, b_k)` in every category,
    /// which leaves each category with a surplus on at most one of its two sides, so the
    /// leftovers route between rows and columns that never share an index and the diagonal is
    /// never added to. That the result has the right margins is what makes
    /// ``AttainableAgreement/upperCount`` a reachable figure rather than a bound.
    ///
    /// - Throws: whatever ``MarginalProfile/requireComparable(_:_:)`` refuses.
    public static func maximumDiagonal(
        first: MarginalProfile, second: MarginalProfile
    ) throws -> JointTable {
        try MarginalProfile.requireComparable(first, second)
        let size = first.categoryCount
        var cells = [[Int]](repeating: [Int](repeating: 0, count: size), count: size)
        var rowSurplus = [Int](repeating: 0, count: size)
        var columnSurplus = [Int](repeating: 0, count: size)
        for index in 0..<size {
            let shared = min(first.counts[index], second.counts[index])
            cells[index][index] = shared
            rowSurplus[index] = first.counts[index] - shared
            columnSurplus[index] = second.counts[index] - shared
        }
        var column = 0
        for row in 0..<size where rowSurplus[row] > 0 {
            while rowSurplus[row] > 0 {
                while columnSurplus[column] == 0 { column += 1 }
                let moved = min(rowSurplus[row], columnSurplus[column])
                cells[row][column] += moved
                rowSurplus[row] -= moved
                columnSurplus[column] -= moved
            }
        }
        return try JointTable(cells: cells)
    }
}
