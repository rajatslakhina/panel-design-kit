import Foundation

/// One constructed fixture, with the distance between what was asked for and what exists.
public struct BinaryConstruction: Sendable, Equatable {

    /// What the caller asked for.
    public let target: AssociationTarget

    /// The table that was built.
    public let table: JointTable

    /// The agreement count the target implies, before the panel's lattice is applied.
    public let requestedDiagonal: Double

    /// The agreement count actually built.
    public let diagonalTotal: Int

    /// How far the request had to move, on the agreement-rate scale.
    ///
    /// Never larger than half a step, and on a two-category panel a step is two items, so a
    /// request can legitimately land a whole item away from itself. Reported rather than
    /// absorbed: a fixture that is one item off the rate its caption claims should say so.
    public var snapDistance: Double {
        abs(Double(diagonalTotal) - requestedDiagonal) / Double(table.itemCount)
    }

    /// The agreement rate the built panel has.
    public var agreementRate: Double { table.agreementRate }
}

/// Builds a two-category fixture that contains a stated amount of association.
///
/// Two categories rather than any number, and that is a boundary rather than an oversight. With
/// two categories the margins leave exactly one free cell, so a target picks the table outright
/// and correctness is arithmetic. Above two the same question is a transportation problem with a
/// forbidden diagonal and a prescribed trace; ``AttainableAgreement`` prices that problem exactly
/// for every category count, and this type declines to solve it.
public struct BinaryPanelBuilder: Sendable {

    /// The first judge's marginal, held fixed by every construction here.
    public let first: MarginalProfile

    /// The second judge's marginal, likewise.
    public let second: MarginalProfile

    /// What the two marginals allow.
    public let attainable: AttainableAgreement

    /// - Throws: ``PanelDesignError/constructionRequiresBinary(categoryCount:)`` above two
    ///   categories, ``PanelDesignError/degenerateMarginal(judge:category:)`` for a judge with
    ///   no variance, and whatever ``AttainableAgreement/init(first:second:)`` refuses.
    public init(first: MarginalProfile, second: MarginalProfile) throws {
        self.attainable = try AttainableAgreement(first: first, second: second)
        guard first.categoryCount == 2 else {
            throw PanelDesignError.constructionRequiresBinary(categoryCount: first.categoryCount)
        }
        if let category = first.degenerateCategory {
            throw PanelDesignError.degenerateMarginal(judge: 0, category: category)
        }
        if let category = second.degenerateCategory {
            throw PanelDesignError.degenerateMarginal(judge: 1, category: category)
        }
        self.first = first
        self.second = second
    }

    /// Builds the fixture `target` describes.
    ///
    /// - Throws: ``PanelDesignError/oddsRatioNotPositive(_:)`` and
    ///   ``PanelDesignError/rateOutsideAttainableRange(requested:lower:upper:)``.
    public func table(for target: AssociationTarget) throws -> BinaryConstruction {
        let requested = try requestedDiagonal(for: target)
        let count = try attainable.snap(rate: requested / Double(attainable.itemCount))
        return BinaryConstruction(
            target: target,
            table: try table(diagonalTotal: count),
            requestedDiagonal: requested,
            diagonalTotal: count
        )
    }

    /// The table with exactly `diagonalTotal` agreements and these marginals.
    ///
    /// - Throws: ``PanelDesignError/rateOutsideAttainableRange(requested:lower:upper:)`` when the
    ///   count is off the lattice or outside the range. Off the lattice is the interesting half:
    ///   a count of 61 on a panel whose attainable counts are even is not nearly right, it does
    ///   not exist.
    public func table(diagonalTotal: Int) throws -> JointTable {
        guard attainable.admits(count: diagonalTotal) == true else {
            throw PanelDesignError.rateOutsideAttainableRange(
                requested: Double(diagonalTotal) / Double(attainable.itemCount),
                lower: attainable.lower,
                upper: attainable.upper
            )
        }
        let items = attainable.itemCount
        let both = (diagonalTotal - items + first.counts[0] + second.counts[0]) / 2
        return try JointTable(cells: [
            [both, first.counts[0] - both],
            [second.counts[0] - both, items - first.counts[0] - second.counts[0] + both]
        ])
    }

    private func requestedDiagonal(for target: AssociationTarget) throws -> Double {
        let items = Double(attainable.itemCount)
        switch target {
        case .independence:
            return diagonal(fromBothPositive: first.rate(0) * second.rate(0) * items)
        case .agreementRate(let rate):
            return rate * items
        case .oddsRatio(let psi):
            guard psi > 0 else { throw PanelDesignError.oddsRatioNotPositive(psi) }
            let joint = PlackettRoot.jointProbability(
                oddsRatio: psi, first: first.rate(0), second: second.rate(0)
            )
            return diagonal(fromBothPositive: joint * items)
        }
    }

    private func diagonal(fromBothPositive both: Double) -> Double {
        2 * both + Double(attainable.itemCount - first.counts[0] - second.counts[0])
    }
}
