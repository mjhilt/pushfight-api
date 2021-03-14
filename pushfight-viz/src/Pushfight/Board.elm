module Pushfight.Board exposing (Board, move)

import Set

-- TODO maybe dont expose Board type, instead just a default, and encoder decoders?

type alias Board =
    { wp1: Int
    , wp2: Int
    , wp3: Int
    , wm1: Int
    , wm2: Int
    , bp1: Int
    , bp2: Int
    , bp3: Int
    , bm1: Int
    , bm2: Int
    , anchor: Maybe Int
    }

type Dir
    = Up
    | Down
    | Left
    | Right

dirToInt : Dir -> Int
dirToInt dir =
    case dir of
        Up ->
            10
        Down ->
            -10
        Left ->
            -1
        Right ->
            1

dirFromDelta : Int -> Maybe Dir
dirFromDelta d =
    if d == 1 then
        Just Right
    else if d == -1 then
        Just Left
    else if d == 10 then
        Just Up
    else if d == -10 then
        Just Down
    else
        Nothing

updatePos : Board -> Int -> Int -> Maybe Board
updatePos board from to =
    if board.wp1 == from then
        Just {board | wp1 = to}
    else if board.wp2 == from then
        Just {board | wp2 = to}
    else if board.wp3 == from then
        Just {board | wp3 = to}
    else if board.wm1 == from then
        Just {board | wm1 = to}
    else if board.wm2 == from then
        Just {board | wm2 = to}
    else if board.bp1 == from then
        Just {board | bp1 = to}
    else if board.bp2 == from then
        Just {board | bp2 = to}
    else if board.bp3 == from then
        Just {board | bp3 = to}
    else if board.bm1 == from then
        Just {board | bm1 = to}
    else if board.bm2 == from then
        Just {board | bm2 = to}
    else
        Nothing


isPusher : Board -> Int -> Bool
isPusher board at =
    if board.wp1 == at then
        True
    else if board.wp2 == at then
        True
    else if board.wp3 == at then
        True
    else if board.bp1 == at then
        True
    else if board.bp2 == at then
        True
    else if board.bp3 == at then
        True
    else
        False


isMover : Board -> Int -> Bool
isMover board at =
    if board.wm1 == at then
        True
    else if board.wm2 == at then
        True
    else if board.bm1 == at then
        True
    else if board.bm2 == at then
        True
    else
        False
 
isPiece : Board -> Int -> Bool
isPiece board at =
    (isPusher board at) || (isMover board at)

isWhitePiece : Board -> Int -> Bool
isWhitePiece board at =
    if board.wp1 == at then
        True
    else if board.wp2 == at then
        True
    else if board.wp3 == at then
        True
    else if board.wm1 == at then
        True
    else if board.wm2 == at then
        True
    else
        False

isBlackPiece : Board -> Int -> Bool
isBlackPiece board at =
    if board.bp1 == at then
        True
    else if board.bp2 == at then
        True
    else if board.bp3 == at then
        True
    else if board.bm1 == at then
        True
    else if board.bm2 == at then
        True
    else
        False

getPushPos : Board -> Int -> Dir -> List Int -> List Int
getPushPos board start dir pos =
    if (start < 0) || (start >= 40) then
        pos
    else
        let
            next = (start+(dirToInt dir))
        in
        if isPiece board next then
            getPushPos board next dir (start::pos)
        else
            pos

isValidPush : List Int -> Dir -> Bool
isValidPush pos dir =
    if List.length pos < 2 then
        False
    else
        case (dir, pos) of
            (Up, p::ps) ->
                List.member p [3,4,5,6,7]
                |> not
            (Down, p::ps) ->
                List.member p [33,34,35,36,37]
                |> not
            _ ->
                True


executePush : Maybe Board -> List Int -> Int -> Maybe Board
executePush board pos dir =
    case (board, pos) of
        (Just b, [p]) ->
            let
                updatedBoard =
                    updatePos b p (p+dir)
            in
            case updatedBoard of
                Just ub ->
                    Just {ub | anchor = Just p}
                Nothing ->
                    Nothing

        (Just b, p::ps) ->
            let
                updatedBoard =
                    updatePos b p (p+dir)
            in
            executePush updatedBoard ps dir
        _ ->
            board




isReachable : Board -> Int -> Int -> Bool
isReachable board from to =
    True

-- moves a piece
movePiece : Board -> Int -> Int -> Maybe Board
movePiece board from to =
    if isReachable board from to then
        updatePos board from to
    else
        Nothing

--isAdjacent : Int -> Int -> Bool
--isAdjacent a b =
--    case a - b of
--        1 ->
--            True
--        -1 ->
--            True
--        -10 ->
--            True
--        10 ->
--            True
--        _ ->
--            False

-- pushes line of pieces and places the anchor
pushPiece : Board -> Int -> Int -> Maybe Board
pushPiece board from to =
    let
        --fromPiece = getPiece board from
        --toPiece = getPiece board to
        dir = dirFromDelta (from - to)
    in
    case (isPusher board from, dir) of
        (_, Nothing) ->
            Nothing
        (True, Just d) ->
            let
                pos = getPushPos board from d []
            in
            if isValidPush pos d then
                case board.anchor of
                    Just anchorPos ->
                        if List.member anchorPos pos then
                            Nothing
                        else
                            executePush (Just board) pos (dirToInt d)
                    Nothing ->
                        executePush (Just board) pos (dirToInt d)
            else
                Nothing
        _ ->
            Nothing

move : Board -> Int -> Int -> Maybe Board
move board from to =
    let
        fromPiece = isPiece board from
        toPiece = isPiece board to
    in
    case (fromPiece, toPiece) of
        (True, True) ->
            pushPiece board from to
        (True, False) ->
            movePiece board from to
        _ ->
            Nothing

--encodeBoard : Board -> Encode.Value
--encodeBoard board =

---- https://package.elm-lang.org/packages/elm/json/latest/Json-Decode#andThen
---- ^ for failing the game stage parse
--decodeBoard : Decoder Board