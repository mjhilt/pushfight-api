module Pushfight.Game exposing (Game, init, view, update)
import Pushfight.Board exposing (Board)
import Pushfight.GameStage exposing (GameStage)
import Pushfight.Color exposing (Color)
import Pushfight.Orientation exposing (Orientation)
import Pushfight.DragState

-- model

type Request
    = NoRequest
    | TakebackRequested (GameStage)
    | DrawOffered (GameStage)

type alias Model =
    { board: Board
    , gameStage: GameStage
    , color: Color
    , moves: List (Int, Int)
    , dragState: DragState
    , gridSize: Int
    , pauseStage: Request
    }

-- init

init: Board -> GameStage -> Color -> Moves -> Game
init playWhite =
    { board = board
    , gameStage = gameStage
    , color = color
    , moves = moves
    , dragState = DragState.init
    }


-- update

type Msg
    = DragMsg DragState.Msg
    | EndTurn
    | Undo
    | AskForTakeBack
    | OfferDraw
    | AcceptTakeback
    | AcceptDraw


undoMove : Model -> Model
undoMove model =
    let
        revMoves =
            model.moves
            |> List.reverse
            |> List.tail
        moves =
            case revMoves of
                Just moves ->
                    List.reverse moves
                Nothing ->
                    []
    in
    {model|moves=moves}

doMoves : List Move -> Board -> Maybe Board
doMoves moves board =
    case moves of
        [] ->
            board
        [m::ms] ->
            Maybe.map
            |> doMoves ms
            |> Board.move board m

handleEndTurn : List Moves -> Board -> GameStage -> Color -> Maybe (Board,GameStage)
handleEndTurn moves board gameStage color =
    --case List.reverse moves of
    --    [] ->
    --        Nothing
    --    [lastMove::_] ->
    let
        newBoard = doMoves moves board
        lastMove =
            moves
            |> List.reverse
            |> List.head
        lastMovePush =
            Maybe.map
            |> Board.anchorAt board
            |> lastMove.to

        pieceOutOfBounds =
            Board.pieceOutOfBounds board
        --moveLen =
    in
    case (newBoard, gameStage, ((((moveLen > 0) && (moveLen <= 3)), color), (lastMovePush, pieceOutOfBounds)) of
        (Just board, WhiteSetup, ((_, White), (False,False)) ->
            Just (board, BlackSetup)
        (Just board, BlackSetup, ((_, Black), (False,False)) ->
            Just (board, WhiteTurn)
        (Just board, WhiteTurn, ((True, White), (True,False)) ->
            Just (board, BlackTurn)
        (Just board, BlackTurn, ((True, Black), (True,False)) ->
            Just (board, WhiteTurn)
        (Just board, WhiteTurn, ((True, White), (True,True)) ->
            Just (board, WhiteWon)
        (Just board, BlackTurn, ((True, Black), (True,True)) ->
            Just (board, BlackWon)
        _ ->
            Nothing

handleDrag : Model -> Drag -> DragState -> Model
handleDrag model {from, to} dragState =
    let
        --dx = (to.x - from.x)//model.gridSize
        --dy = (to.y - from.y)//model.gridSize
        mapXY = Orientation.mapXY model.Orientation
        (fromX, fromY) = mapXY (from.x//model.gridSize) (from.y//model.gridSize)
        (toX, toY) = mapXY (to.x//model.gridSize) (to.y//model.gridSize)
        from = fromX+10*fromY
        to = toX+10*toY
        newMoves = 
            case List.reverse model.moves of
                [] ->
                    [{from=from, to=to}]
                [lastMove::otherMoves] ->
                    if lastMove.to == from then
                        List.append
                        |> List.reverse otherMoves
                        |> [{from=lastMove.from,to=to}]
                    else
                        List.append
                        |> model.moves
                        |> [{from=from,to=to}]
        isValid =
            ((Board.isWite board from) && (model.color == White)) || ((Board.isBlack board from) && (model.color == Black))
    in
    case (isValid, doMoves newMoves board) of
        (True, Just _) ->
            {model|moves=newMoves, dragState=dragState}
        _ ->
            {model|dragState=dragState}



update : Msg -> Model -> Model
update msg model =
    case msg of
        DragMsg dm ->
            let
                (dragState, finishedDrag) =
                    DragState.update model.dragState dm
            in
            case finishedDrag of
                Just drag ->
                    handleDrag model drag ds
                Nothing ->
                    {model|dragState=dragState}
        EndTurn ->
            case handleEndTurn model.moves model.board model.gameStage model.color of
                Just (board,gameStage) ->
                    {model|board=board,gameStage=gameStage}
                Nothing ->
                    model
        Undo ->
            undoMove model
        AskForTakeBack ->
            {model|request=TakebackRequested}
        OfferDraw ->
            {model|request=DrawOffered}
        AcceptDraw ->
            {model|gameStage=Draw}
        AcceptTakeback ->
            model

            --{model|gameStage=Draw}
    --color =
    --    if playWhite then
    --        White
    --    else
    --        Black

    --= DragAt Position
    --| DragEnd Position
    --| MouseDownAt (Float, Float)
    --| EndTurn
    --| Undo
    --| ToggleEndTurnOnPush Bool
    --| RotateOrientationCCW

--mouseSubsrciptions : DragState -> Sub Msg
--mouseSubsrciptions model =
--    case model.dragState of
--        NotDragging ->
--            Browser.Events.onMouseDown (Decode.map DragAt position)
--        _ ->
--            Sub.batch
--                [ Browser.Events.onMouseMove (Decode.map DragAt position)
--                , Browser.Events.onMouseUp (Decode.map DragEnd position)
--                ]


-- helpers


sign : Int -> Int
sign n =
    if n < 0 then
        -1
    else
        1


-- view

view : Model -> Html.Html Msg
view model =
    let
        rmapXY = Orientation.rmapXY model.orientation
        pieces =
            [ drawPiece model.gridSize rmapXY True True board.wp1
            , drawPiece model.gridSize rmapXY True True board.wp2
            , drawPiece model.gridSize rmapXY True True board.wp3
            , drawPiece model.gridSize rmapXY True False board.wm1
            , drawPiece model.gridSize rmapXY True False board.wm2
            , drawPiece model.gridSize rmapXY False True board.bp1
            , drawPiece model.gridSize rmapXY False True board.bp2
            , drawPiece model.gridSize rmapXY False True board.bp3
            , drawPiece model.gridSize rmapXY False False board.bm1
            , drawPiece model.gridSize rmapXY False False board.bm2
            ]
        anchor =
            case model.anchor of
                Just a ->
                    let
                        (x,y) = Board.ixToXY a
                        (xr,yr) = rmapXY x y
                    in
                    [drawAnchor model.gridSize xr yr]
                Nothing ->
                    []
        board =
            drawBoard size rmapXY
        width = String.fromInt (4*model.gridSize)
        height = String.fromInt (10*model.gridSize)
        title =
            case model.gameStage of
                WhiteSetup ->
                    "WhiteSetup"
                BlackSetup ->
                    "BlackSetup"
                WhiteTurn ->
                    "WhiteTurn, " ++ String.fromInt(2 - List.length model.moves) ++ " moves left"
                BlackTurn ->
                    "BlackTurn, " ++ String.fromInt(2 - List.length model.moves) ++ " moves left"
                WhiteWon ->
                    "WhiteWon"
                BlackWon ->
                    "BlackWon"
                Draw ->
                    "Draw"
        --subitle =
        --    case model.pr

    in
       Html.div []
        [ Html.text title
        , Svg.svg 
            [ Svg.Attributes.width width
            , Svg.Attributes.height height
            , Svg.Attributes.viewBox <| "0 0 " ++ width ++ " " ++ height
            ]
            ( List.concat
                [ board
                , pieces
                , anchor
                ]
            )
        ]

    --, anchor: Maybe Int

drawPiece : Int -> (Int -> Int -> (Int, Int)) -> Bool -> Bool -> Int -> Svg Msg
drawPiece size rmapXY isWhite isPusher ix =
    --(x,y) = (modBy 10 ix, ix//10)
    (x,y) = Board.ixToXY ix
    (color,accentColor) =
        if isWhite then
            (pieceColorWhite, pieceColorBlack)
        else
            (pieceColorBlack, pieceColorWhite)
    if isPusher then
        drawPusher size x y color accentColor
    else
        drawMover size x y color accentColor

    --case (isWhite, isPusher) of
    --    True, True
boardColor =
    "#BD632F"

pieceColorWhite =
    "#FFFAFA"

pieceColorBlack =
    "#19180A"

pieceMovingColor =
    "#D8AC8D"

anchorColor =
    "#A4243B"

--drawBoardSquare : Int -> (Int -> Int -> (Int, Int)) -> Int -> Int -> Svg Msg
--drawBoardSquare size rotateXY y x =
--    let
--        (xr, yr) =
--            rotateXY x y
--        (color, extraStyles) =
--            if isInBoard x y then
--                (boardColor, [Attributes.strokeWidth "1", Attributes.stroke "black"])
--            else
--                 ("#aaaaaa", [Attributes.fillOpacity "0"])

--    in
--        Svg.rect (
--            List.append extraStyles
--                [ Attributes.x <| String.fromInt (size * xr)
--                , Attributes.y <| String.fromInt (size * yr)
--                , Attributes.width <| String.fromInt size
--                , Attributes.height <| String.fromInt size
--                , Attributes.fill color
--                ]
--            ) []
drawBoardSquare size x y =
    let
        --(xr, yr) =
            --rotateXY x y
        (color, extraStyles) =
            --if isInBoard x y then
            (boardColor, [Attributes.strokeWidth "1", Attributes.stroke "black"])
            --else
            --     ("#aaaaaa", [Attributes.fillOpacity "0"])

    in
        Svg.rect (
            List.append extraStyles
                [ Attributes.x <| String.fromInt (size * xr)
                , Attributes.y <| String.fromInt (size * yr)
                , Attributes.width <| String.fromInt size
                , Attributes.height <| String.fromInt size
                , Attributes.fill color
                ]
            ) []

drawBoard : Int -> (Int -> Int -> (Int, Int)) -> List (Svg Msg)
drawBoard size rotateXY =
    let
        boardIxs =
            [           3, 4, 5, 6, 7
            ,    11,12,13,14,15,16,17,18
            ,    21,22,23,24,25,26,27,28
            ,       32,33,34,35,36,37
            ]
        boardXY = List.map Board.ixToXY boardIxs
        boardRXY =
            List.map
            |> \(x,y) -> rotateXY x y
            boardXY
    in
    List.map
    |> \(x,y) -> drawBoardSquare size x y
    |> boardRXY

--drawRow : (Int -> Int -> (Int,Int)) -> Int -> List Int -> Int -> List (Svg Msg)
--drawRow rotateXY size xs y =
--    List.map (drawBoardSquare size rotateXY y) xs


--drawBoard : (Int -> Int -> (Int,Int)) -> Int -> List (Svg Msg)
--drawBoard rotateXY size =
--    List.map (drawRow rotateXY size (List.range 0 9)) (List.range 0 3)
--    |> List.concat


drawPusher : Int -> Int -> Int -> String -> String -> List (Svg Msg)
drawPusher size x y color accentColor =
    let
        (posx, posy, fsize) =
            (toFloat (size * x), toFloat (size * y), toFloat size)
    in
        [ Svg.rect
            [ Attributes.fill accentColor
            , Attributes.x <| String.fromInt <| round (posx + fsize * 0.02)
            , Attributes.y <| String.fromInt <| round (posy + fsize * 0.02)
            , Attributes.width <| String.fromInt <| round (fsize * 0.96)
            , Attributes.height <| String.fromInt <| round (fsize * 0.96)
            ]
            []
        , Svg.rect
            [ Attributes.fill color
            , Attributes.x <| String.fromInt <| round (posx + fsize * 0.05)
            , Attributes.y <| String.fromInt <| round (posy + fsize * 0.05)
            , Attributes.width <| String.fromInt <| round (fsize * 0.9)
            , Attributes.height <| String.fromInt <| round (fsize * 0.9)
            , Touch.onStart ( \e -> MouseDownAt (x*size + size//2 |> toFloat, y*size + size//2 |> toFloat) )
            ]
            []
        ]


drawMover : Int -> Int -> Int -> String -> String -> List (Svg Msg)
drawMover size x y color accentColor =
    let
        (posx, posy, fsize) =
            (toFloat (size * x), toFloat (size * y), toFloat size)
    in
        [ Svg.circle
            [ Attributes.fill accentColor
            , Attributes.cx <| String.fromInt <| round (posx + (fsize / 2.0))
            , Attributes.cy <| String.fromInt <| round (posy + (fsize / 2.0))
            , Attributes.r <| String.fromInt <| round (fsize / 2.0)
            ]
            []
        , Svg.circle
            [ Attributes.fill color
            , Attributes.cx <| String.fromInt <| round (posx + (fsize / 2.0))
            , Attributes.cy <| String.fromInt <| round (posy + (fsize / 2.0))
            , Attributes.r <| String.fromInt <| round ((fsize * 0.95) / 2.0)
            , Touch.onStart ( \e -> MouseDownAt (x*size + size//2 |> toFloat, y*size + size//2 |> toFloat) )
            ]
            []
        ]


drawAnchor : Int -> Int -> Int -> List (Svg Msg)
drawAnchor size x y =
    let
        (posx, posy, fsize) =
            (toFloat (size * x), toFloat (size * y), toFloat size)
    in
        [
            Svg.circle
                [ Attributes.fill anchorColor
                , Attributes.cx <| String.fromInt <| round (posx + (fsize / 2.0))
                , Attributes.cy <| String.fromInt <| round (posy + (fsize / 2.0))
                , Attributes.r <| String.fromInt <| round (fsize / 4.0)
                ]
                []
        ]

-- TODO
--drawRails : Int -> Orientation -> List (Svg Msg)
--drawRails size orientation =
