import Foundation

/// What a fixture is being asked to contain.
///
/// A target is a claim about the panel a page will be computed over, and the three here are the
/// three claims that get made. They are not interchangeable: an agreement rate is on the scale
/// the reader sees, an odds ratio is on the scale that is invariant to how common the categories
/// are, and independence is the one people get by accident.
public enum AssociationTarget: Sendable, Equatable {

    /// The judges agree exactly as often as their marginals alone predict.
    ///
    /// Rarely attainable on the nose. `a * b / n` is an integer only when `n` divides it, so an
    /// integer panel is usually independent to within one item rather than exactly — which is
    /// why a fully crossed design, whose counts are products by construction, is the one shape
    /// that hits it dead on.
    case independence

    /// The judges agree on this share of items.
    case agreementRate(Double)

    /// The two-by-two table has this odds ratio.
    ///
    /// One is independence. Above one the judges' positives coincide more than chance; below,
    /// less. Unlike an agreement rate it does not move when the categories' prevalence does,
    /// which is what makes it the right handle when the fixture's marginals are also being set.
    case oddsRatio(Double)
}
