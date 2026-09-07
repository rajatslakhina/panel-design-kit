import Foundation

/// What agreement rates two marginals can and cannot produce, before either judge speaks.
///
/// A fixture is usually specified by the rate the judges are meant to agree at, and the two
/// marginals decide which rates exist. They decide it twice over. The **range** is bounded on
/// both sides — the familiar ceiling `sum min(a_k, b_k) / n`, and a floor that is not zero
/// whenever one category is common enough that the two judges are forced to collide in it.
/// Inside that range the attainable counts are **not every integer**, and on a two-category
/// panel they are not even close: the single free cell of a two-by-two table with fixed margins
/// moves both diagonal cells together, so the agreement count moves in steps of two.
///
/// Above two categories there is no single step. Exhaustive enumeration over five items and
/// three categories finds identical margins `[1, 2, 2]` whose attainable counts are
/// `{0, 1, 2, 3, 5}` — contiguous, and then a hole immediately below the maximum. This type
/// reports the range, reports the step where one exists, and returns `nil` rather than guessing
/// where one does not.
public struct AttainableAgreement: Sendable, Equatable {

    /// The smallest number of items the two judges can agree on.
    public let lowerCount: Int

    /// The largest number of items they can agree on.
    public let upperCount: Int

    /// The spacing of attainable counts, or `nil` when no single spacing describes them.
    ///
    /// `2` for two categories, exactly. `nil` above two, because the attainable set can have
    /// holes in it and a step of one would claim counts that no table produces.
    public let step: Int?

    /// `true` when the two judges used every category equally often.
    ///
    /// Worth its own field because of what it forbids. If the margins match, the two label
    /// vectors are the same multiset, so a single disagreement cannot exist on its own — the
    /// item that moved out of a category leaves it one short and some other item has to move
    /// in. **An agreement count of `n - 1` is unattainable for identical margins at every
    /// category count**, which is the general form of the two-category step.
    public let marginsAreIdentical: Bool

    /// How many items the panel has.
    public let itemCount: Int

    /// How many categories the judges were choosing between.
    public let categoryCount: Int

    /// - Throws: whatever ``MarginalProfile/requireComparable(_:_:)`` refuses.
    public init(first: MarginalProfile, second: MarginalProfile) throws {
        try MarginalProfile.requireComparable(first, second)
        let items = first.itemCount
        // At most one category can have `a_k + b_k > n`, so this maximum is the whole forced
        // diagonal rather than one term of a sum.
        let forced = zip(first.counts, second.counts).reduce(0) { max($0, $1.0 + $1.1 - items) }
        self.lowerCount = max(0, forced)
        self.upperCount = zip(first.counts, second.counts).reduce(0) { $0 + min($1.0, $1.1) }
        self.step = first.categoryCount == 2 ? 2 : nil
        self.marginsAreIdentical = first.counts == second.counts
        self.itemCount = items
        self.categoryCount = first.categoryCount
    }

    /// The lowest attainable agreement rate.
    public var lower: Double { Double(lowerCount) / Double(itemCount) }

    /// The highest attainable agreement rate.
    public var upper: Double { Double(upperCount) / Double(itemCount) }

    /// Every agreement count these marginals admit, or `nil` above two categories.
    public var attainableCounts: [Int]? {
        step.map { Array(stride(from: lowerCount, through: upperCount, by: $0)) }
    }

    /// Whether `count` is attainable, or `nil` when this package will not decide.
    ///
    /// `false` is always a real answer: a count outside the range, or `n - 1` against identical
    /// margins, is impossible at any category count. `nil` is reserved for a count inside the
    /// range on a panel with more than two categories, where deciding would mean solving a
    /// transportation problem this package does not solve.
    public func admits(count: Int) -> Bool? {
        guard count >= lowerCount, count <= upperCount else { return false }
        if marginsAreIdentical, count == itemCount - 1 { return false }
        guard let step else { return nil }
        return (count - lowerCount) % step == 0
    }

    /// The attainable agreement count nearest to `rate`.
    ///
    /// Snapping is reported rather than hidden: the caller gets the count, and
    /// ``BinaryConstruction/snapDistance`` says how far the request had to move. A rate inside
    /// the range but off the lattice is snapped; a rate outside the range is refused, because
    /// clamping it would silently hand back a panel that does not answer the question asked.
    ///
    /// - Throws: ``PanelDesignError/latticeRequiresBinary(categoryCount:)`` above two categories,
    ///   where the attainable set is not a lattice, and
    ///   ``PanelDesignError/rateOutsideAttainableRange(requested:lower:upper:)``.
    public func snap(rate: Double) throws -> Int {
        guard let step else {
            throw PanelDesignError.latticeRequiresBinary(categoryCount: categoryCount)
        }
        let raw = rate * Double(itemCount)
        guard raw >= Double(lowerCount) - 0.5, raw <= Double(upperCount) + 0.5 else {
            throw PanelDesignError.rateOutsideAttainableRange(
                requested: rate, lower: lower, upper: upper
            )
        }
        let offset = (raw - Double(lowerCount)) / Double(step)
        let stepsTaken = min(max(offset.rounded(), 0), Double((upperCount - lowerCount) / step))
        return lowerCount + Int(stepsTaken) * step
    }

    /// `true` when the marginals leave no choice at all.
    ///
    /// Reachable, and it is the sharpest statement this type makes: a judge who affirmed every
    /// item pins the agreement rate to the other judge's marginal, so the fixture's headline
    /// number is not a property of the pair but a restatement of one of them.
    public var isPinned: Bool { lowerCount == upperCount }
}
