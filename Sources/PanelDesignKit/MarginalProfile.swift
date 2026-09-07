import Foundation

/// One judge's per-category totals over a fixed set of items, validated once.
///
/// Everything a fixture can and cannot do is a function of the two judges' marginals alone.
/// The attainable range of agreement, the ceiling on every chance-corrected coefficient and
/// the set of joint tables that exist at all are all fixed before either judge has said
/// anything interesting, so the marginals are the type the rest of this package is built on.
public struct MarginalProfile: Sendable, Equatable {

    /// How many items landed in each category.
    public let counts: [Int]

    /// How many items the judge saw.
    public let itemCount: Int

    /// How many categories the judge was choosing between.
    public var categoryCount: Int { counts.count }

    /// - Throws: ``PanelDesignError/categoryCountTooSmall(_:)``,
    ///   ``PanelDesignError/negativeCount(category:count:)`` or
    ///   ``PanelDesignError/itemCountTooSmall(_:)``.
    public init(counts: [Int]) throws {
        guard counts.count >= 2 else {
            throw PanelDesignError.categoryCountTooSmall(counts.count)
        }
        for (category, count) in counts.enumerated() where count < 0 {
            throw PanelDesignError.negativeCount(category: category, count: count)
        }
        let total = counts.reduce(0, +)
        guard total >= 2 else {
            throw PanelDesignError.itemCountTooSmall(total)
        }
        self.counts = counts
        self.itemCount = total
    }

    /// Builds a profile from counts a caller has already established are valid.
    ///
    /// Used where the counts are row or column sums of an already-validated table, so the
    /// checks in ``init(counts:)`` would restate a fact rather than test one.
    init(validated counts: [Int], itemCount: Int) {
        self.counts = counts
        self.itemCount = itemCount
    }

    /// A two-category profile from a count of positives.
    ///
    /// - Throws: ``PanelDesignError/itemCountTooSmall(_:)`` or
    ///   ``PanelDesignError/negativeCount(category:count:)``.
    public static func binary(positives: Int, items: Int) throws -> MarginalProfile {
        guard items >= 2 else { throw PanelDesignError.itemCountTooSmall(items) }
        guard positives >= 0 else {
            throw PanelDesignError.negativeCount(category: 0, count: positives)
        }
        guard items - positives >= 0 else {
            throw PanelDesignError.negativeCount(category: 1, count: items - positives)
        }
        return try MarginalProfile(counts: [positives, items - positives])
    }

    /// The profile a label vector implies.
    ///
    /// - Throws: ``PanelDesignError/labelOutOfRange(judge:item:label:)`` or whatever
    ///   ``init(counts:)`` refuses.
    public static func fromLabels(_ labels: [Int], categoryCount: Int, judge: Int = 0) throws -> MarginalProfile {
        guard categoryCount >= 2 else {
            throw PanelDesignError.categoryCountTooSmall(categoryCount)
        }
        var totals = [Int](repeating: 0, count: categoryCount)
        for (item, label) in labels.enumerated() {
            guard label >= 0, label < categoryCount else {
                throw PanelDesignError.labelOutOfRange(judge: judge, item: item, label: label)
            }
            totals[label] += 1
        }
        return try MarginalProfile(counts: totals)
    }

    /// The share of items in `category`.
    public func rate(_ category: Int) -> Double {
        Double(counts[category]) / Double(itemCount)
    }

    /// `true` when every item landed in one category.
    public var isDegenerate: Bool { counts.contains(itemCount) }

    /// The category holding everything, or `nil` when the judge used more than one.
    public var degenerateCategory: Int? {
        counts.firstIndex(of: itemCount)
    }

    /// The item and category counts two profiles must share to describe the same panel.
    ///
    /// - Throws: ``PanelDesignError/itemCountMismatch(first:second:)`` or
    ///   ``PanelDesignError/categoryCountMismatch(first:second:)``.
    public static func requireComparable(_ first: MarginalProfile, _ second: MarginalProfile) throws {
        guard first.itemCount == second.itemCount else {
            throw PanelDesignError.itemCountMismatch(first: first.itemCount, second: second.itemCount)
        }
        guard first.categoryCount == second.categoryCount else {
            throw PanelDesignError.categoryCountMismatch(
                first: first.categoryCount, second: second.categoryCount
            )
        }
    }
}
