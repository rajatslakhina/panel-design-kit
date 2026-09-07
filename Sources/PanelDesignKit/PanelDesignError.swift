import Foundation

/// Every way this package declines to describe or build a fixture.
///
/// A fixture is the thing a coefficient is computed over, and it is the one input to an
/// evaluation that nobody checks. Each case below is a place where returning a panel would
/// have been arithmetically possible and would have produced a page of numbers measuring
/// something other than what the reader was about to be told they measured.
public enum PanelDesignError: Error, Equatable, Sendable {

    /// Fewer than two categories, so there is nothing for two judges to disagree about.
    case categoryCountTooSmall(Int)

    /// Fewer than two items, which is fewer than one degree of freedom.
    case itemCountTooSmall(Int)

    /// A negative count in a marginal profile or a joint table.
    case negativeCount(category: Int, count: Int)

    /// Two judges' profiles were built over different numbers of items.
    case itemCountMismatch(first: Int, second: Int)

    /// Two judges' profiles were built over different numbers of categories.
    case categoryCountMismatch(first: Int, second: Int)

    /// A judge put every item in one category.
    ///
    /// Such a judge has no variance, so there is no association to target and no rate to hold
    /// fixed. Constructing a panel around one produces a table whose only reading is the other
    /// judge's marginal, restated.
    case degenerateMarginal(judge: Int, category: Int)

    /// A label outside `0..<categoryCount`.
    case labelOutOfRange(judge: Int, item: Int, label: Int)

    /// A joint table was handed rows of unequal length, or a non-square shape.
    case tableNotSquare(rows: Int, columns: Int)

    /// The requested agreement rate lies outside what these two marginals can produce.
    ///
    /// This is the Fréchet–Hoeffding refusal on the agreement scale. Two judges who each
    /// approve eighty of a hundred items must agree on at least sixty of them whatever either
    /// of them knows; asking for a fixture where they agree on thirty is not a hard request,
    /// it is an impossible one, and the honest answer names the interval.
    case rateOutsideAttainableRange(requested: Double, lower: Double, upper: Double)

    /// Construction was asked for on a panel with more than two categories.
    ///
    /// The general square case is a transportation problem with a forbidden diagonal and a
    /// prescribed trace. This package prices that problem — ``AttainableAgreement`` is exact
    /// for every category count — and declines to pretend it solves it.
    case constructionRequiresBinary(categoryCount: Int)

    /// A lattice of attainable agreement counts was asked for above two categories.
    ///
    /// Two categories give a genuine lattice — every second count, from the floor to the
    /// ceiling. Above two the attainable set can have holes: five items over three categories
    /// with identical margins `[1, 2, 2]` reach `{0, 1, 2, 3, 5}` and never four. Rounding a
    /// request onto a set with holes in it would produce a panel that does not exist.
    case latticeRequiresBinary(categoryCount: Int)

    /// An odds ratio was requested on a table that is not two-by-two.
    case oddsRatioRequiresBinary(categoryCount: Int)

    /// A non-positive odds ratio, which no joint distribution has.
    case oddsRatioNotPositive(Double)

    /// An odds ratio was read off a table with an empty cell, so the ratio is not finite.
    case oddsRatioUndefined(row: Int, column: Int)

    /// A fixture was certified for measuring association, and it has none to measure.
    ///
    /// The deviation carried here is the largest gap between any joint count and the count
    /// independence predicts. When it is zero the judges are exactly independent **by
    /// construction**, so every coefficient, interval and multiplicity correction computed
    /// over the fixture is estimating a quantity whose true value is nil. Nothing is broken;
    /// the page simply cannot say what it was built to say.
    case designCarriesNoAssociation(judges: Int, deviation: Double)

    /// A panel was recorded with fewer than two judges, so it has no pair to diagnose.
    case judgeCountTooSmall(Int)

    /// A judge index outside the recorded panel.
    case judgeOutOfRange(Int)

    /// A pair of judge indices that names the same judge twice.
    case judgePairNotDistinct(Int)

    /// No panel was recorded under the requested key.
    case unknownPanel(String)
}
