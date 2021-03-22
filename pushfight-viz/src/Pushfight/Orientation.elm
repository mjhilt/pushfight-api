module Pushfight.Orientation exposing (Orientation, mapXY, rmapXY)


type Orientation
    = Zero
    | Ninety
    | OneEighty
    | TwoSeventy


mapXY: Orientation -> Int -> Int -> (Int, Int)
mapXY orientation x y =
    case orientation of
        Zero ->
            (x, y)
        Ninety ->
            (9 - y, x)
        OneEighty ->
            (9 - x, 3 - y)
        TwoSeventy ->
            (y, 3 - x)


rmapXY: Orientation -> Int -> Int -> (Int, Int)
rmapXY orientation x y =
    case orientation of
        Zero ->
            (x, y)
        Ninety ->
            (y, 9 - x)
        OneEighty ->
            (9 - x, 3 - y)
        TwoSeventy ->
            (3 - y, x)
