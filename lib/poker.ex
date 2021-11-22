defmodule Poker do
  @ranks ~w(2 3 4 5 6 7 8 9 T J Q K A) |> Enum.with_index(2) |> Enum.into(%{})
  @rank_mapping %{
    "01" => "high card",
    "02" => "one pair",
    "03" => "two pair",
    "04" => "three of a kind",
    "05" => "straight",
    "06" => "flush",
    "07" => "full house",
    "08" => "four of a kind",
    "09" => "straight flush"
  }

  @moduledoc """
  Documentation for `Poker`.

  A poker deck contains 52 cards - each card has a suit which
  is one of clubs, diamonds, hearts, or spades
  (denoted C, D, H, and S in the input data).

  Each card also has a value which is one of
  2, 3, 4, 5, 6, 7, 8, 9, 10, jack, queen, king, ace
  (denoted 2, 3, 4, 5, 6, 7, 8, 9, T, J, Q, K, A).

  For scoring purposes, the suits are unordered while the
  values are ordered as given above, with 2 being the lowest
  and ace the highest value.

  A poker hand consists of 5 cards dealt from the deck. Poker
  hands are ranked by the following partial order from lowest
  to highest.

  High Card: Hands which do not fit any higher category are
  ranked by the value of their highest card. If the highest
  cards have the same value, the hands are ranked by the next
  highest, and so on.

  Pair: 2 of the 5 cards in the hand have the same value.
  Hands which both contain a pair are ranked by the value of
  the cards forming the pair. If these values are the same,
  the hands are ranked by the values of the cards not
  forming the pair, in decreasing order.

  Two Pairs: The hand contains 2 different pairs. Hands
  which both contain 2 pairs are ranked by the value of
  their highest pair. Hands with the same highest pair
  are ranked by the value of their other pair. If these
  values are the same the hands are ranked by the value
  of the remaining card.

  Three of a Kind: Three of the cards in the hand have the
  same value. Hands which both contain three of a kind are
  ranked by the value of the 3 cards.
  Straight: Hand contains 5 cards with consecutive values.
  Hands which both contain a straight are ranked by their
  highest card.

  Flush: Hand contains 5 cards of the same suit. Hands which
  are both flushes are ranked using the rules for High Card.
  Full House: 3 cards of the same value, with the remaining 2
  cards forming a pair. Ranked by the value of the 3 cards

  Full House: 3 cards of the same value, with the remaining 2
  cards forming a pair. Ranked by the value of the 3 cards.

  Four of a kind: 4 cards with the same value. Ranked by the
  value of the 4 cards.

  Straight flush: 5 cards of the same suit with consecutive
  values. Ranked by the highest card in the hand.
  """

  def best_hand(hands) do
    hands
    |> Enum.group_by(&score_hand(&1))
    |> Enum.sort_by(fn {score, _hands} -> score end, &>=/2)
    |> List.first()
    |> convert_poker_result_to_string()
    |> format_output()
  end

  def format_output(result) do
    cond do
      elem(result, 0) == "Tie" ->
        {elem(result, 0),
         elem(result, 1)
         |> elem(1)}

      true ->
        {elem(result, 0),
         elem(result, 1)
         |> elem(1)
         |> hd()}
    end
  end

  def convert_poker_result_to_string(card) do
    win =
      cond do
        card
        |> elem(1)
        |> Enum.count() > 1 ->
          "Tie"

        true ->
          card
          |> elem(0)
          |> String.slice(0..1)
          |> then(&Map.fetch(@rank_mapping, &1))
          |> elem(1)
      end

    {win, card}
  end

  def score_hand(cards) do
    cards = cards |> Enum.map(&rank_and_suit/1)

    cond do
      is_straight_flush?(cards) -> {"09", straight_flush(cards)}
      is_four_of_a_kind?(cards) -> {"08", four_of_a_kind(cards)}
      is_full_house?(cards) -> {"07", full_house(cards)}
      is_flush?(cards) -> {"06", flush(cards)}
      is_straight?(cards) -> {"05", straight(cards)}
      is_three_of_kind?(cards) -> {"04", three_of_kind(cards)}
      is_two_pair?(cards) -> {"03", two_pair(cards)}
      is_one_pair?(cards) -> {"02", one_pair(cards)}
      true -> {"01", cards |> sort_by_rank()}
    end
    |> then(fn {score, cards} -> score <> order_ranks(cards) end)
  end

  def is_straight_flush?(cards) do
    sequence = cards |> sort_by_rank() |> sequential?()
    same_suite = cards |> same_suite() |> Enum.count() |> Kernel.==(1)
    sequence && same_suite
  end

  def straight_flush(cards), do: cards |> sort_by_rank()

  def is_four_of_a_kind?(cards), do: cards |> same_rank() |> with_count(4)

  def four_of_a_kind(cards) do
    same_rank = cards |> same_rank()
    four = same_rank |> with_count(4) |> elem(1) |> sort_by_rank()
    last = same_rank |> with_count(1) |> elem(1)
    four ++ last
  end

  def is_full_house?(cards) do
    same_rank = cards |> same_rank()
    same_rank |> with_count(3) && same_rank |> with_count(2)
  end

  def full_house(cards) do
    same_rank = cards |> same_rank()
    triple = same_rank |> with_count(3) |> elem(1) |> sort_by_rank()
    pair = same_rank |> with_count(2) |> elem(1) |> sort_by_rank() |> Enum.reverse()
    triple ++ pair
  end

  def is_flush?(cards), do: cards |> same_suite() |> Enum.count() |> Kernel.==(1)
  def flush(cards), do: sort_by_rank(cards)

  def is_straight?(cards), do: cards |> sort_by_rank() |> sequential?()
  def straight(cards), do: cards |> sort_by_rank()

  def is_three_of_kind?(cards), do: cards |> same_rank() |> with_count(3)

  def three_of_kind(cards) do
    triple = cards |> same_rank() |> with_count(3) |> elem(1) |> sort_by_rank()
    other = cards |> Enum.reject(&Enum.member?(triple, &1)) |> sort_by_rank() |> Enum.reverse()
    triple ++ other
  end

  def is_two_pair?(cards),
    do: cards |> same_rank() |> filter_count(2) |> Enum.count() |> Kernel.==(2)

  def two_pair(cards) do
    pairs =
      cards
      |> same_rank()
      |> filter_count(2)
      |> Enum.map(&elem(&1, 1))
      |> List.flatten()
      |> sort_by_rank()
      |> Enum.reverse()

    other = cards |> Enum.reject(&Enum.member?(pairs, &1))
    pairs ++ other
  end

  def is_one_pair?(cards), do: cards |> same_rank() |> with_count(2)

  def one_pair(cards) do
    pair = cards |> same_rank() |> with_count(2) |> elem(1)
    other = cards |> Enum.reject(&Enum.member?(pair, &1)) |> sort_by_rank() |> Enum.reverse()
    pair ++ other
  end

  def rank_and_suit(card) do
      [rank, suite] = String.codepoints(card)
      {@ranks[rank], suite}
  end

  def order_ranks(cards),
    do:
      cards
      |> Enum.map(fn {rank, _} -> rank end)
      |> Enum.map(&Integer.to_string/1)
      |> Enum.map(&String.pad_leading(&1, 2, "0"))
      |> Enum.join()

  def same_suite(cards), do: cards |> Enum.group_by(fn {_, suit} -> suit end)
  def same_rank(cards), do: cards |> Enum.group_by(fn {rank, _} -> rank end)
  def sort_by_rank(cards), do: cards |> Enum.sort_by(fn {rank, _} -> rank end)
  def sequential?([{rank, _} | tail]), do: sequential?(tail, rank)
  def sequential?([], _previous), do: true
  def sequential?([{rank, _} | _tail], previous) when previous + 1 != rank, do: false
  def sequential?([{rank, _} | tail], _previous), do: sequential?(tail, rank)
  def with_count(cards, n), do: cards |> Enum.find(fn {_, cards} -> length(cards) == n end)
  def filter_count(cards, n), do: cards |> Enum.filter(fn {_, cards} -> length(cards) == n end)
end
