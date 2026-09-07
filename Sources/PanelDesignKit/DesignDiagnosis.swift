import Foundation

/// One pair of judges, and how far their fixture sits from independence.
public struct PairDeviation: Sendable, Equatable {

    /// The first judge's index.
    public let first: Int

    /// The second judge's index.
    public let second: Int

    /// The largest gap between a joint count and the count independence predicts.
    public let deviation: Double

    /// The pair's raw agreement rate.
    public let agreementRate: Double

    /// Cohen's kappa for the pair, or `nil` where the chance term is one.
    public let cohenKappa: Double?
}

/// What a fixture can carry, decided before anything is measured on it.
///
/// The reading that matters is ``maximumPairDeviation``. When it is zero the judges are
/// independent as a fact about the counts rather than as an estimate from them, and every
/// coefficient, confidence interval and multiplicity correction computed over the panel is
/// measuring a quantity whose true value is exactly nil. A page of such numbers is not wrong.
/// It is a page about the fixture.
public struct DesignDiagnosis: Sendable, Equatable {

    /// How many judges the panel has.
    public let judgeCount: Int

    /// How many items every judge saw.
    public let itemCount: Int

    /// Every distinct pair, in index order.
    public let deviations: [PairDeviation]

    /// `true` when every combination of the judges' labels occurs equally often.
    ///
    /// The shape a factorial fixture has when it is built by crossing every factor with every
    /// other, which is the natural way to build one and the reason this diagnosis exists. A
    /// fully crossed panel's joint counts are products of its marginals by construction, so
    /// its pairwise association is not small — it is zero, to the last bit.
    public let isFullyCrossed: Bool

    /// - Throws: whatever ``PanelMatrix/table(_:_:)`` refuses.
    public init(panel: PanelMatrix) throws {
        var found: [PairDeviation] = []
        for first in 0..<panel.judgeCount {
            for second in (first + 1)..<panel.judgeCount {
                let table = try panel.table(first, second)
                found.append(
                    PairDeviation(
                        first: first,
                        second: second,
                        deviation: table.maximumIndependenceDeviation,
                        agreementRate: table.agreementRate,
                        cohenKappa: table.cohenKappa
                    )
                )
            }
        }
        self.judgeCount = panel.judgeCount
        self.itemCount = panel.itemCount
        self.deviations = found
        self.isFullyCrossed = Self.isFullyCrossed(panel)
    }

    /// The largest pairwise deviation anywhere in the panel.
    public var maximumPairDeviation: Double {
        deviations.reduce(0) { max($0, $1.deviation) }
    }

    /// `true` when no pair in the panel deviates from independence at all.
    public var isStructurallyNull: Bool { maximumPairDeviation == 0 }

    /// The pair carrying the most association, which is the one worth measuring first.
    public var strongestPair: PairDeviation? {
        deviations.max { $0.deviation < $1.deviation }
    }

    /// Passes the diagnosis through, or refuses the fixture.
    ///
    /// - Throws: ``PanelDesignError/designCarriesNoAssociation(judges:deviation:)`` when the
    ///   panel is structurally null. Certifying is the step a caller takes before publishing a
    ///   coefficient over the fixture, and it is the only step in this package that says no.
    @discardableResult
    public func certify() throws -> DesignDiagnosis {
        guard !isStructurallyNull else {
            throw PanelDesignError.designCarriesNoAssociation(
                judges: judgeCount, deviation: maximumPairDeviation
            )
        }
        return self
    }

    private static func isFullyCrossed(_ panel: PanelMatrix) -> Bool {
        var combinations = 1
        for _ in 0..<panel.judgeCount {
            guard combinations <= panel.itemCount / panel.categoryCount else { return false }
            combinations *= panel.categoryCount
        }
        guard panel.itemCount % combinations == 0 else { return false }
        var seen = [Int: Int]()
        for item in 0..<panel.itemCount {
            var index = 0
            for judge in 0..<panel.judgeCount {
                index = index * panel.categoryCount + panel.labels[judge][item]
            }
            seen[index, default: 0] += 1
        }
        let expected = panel.itemCount / combinations
        return seen.count == combinations && seen.values.allSatisfy { $0 == expected }
    }
}
