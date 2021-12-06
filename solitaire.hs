-- An implementation of solitaire in Haskell for COM2108 Functional Programming, a 2nd year module.
import System.Random
import Data.List

-- Initial datatypes
data Suit = Hearts | Clubs | Spades | Diamonds deriving (Eq, Ord, Enum, Show)
data Pip = Ace | Two | Three | Four | Five | Six | Seven | Eight | Nine | Ten | Jack | Queen | King deriving (Eq, Ord, Enum, Show)
type Card = (Pip, Suit)
type Deck = [Card]

-- Datatypes for Eight Off Board
type Foundations = [Deck]
type Columns = [Deck]
type Reserves = [Card]
data Board = Empty | EOBoard (Foundations, Columns, Reserves) | SBoard (Foundations, Columns, Stock) deriving (Eq, Ord)

-- Datatypes for Spider Board
type Stock = [Card]

-- Creates an instance of Board with a specific way of showing boards so it is more legible in the terminal
-- CHANGE TO LET TO MAKE MORE EFFICIENT?
instance Show Board where
  show (EOBoard (f, c, r)) = "EOBoard\nFoundations  " ++ show f ++ "\nColumns\n" ++ showColumns c ++ "Reserves    " ++ show r
    where
      showColumns [] = ""
      showColumns (c : cs) = show c ++ "\n" ++ showColumns cs
  show (SBoard (f, c, s)) = "SBoard\nFoundations  " ++ show f ++ "\nColumns\n" ++ showColumns c ++ "Stock  " ++ show (length s) ++ " Deals remaining"
    where
      showColumns [] = ""
      showColumns (c : cs) = show c ++ "\n" ++ showColumns cs

-- List all 52 cards in a pack
pack :: Deck
pack = [(pip, suit) | pip <- [Ace .. King], suit <- [Hearts .. Diamonds]]

-- Returns the successor of a card (successor of a king is an ace of the same suit)
sCard :: Card -> Card
sCard (King, suit) = (Ace, suit)
sCard (pip, suit) = (succ pip, suit)

-- Returns the successor of a card (predecessor of an ace is a king of the same suit)
pCard :: Card -> Card
pCard (Ace, suit) = (King, suit)
pCard (pip, suit) = (pred pip, suit)

-- Checks if the given card is an ace
isAce :: Card -> Bool
isAce (pip, _) = pip == Ace

-- Checks if the given card is a king
isKing :: Card -> Bool
isKing (pip, _) = pip == King

-- Takes a deck and returns a shuffled deck of the same cards
shuffle :: Int -> Deck
cmp (x1, y1) (x2, y2) = compare y1 y2
shuffle seed = [x | (x, n) <- sortBy cmp (zip pack (randoms (mkStdGen seed) :: [Int]))]

-- Removes the first instance of a card from a given list of cards (deck)
remove :: Card -> Deck -> Deck
remove card [] = []
remove card (element : deck)
  | card == element = deck
  | otherwise = element : remove card deck

-- Deals an eight off board given a seed
eoDeal :: Int -> Board
eoDeal seed = EOBoard (foundations, columns, reserves)
  where
    deck = shuffle seed
    foundations = []
    columns = eoSplitColumns (drop 4 deck)
    reserves = take 4 deck

sDeal :: Int -> Board
sDeal seed = SBoard (foundations, columns, stock)
  where
    deck = shuffle seed ++ shuffle seed
    foundations = []
    columns = sSplitColumns (drop 50 deck) -- 54 remaining
    stock = take 50 deck

-- Splits a deck recursively into piles of 6, to create 8 columns
eoSplitColumns :: Deck -> [Deck]
eoSplitColumns [] = []
eoSplitColumns deck = head : eoSplitColumns tail
  where
    (head, tail) = splitAt 6 deck

sSplitColumns :: Deck -> [Deck]
sSplitColumns [] = []
sSplitColumns deck = head : sSplitColumns tail
  where
    (head, tail) = splitAt 6 deck
    {--
    if length tail > 30
      then (head, tail) = splitAt 6 deck
      else (head, tail) = splitAt 5 deck
      --}

toFoundations :: Board -> Board
toFoundations board
  | anyValidMoves board = toFoundations (autoplay board)
  | otherwise = board

-- Check that there is a valid move given an eight off board
anyValidMoves :: Board -> Bool
anyValidMoves board = (not . null) (getValidAces board ++ getValidSuccessors board)

-- Moves all valid cards to foundations (copying them over to foundations and deleting them from their original location)
autoplay :: Board -> Board
autoplay (EOBoard (foundations, columns, reserves)) = foldr moveValidToFoundations (EOBoard (foundations, columns, reserves)) (moveable_aces ++ moveable_successors)
  where
    moveable_aces = getValidAces (EOBoard (foundations, columns, reserves))
    moveable_successors = getValidSuccessors (EOBoard (foundations, columns, reserves))

-- Get a list of all aces which are in the topmost columns or reserves which can be moved to foundations
getValidAces :: Board -> Deck
getValidAces (EOBoard (_, columns, reserves)) = filter isAce (map last columns ++ reserves)

-- Get a list of all successors which are in the topmost columns or reserves which can be moved to foundations
getValidSuccessors :: Board -> Deck
getValidSuccessors (EOBoard (foundations, columns, reserves)) = [c2 | c1 <- topmost_foundations, c2 <- topmost_possibles, sCard c1 == c2 && not (isKing c1)]
  where
    topmost_foundations = map last (filter (not . null) foundations)
    topmost_possibles = map last (filter (not . null) columns) ++ reserves

-- Moves valid cards to foundations
moveValidToFoundations :: Card -> Board -> Board
moveValidToFoundations card (EOBoard (foundations, columns, reserves)) = EOBoard (updated_foundations, updated_columns, updated_reserves)
  where
    updated_foundations = cardToFoundations card foundations
    updated_columns = map (remove card) columns
    updated_reserves = remove card reserves

-- Takes a card decides the appropriate action when it moves it to foundations based on whether the card is an ace or a successor
cardToFoundations :: Card -> Foundations -> Foundations
cardToFoundations card foundations
  | isAce card = [card] : foundations
  | otherwise = map (\e -> if sameSuit card (last e) then reverse (card : e) else e) foundations

-- Checks whether two cards are of the same suit
sameSuit :: Card -> Card -> Bool
sameSuit (_, suit1) (_, suit2) = suit1 == suit2

--findMoves :: Board -> [Board]
findMoves (EOBoard (foundations, columns, reserves)) =  potential_moveables
  where
    potential_moveables = map last columns ++ reserves

--cardToColumns :: Card -> Columns -> Columns
cardToColumns card columns = map (\e -> if sameSuit card (last e) then reverse (card : e) else e) columns 

--cardToReserves :: Card -> Reserves -> Reserves